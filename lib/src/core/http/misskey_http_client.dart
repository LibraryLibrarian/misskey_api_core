import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:retry/retry.dart';

import '../auth/token_provider.dart';
import '../config/misskey_api_config.dart';
import '../error/misskey_api_exception.dart';
import '../logging/function_logger.dart';
import '../logging/logger.dart';
import 'request_options.dart' as ro;

/// Misskey API 用のHTTPクライアント
class MisskeyHttpClient {
  final MisskeyApiConfig config;
  final TokenProvider? tokenProvider;
  final Logger? logger;
  final Object Function(Object error)? exceptionMapper;

  /// 公開ベースURL（`/api` 付与前の元URL）
  Uri get baseUrl => config.baseUrl;

  late final Dio _dio;

  MisskeyHttpClient({
    required this.config,
    this.tokenProvider,
    Logger? logger,
    this.exceptionMapper,
    void Function(String level, String message)? loggerFn,
    HttpClientAdapter? httpClientAdapter,
  }) : logger = logger ?? (loggerFn != null ? FunctionLogger(loggerFn) : null) {
    final baseOptions = BaseOptions(
      baseUrl: _ensureApiBase(config.baseUrl).toString(),
      connectTimeout: config.timeout,
      sendTimeout: config.timeout,
      receiveTimeout: config.timeout,
      headers: {
        ...config.defaultHeaders,
        if (config.userAgent != null) 'User-Agent': config.userAgent,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    _dio = Dio(baseOptions);
    if (httpClientAdapter != null) {
      _dio.httpClientAdapter = httpClientAdapter;
    }

    _dio.interceptors.add(
      _MisskeyInterceptor(
        tokenProvider: tokenProvider,
        enableLog: config.enableLog,
        logger: logger ?? const StdoutLogger(),
      ),
    );
  }

  /// `path` は `/notes/create` のように `/api` より後のパスを渡す
  Future<T> send<T>(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? body,
    ro.RequestOptions options = const ro.RequestOptions(),
    CancelToken? cancelToken,
  }) async {
    final r = RetryOptions(
      maxAttempts: options.idempotent ? config.maxRetries : 1,
      delayFactor: config.retryInitialDelay,
      maxDelay: config.retryMaxDelay,
      randomizationFactor: 0.25,
    );

    // リトライオプションに従い、Dioを使ってHTTPリクエストを送信し、必要に応じてリトライを行う処理
    try {
      final result = await r.retry(
        () async {
          final Response<dynamic> res = await _dio.request(
            path.startsWith('/') ? path : '/$path',
            data: body,
            options: Options(
              method: method,
              extra: {'authRequired': options.authRequired},
            ),
            cancelToken: cancelToken,
          );
          return res;
        },
        retryIf: (e) => _shouldRetry(e, options.idempotent),
        onRetry: (e) {
          if (config.enableLog && kDebugMode) {
            (logger ?? const StdoutLogger()).warn('retrying due to: $e');
          }
        },
      );
      return result.data as T;
    } on DioException catch (e) {
      final err = _mapDioError(e);
      throw exceptionMapper != null ? exceptionMapper!(err) : err;
    } catch (e) {
      final err = MisskeyApiException(message: 'Unexpected error', raw: e);
      throw exceptionMapper != null ? exceptionMapper!(err) : err;
    }
  }

  static Uri _ensureApiBase(Uri base) {
    // 末尾に `/api` がなければ付与
    final normalized = base.replace(
      path: base.path.replaceAll(RegExp(r"/+$"), ''),
    );
    final path = normalized.path.endsWith('/api')
        ? normalized.path
        : '${normalized.path.isEmpty ? '' : normalized.path}/api';
    return normalized.replace(path: path);
  }

  static bool _shouldRetry(Object e, bool idempotent) {
    if (!idempotent) return false;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return true;
      }
      final status = e.response?.statusCode;
      if (status == null) return false;
      return status == 429 || (status >= 500 && status < 600);
    }
    return false;
  }

  static MisskeyApiException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    String message = e.message ?? 'HTTP error';
    String? code;
    final data = e.response?.data;
    if (data is Map) {
      final dynamic errorObj = data['error'];
      if (errorObj is Map) {
        final dynamic c = errorObj['code'];
        final dynamic m = errorObj['message'];
        if (c != null) code = c.toString();
        if (m != null) message = m.toString();
      } else {
        final dynamic c = data['code'];
        final dynamic m = data['message'];
        if (c != null) code = c.toString();
        if (m != null) message = m.toString();
      }
    }
    return MisskeyApiException(
      statusCode: status,
      code: code,
      message: message,
      raw: e,
    );
  }
}

class _MisskeyInterceptor extends Interceptor {
  final TokenProvider? tokenProvider;
  final bool enableLog;
  final Logger logger;

  _MisskeyInterceptor({
    required this.tokenProvider,
    required this.enableLog,
    required this.logger,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 認証付与（POSTのみ、かつ body が Map のとき）
    final extra = options.extra;
    final authRequired = (extra['authRequired'] as bool?) ?? true;
    if (authRequired && options.method.toUpperCase() == 'POST') {
      final token = await tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        final data = options.data;
        if (data is Map<String, dynamic>) {
          options.data = <String, dynamic>{...data, 'i': token};
        } else if (data == null) {
          options.data = <String, dynamic>{'i': token};
        }
      }
    }

    if (enableLog && kDebugMode) {
      logger.debug('REQ ${options.method} ${options.uri} data=${options.data}');
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enableLog && kDebugMode) {
      logger.debug('RES ${response.statusCode} ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enableLog && kDebugMode) {
      logger.error('ERR ${err.requestOptions.uri}', err, err.stackTrace);
    }
    super.onError(err, handler);
  }
}
