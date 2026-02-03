import 'package:json_annotation/json_annotation.dart';

part 'meta.g.dart';

/// Misskey `/api/meta` の最小モデル（ドメイン非依存）
/// - 未知フィールドを含む全JSONを `raw` に保持し、能力検出で活用できるように
@JsonSerializable(explicitToJson: true, createFactory: false, createToJson: true)
class Meta {
  const Meta({this.version, this.name, required this.raw});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      version: json['version'] as String?,
      name: json['name'] as String?,
      raw: Map<String, dynamic>.from(json),
    );
  }

  /// サーバーバージョン（例: "2024.12.0"）
  final String? version;

  /// サーバー名（例: "misskey.example"）
  final String? name;

  /// 全てのJSONを保持
  final Map<String, dynamic> raw;

  Map<String, dynamic> toJson() => _$MetaToJson(this);
}
