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
    return GlobalLoaderOverlay(
      child: MaterialApp(title: 'Misskey Core Example', home: const AuthGate()),
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
  const AuthState({
    required this.authenticated,
    this.accessToken,
    this.baseUrl,
  });
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthStateNotifier(this.ref) : super(const AuthState(authenticated: false));

  Future<void> authenticate(BuildContext context) async {
    final instance = Uri.parse(ref.read(instanceUrlProvider));
    context.loaderOverlay.show();
    try {
      // misskey_auth 側の具体APIはダミー呼び出し（利用者が差し替え）
      final client = MisskeyOAuthClient();
      final config = MisskeyOAuthConfig(
        host: instance.host,
        clientId: 'https://librarylibrarian.github.io/misskey_api_core/',
        redirectUri:
            'https://librarylibrarian.github.io/misskey_api_core/redirect.html',
        scope: 'read:notes read:accounts write:notes',
        callbackScheme: 'misskeyapicore',
      );
      final token = await client.authenticate(config);
      if (token == null) {
        // キャンセルや失敗時は非認証のまま
        return;
      }
      state = AuthState(
        authenticated: true,
        accessToken: token.accessToken,
        baseUrl: instance,
      );
    } finally {
      context.loaderOverlay.hide();
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
        onTap: (i) => setState(() => _index = i),
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
    final res = await client.send<List<dynamic>>(
      '/notes/timeline',
      body: const {'limit': 20},
      options: const RequestOptions(idempotent: true),
    );
    setState(() => notes = res);
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
  Future<void> _load() async {
    final client = ref.read(httpClientProvider);
    if (client == null) return;
    final res = await client.send<List<dynamic>>(
      '/following',
      body: const {'limit': 30},
      options: const RequestOptions(idempotent: true),
    );
    setState(() => users = res);
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
          title: Text(users[i]['username']?.toString() ?? ''),
          subtitle: Text(users[i]['host']?.toString() ?? ''),
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
  Future<void> _load() async {
    final client = ref.read(httpClientProvider);
    if (client == null) return;
    final res = await client.send<List<dynamic>>(
      '/followers',
      body: const {'limit': 30},
      options: const RequestOptions(idempotent: true),
    );
    setState(() => users = res);
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
          title: Text(users[i]['username']?.toString() ?? ''),
          subtitle: Text(users[i]['host']?.toString() ?? ''),
        ),
      ),
    );
  }
}
