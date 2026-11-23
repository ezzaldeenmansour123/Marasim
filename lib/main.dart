import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'assistant.dart';
import 'db.dart';
import 'encyclopedia.dart';
import 'library.dart';
import 'notifications.dart';
import 'tools.dart';
import 'widgets.dart';

Future<void> scheduleNationalDayReminders() async {
  final days = await Repo.i.upcomingNationalDays(days: 60);
  for (final d in days) {
    await NotificationService.schedule(
      id: 20000 + d.countryId,
      title: 'العيد الوطني — ${d.countryAr}',
      body: 'اليوم ${d.name} (${d.countryAr}).',
      when: DateTime(d.nextDate.year, d.nextDate.month, d.nextDate.day, 9),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final state = AppState();
  await state.load();
  await NotificationService.requestPermissions();
  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const MarasimApp(),
    ),
  );
}

class MarasimApp extends StatelessWidget {
  const MarasimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (ctx, state, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مراسم | MARASIM',
        locale: Locale(state.language),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: AppTheme.light(state.fontScale),
        darkTheme: AppTheme.dark(state.fontScale),
        themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
        home: const SplashPage(),
      ),
    );
  }
}

// ── Splash ──
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoom;

  @override
  void initState() {
    super.initState();
    _zoom = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600))
      ..forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    });
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle animated photo backdrop: slow Ken Burns zoom.
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.12).animate(
                CurvedAnimation(parent: _zoom, curve: Curves.easeOut)),
            child: Image.asset('assets/images/hero1.jpg',
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) =>
                    Container(color: AppColors.navy)),
          ),
          Container(color: AppColors.navy.withValues(alpha: 0.82)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png',
                    width: 220,
                    height: 220,
                    errorBuilder: (c, e, st) => const Icon(Icons.public,
                        color: AppColors.gold, size: 120)),
                const SizedBox(height: 8),
                const Text('MARASIM',
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        color: AppColors.gold,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6)),
                const SizedBox(height: 4),
                const Text('International Protocol & Ceremonial Guide',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: AppColors.gold),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Home (bottom nav) ──
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  bool _remindersScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_remindersScheduled) return;
      _remindersScheduled = true;
      final state = Provider.of<AppState>(context, listen: false);
      if (state.notifDays) await scheduleNationalDayReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final pages = [
      const HomeTab(),
      const LibraryPage(),
      const ToolsHubPage(),
      const MorePage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.stone,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: tr(state, 'home')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book),
              label: tr(state, 'library')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.build),
              label: tr(state, 'tools')),
          BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz),
              label: tr(state, 'more')),
        ],
      ),
    );
  }
}

// ── Home tab ──
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Article> _latest = [];
  List<NationalDayItem> _upcoming = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final latest = await Repo.i.latestArticles(limit: 4);
    final upcoming = await Repo.i.upcomingNationalDays(days: 30);
    if (!mounted) return;
    setState(() {
      _latest = latest;
      _upcoming = upcoming;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png',
                width: 34,
                height: 34,
                errorBuilder: (c, e, st) => const Icon(Icons.public,
                    color: AppColors.gold)),
            const SizedBox(width: 8),
            const Text('مراسم | MARASIM'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined),
            tooltip: tr(state, 'assistant'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AssistantPage())),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBackground(),
          RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SearchPage())),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.stone),
                          const SizedBox(width: 8),
                          Text(tr(state, 'search_hint'),
                              style: const TextStyle(color: AppColors.stone)),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 14),
              // AI assistant banner
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AssistantPage())),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      AppColors.navy,
                      AppColors.navyLight,
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy,
                          color: AppColors.gold, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(state, 'assistant'),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                            Text(
                                tr(state, 'assistant_desc'),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  HomeTile(
                    icon: Icons.account_balance,
                    label: tr(state, 'protocol'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProtocolGuidePage())),
                  ),
                  HomeTile(
                    icon: Icons.apartment,
                    label: tr(state, 'ceremonies'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SectionArticlesPage(
                                section: 'المراسم الرئاسية'))),
                  ),
                  HomeTile(
                    icon: Icons.flag,
                    label: tr(state, 'flags'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SectionArticlesPage(
                                section: 'الأعلام والرموز الوطنية'))),
                  ),
                  HomeTile(
                    icon: Icons.format_list_numbered,
                    label: tr(state, 'precedence'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrecedencePage())),
                  ),
                  HomeTile(
                    icon: Icons.emoji_people,
                    label: tr(state, 'etiquette'),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SectionArticlesPage(
                                section: 'الإتيكيت الدولي'))),
                  ),
                  HomeTile(
                    icon: Icons.event,
                    label: tr(state, 'events'),
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EventsPage())),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public, color: AppColors.navy),
                  title: Text(tr(state, 'countries'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(tr(state, 'countries_sub')),
                  trailing: const Icon(Icons.arrow_back_ios, size: 14),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CountriesPage())),
                ),
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: tr(state, 'latest'),
                onMore: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProtocolGuidePage())),
              ),
              const SizedBox(height: 6),
              ..._latest.map((a) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: const Icon(Icons.article_outlined,
                          color: AppColors.navy),
                      title: Text(a.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(a.section),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ArticleReaderPage(article: a)),
                      ),
                    ),
                  )),
              const SizedBox(height: 14),
              SectionHeader(title: tr(state, 'upcoming')),
              const SizedBox(height: 6),
              if (_upcoming.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(tr(state, 'no_national_days'),
                        style: const TextStyle(color: AppColors.stone)),
                  ),
                )
              else
                ..._upcoming.map((d) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Text(d.flag,
                            style: const TextStyle(fontSize: 26)),
                        title: Text('${d.countryAr} — ${d.name}'),
                        subtitle: Text(
                            '${d.nextDate.year}-${d.nextDate.month.toString().padLeft(2, '0')}-${d.nextDate.day.toString().padLeft(2, '0')}'),
                      ),
                    )),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }
}

