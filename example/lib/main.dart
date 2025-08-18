import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:misskey_api_core/misskey_api_core.dart';
import 'package:misskey_auth/misskey_auth.dart';

void main() {
  runApp(const ProviderScope(child: ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return GlobalLoaderOverlay(
      child: MaterialApp(
        title: 'Misskey Core Example',
        theme: ThemeData(
          colorScheme: scheme,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F7FA),
          appBarTheme: AppBarTheme(
            backgroundColor: scheme.surface,
            foregroundColor: scheme.onSurface,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: scheme.surface,
            selectedItemColor: scheme.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: scheme.surface,
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}

final instanceUrlProvider = StateProvider<String>(
  (ref) => 'https://misskey.io',
);

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  return AuthStateNotifier(ref);
});

class AuthState {
  final bool authenticated;
  final String? accessToken;
  final Uri? baseUrl;
  final String? selfUserId;
  const AuthState({
    required this.authenticated,
    this.accessToken,
    this.baseUrl,
    this.selfUserId,
  });
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthStateNotifier(this.ref) : super(const AuthState(authenticated: false));

  Future<void> authenticate(BuildContext context) async {
    final instance = Uri.parse(ref.read(instanceUrlProvider));
    final overlay = context.loaderOverlay;
    overlay.show();
    try {
      // misskey_auth 側の具体APIはダミー呼び出し（利用者が差し替え）
      final client = MisskeyOAuthClient();
      final config = MisskeyOAuthConfig(
        host: instance.host,
        clientId: 'https://librarylibrarian.github.io/misskey_api_core/',
        redirectUri:
            'https://librarylibrarian.github.io/misskey_api_core/redirect.html',
        scope: 'read:account read:notes write:notes read:following',
        callbackScheme: 'misskeyapicore',
      );
      final token = await client.authenticate(config);
      if (token == null) {
        // キャンセルや失敗時は非認証のまま
        return;
      }
      // 自分のユーザーIDを取得
      final tempApi = MisskeyHttpClient(
        config: MisskeyApiConfig(baseUrl: instance, enableLog: true),
        tokenProvider: () async => token.accessToken,
      );
      String? selfId;
      try {
        final me = await tempApi.send<Map<String, dynamic>>(
          '/i',
          body: const {},
          options: const RequestOptions(idempotent: true),
        );
        selfId = me['id'] as String?;
      } catch (_) {
        selfId = null;
      }

      state = AuthState(
        authenticated: true,
        accessToken: token.accessToken,
        baseUrl: instance,
        selfUserId: selfId,
      );
    } finally {
      overlay.hide();
    }
  }
}

final httpClientProvider = Provider<MisskeyHttpClient?>((ref) {
  final s = ref.watch(authStateProvider);
  if (!s.authenticated || s.baseUrl == null) return null;
  return MisskeyHttpClient(
    config: MisskeyApiConfig(baseUrl: s.baseUrl!, enableLog: true),
    tokenProvider: () async => s.accessToken,
  );
});

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (!auth.authenticated) {
      return const AuthScreen();
    }
    return const HomeScreen();
  }
}

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instanceUrl = ref.watch(instanceUrlProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in to Misskey')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Instance URL'),
              controller: TextEditingController(text: instanceUrl),
              onSubmitted: (v) =>
                  ref.read(instanceUrlProvider.notifier).state = v,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(authStateProvider.notifier).authenticate(context),
              child: const Text('Authenticate'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const PostNotePage(),
      const TimelinePage(),
      const FollowingPage(),
      const FollowersPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Misskey Example')),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          // タブ切替時にフォーカスを明示的に外し、キーボードイベントの不整合を回避
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _index = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Timeline'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Following',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Followers'),
        ],
      ),
    );
  }
}

class PostNotePage extends ConsumerWidget {
  const PostNotePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(httpClientProvider);
    final controller = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Text'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: client == null
                ? null
                : () async {
                    try {
                      await client.send<Map<String, dynamic>>(
                        '/notes/create',
                        body: {'text': controller.text},
                        options: const RequestOptions(idempotent: false),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Posted!')),
                        );
                        controller.clear();
                      }
                    } on MisskeyApiException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.message}')),
                      );
                    }
                  },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});
  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  List<dynamic> notes = const [];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final client = ref.read(httpClientProvider);
    if (client == null) return;
    try {
      final res = await client.send<List<dynamic>>(
        '/notes/timeline',
        body: const {'limit': 20},
        options: const RequestOptions(idempotent: true),
      );
      if (!mounted) return;
      setState(() => notes = res);
    } on MisskeyApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Timeline error: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (c, i) => ListTile(
          title: Text(notes[i]['text']?.toString() ?? ''),
          subtitle: Text(notes[i]['user']?['username']?.toString() ?? ''),
        ),
      ),
    );
  }
}

class FollowingPage extends ConsumerStatefulWidget {
  const FollowingPage({super.key});
  @override
  ConsumerState<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends ConsumerState<FollowingPage> {
  List<dynamic> users = const [];
  Map<String, dynamic>? _pickUser(dynamic item) {
    if (item is Map<String, dynamic>) {
      if (item['username'] is String) return item;
      if (item['followee'] is Map) {
        return (item['followee'] as Map).cast<String, dynamic>();
      }
      if (item['user'] is Map) {
        return (item['user'] as Map).cast<String, dynamic>();
      }
      if (item['follower'] is Map) {
        return (item['follower'] as Map).cast<String, dynamic>();
      }
    }
    return null;
  }

  Future<void> _load() async {
    final client = ref.read(httpClientProvider);
    if (client == null) return;
    final selfId = ref.read(authStateProvider).selfUserId;
    if (selfId == null) return;
    try {
      final res = await client.send<List<dynamic>>(
        '/users/following',
        body: {'userId': selfId, 'limit': 30, 'detailed': true},
        options: const RequestOptions(idempotent: true),
      );
      if (!mounted) return;
      setState(() => users = res);
    } on MisskeyApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Following error: ${e.message}')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (c, i) => ListTile(
          title: Text(_pickUser(users[i])?['username']?.toString() ?? ''),
          subtitle: Text(_pickUser(users[i])?['host']?.toString() ?? ''),
        ),
      ),
    );
  }
}

class FollowersPage extends ConsumerStatefulWidget {
  const FollowersPage({super.key});
  @override
  ConsumerState<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends ConsumerState<FollowersPage> {
  List<dynamic> users = const [];
  Map<String, dynamic>? _pickUser(dynamic item) {
    if (item is Map<String, dynamic>) {
      if (item['username'] is String) return item;
      if (item['follower'] is Map) {
        return (item['follower'] as Map).cast<String, dynamic>();
      }
      if (item['user'] is Map) {
        return (item['user'] as Map).cast<String, dynamic>();
      }
      if (item['followee'] is Map) {
        return (item['followee'] as Map).cast<String, dynamic>();
      }
    }
    return null;
  }

  Future<void> _load() async {
    final client = ref.read(httpClientProvider);
    if (client == null) return;
    final selfId = ref.read(authStateProvider).selfUserId;
    if (selfId == null) return;
    try {
      final res = await client.send<List<dynamic>>(
        '/users/followers',
        body: {'userId': selfId, 'limit': 30, 'detailed': true},
        options: const RequestOptions(idempotent: true),
      );
      if (!mounted) return;
      setState(() => users = res);
    } on MisskeyApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Followers error: ${e.message}')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (c, i) => ListTile(
          title: Text(_pickUser(users[i])?['username']?.toString() ?? ''),
          subtitle: Text(_pickUser(users[i])?['host']?.toString() ?? ''),
        ),
      ),
    );
  }
}