// ── Global search ──
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  List<Article> _articles = [];
  List<Country> _countries = [];
  List<TemplateDoc> _templates = [];
  bool _searched = false;

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _articles = [];
        _countries = [];
        _templates = [];
        _searched = false;
      });
      return;
    }
    final a = await Repo.i.searchArticles(q);
    final c = await Repo.i.searchCountries(q);
    final t = await Repo.i.searchTemplates(q);
    if (!mounted) return;
    setState(() {
      _articles = a;
      _countries = c;
      _templates = t;
      _searched = true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: tr(state, 'search'),
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.white),
            ),
            onChanged: _search,
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: tr(state, 'tab_articles')),
              Tab(text: tr(state, 'tab_countries')),
              Tab(text: tr(state, 'tab_templates')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _resultsList<Article>(
              _articles,
              (a) => ListTile(
                leading:
                    const Icon(Icons.article_outlined, color: AppColors.navy),
                title: Text(a.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(a.section),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ArticleReaderPage(article: a)),
                ),
              ),
            ),
            _resultsList<Country>(
              _countries,
              (c) => ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 26)),
                title: Text(c.nameAr,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${c.nameEn} • ${c.capital}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CountryDetailPage(country: c)),
                ),
              ),
            ),
            _resultsList<TemplateDoc>(
              _templates,
              (t) => ListTile(
                leading:
                    const Icon(Icons.description, color: AppColors.navy),
                title: Text(t.titleAr,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(t.category),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DocGeneratorPage(templateKey: t.key)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsList<T>(List<T> items, Widget Function(T) tile) {
    if (!_searched) {
      return EmptyState(
          icon: Icons.search, text: trc(context, 'search_empty_hint'));
    }
    if (items.isEmpty) {
      return EmptyState(
          icon: Icons.search_off, text: trc(context, 'search_no_results'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (ctx, i) => Card(child: tile(items[i])),
    );
  }
}

// ── More hub ──
class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final items = [
      (Icons.star, tr(state, 'favorites'), const FavoritesPage()),
      (Icons.public, tr(state, 'countries'), const CountriesPage()),
      (Icons.settings, tr(state, 'settings'), const SettingsPage()),
      (Icons.info_outline, tr(state, 'about'), const AboutPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(tr(state, 'more'))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode, color: AppColors.navy),
              title: Text(tr(state, 'settings_dark'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(tr(state, 'settings_dark_sub')),
              value: state.darkMode,
              onChanged: (v) => state.setDarkMode(v),
            ),
          ),
          ...items.map((it) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(it.$1, color: AppColors.navy),
                  title: Text(it.$2,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_back_ios, size: 14),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => it.$3)),
                ),
              )),
        ],
      ),
    );
  }
}

// ── Favorites ──
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Article> _articles = [];
  List<Country> _countries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final a = await Repo.i.favArticles();
    final c = await Repo.i.favCountries();
    if (mounted) {
      setState(() {
        _articles = a;
        _countries = c;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'favorites'))),
      body: (_articles.isEmpty && _countries.isEmpty)
          ? EmptyState(
              icon: Icons.star_border,
              text: trc(context, 'favorites_empty'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_articles.isNotEmpty) ...[
                    SectionHeader(title: trc(context, 'favorites_articles')),
                    ..._articles.map((a) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.article_outlined,
                                color: AppColors.navy),
                            title: Text(a.title),
                            subtitle: Text(a.section),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ArticleReaderPage(article: a)),
                            ),
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                  if (_countries.isNotEmpty) ...[
                    SectionHeader(title: trc(context, 'favorites_countries')),
                    ..._countries.map((c) => Card(
                          child: ListTile(
                            leading: Text(c.flag,
                                style: const TextStyle(fontSize: 26)),
                            title: Text(c.nameAr),
                            subtitle: Text(c.capital),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      CountryDetailPage(country: c)),
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }
}

// ── Settings ──
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = Provider.of<AppState>(context, listen: false);
    _apiCtrl.text = state.apiKey;
  }

  @override
  void dispose() {
    _apiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr(state, 'settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: tr(state, 'settings_language')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.language == 'ar'
                          ? AppColors.navy
                          : Colors.grey[300],
                      foregroundColor: state.language == 'ar'
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => state.setLanguage('ar'),
                    child: const Text('العربية'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.language == 'en'
                          ? AppColors.navy
                          : Colors.grey[300],
                      foregroundColor: state.language == 'en'
                          ? Colors.white
                          : Colors.black,
                    ),
                    onPressed: () => state.setLanguage('en'),
                    child: const Text('English'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionHeader(title: tr(state, 'settings_font')),
            Row(
              children: [
                IconButton(
                  icon: const Text('A−',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () =>
                      state.setFontScale(state.fontScale - 0.1),
                ),
                Expanded(
                  child: Slider(
                    value: state.fontScale,
                    min: 0.9,
                    max: 1.3,
                    divisions: 4,
                    label: state.fontScale.toStringAsFixed(1),
                    onChanged: (v) => state.setFontScale(v),
                  ),
                ),
                IconButton(
                  icon: const Text('A+',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  onPressed: () =>
                      state.setFontScale(state.fontScale + 0.1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(tr(state, 'settings_dark')),
              subtitle: Text(tr(state, 'settings_dark_sub')),
              value: state.darkMode,
              onChanged: (v) => state.setDarkMode(v),
            ),
            SwitchListTile(
              title: Text(tr(state, 'settings_notif_days')),
              subtitle: Text(tr(state, 'settings_notif_days_sub')),
              value: state.notifDays,
              onChanged: (v) async {
                await state.setNotifDays(v);
                if (v) await scheduleNationalDayReminders();
              },
            ),
            SwitchListTile(
              title: Text(tr(state, 'settings_notif_events')),
              subtitle: Text(tr(state, 'settings_notif_events_sub')),
              value: state.notifEvents,
              onChanged: (v) => state.setNotifEvents(v),
            ),
            const SizedBox(height: 16),
            SectionHeader(title: tr(state, 'settings_generative')),
            const SizedBox(height: 6),
            Text(
              tr(state, 'settings_generative_desc'),
              style: const TextStyle(color: AppColors.stone, height: 1.7),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr(state, 'settings_api_label'),
                hintText: 'sk-...',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await state.setApiKey(_apiCtrl.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(tr(state, 'settings_key_saved'))));
                    }
                  },
                  child: Text(tr(state, 'settings_save_key')),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await scheduleNationalDayReminders();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(tr(state, 'settings_rescheduled'))));
                    }
                  },
                  child: Text(tr(state, 'settings_reschedule')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('مراسم | MARASIM — ${tr(state, 'version')} $appVersion',
                style: const TextStyle(color: AppColors.stone)),
          ],
        ),
      ),
    );
  }
}

// ── About (founder info lives ONLY here) ──
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'about_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png',
                width: 150,
                height: 150,
                errorBuilder: (c, e, st) => const Icon(Icons.public,
                    color: AppColors.gold, size: 90)),
            const SizedBox(height: 12),
            Text('مراسم | MARASIM',
                style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: context.headingColor)),
            const Text('International Protocol & Ceremonial Intelligence Platform',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.stone)),
            const SizedBox(height: 20),
            Text(
              trc(context, 'about_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.9, fontSize: 15),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(trc(context, 'founder_dev'),
                        style: const TextStyle(
                            color: AppColors.stone, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    const Text('Ezzaldeen Mansour',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('عز الدين منصور',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(trc(context, 'founder_of'),
                        style: const TextStyle(color: AppColors.gold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              trc(context, 'about_disclaimer'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.stone, height: 1.7),
            ),
            const SizedBox(height: 8),
            Text('${trc(context, 'version')} $appVersion',
                style: const TextStyle(color: AppColors.stone)),
          ],
        ),
      ),
    );
  }
}
