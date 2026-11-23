import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'app_state.dart';
import 'assistant.dart';
import 'db.dart';
import 'widgets.dart';

/// Countries encyclopedia: list + search + detail page.
class CountriesPage extends StatefulWidget {
  const CountriesPage({super.key});
  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  final _search = TextEditingController();
  List<Country> _all = [];
  List<Country> _shown = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await Repo.i.allCountries();
    if (!mounted) return;
    setState(() {
      _all = all;
      _shown = all;
      _loading = false;
    });
  }

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _shown = _all);
      return;
    }
    final res = await Repo.i.searchCountries(q);
    if (mounted) setState(() => _shown = res);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'countries'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: trc(context, 'countries_search_hint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _onSearch('');
                        },
                      ),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _shown.isEmpty
                    ? EmptyState(
                        icon: Icons.public_off,
                        text: trc(context, 'countries_no_match'))
                    : ListView.builder(
                        itemCount: _shown.length,
                        itemBuilder: (ctx, i) {
                          final c = _shown[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            child: ListTile(
                              leading: Text(c.flag,
                                  style: const TextStyle(fontSize: 30)),
                              title: Text(c.nameAr,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${c.nameEn} • ${trc(context, 'capital')}: ${c.capital}'),
                              trailing:
                                  const Icon(Icons.arrow_back_ios, size: 14),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        CountryDetailPage(country: c)),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class CountryDetailPage extends StatefulWidget {
  final Country country;
  const CountryDetailPage({super.key, required this.country});
  @override
  State<CountryDetailPage> createState() => _CountryDetailPageState();
}

class _CountryDetailPageState extends State<CountryDetailPage> {
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    Repo.i.isFav('country', widget.country.id).then((v) {
      if (mounted) setState(() => _fav = v);
    });
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(width: 10),
          SizedBox(
              width: 110,
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.headingColor))),
          Expanded(child: Text(value, style: const TextStyle(height: 1.6))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.country;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.nameAr),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.star : Icons.star_border,
                color: AppColors.gold),
            onPressed: () async {
              await Repo.i.toggleFav('country', c.id);
              if (mounted) setState(() => _fav = !_fav);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share(
                '${c.nameAr} (${c.nameEn})\n${trc(context, 'capital')}: ${c.capital}\n${trc(context, 'language')}: ${c.languages}\n${trc(context, 'currency')}: ${c.currency}\n${trc(context, 'national_day')}: ${c.nationalDayName}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(c.flag, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 6),
                  Text(c.nameAr,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Text(c.nameEn,
                      style: TextStyle(color: context.mutedColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _row(trc(context, 'capital'), c.capital, Icons.location_city),
                    _row(trc(context, 'language'), c.languages, Icons.language),
                    _row(trc(context, 'currency'), c.currency, Icons.attach_money),
                    _row(trc(context, 'timezone'), c.timezones, Icons.schedule),
                    _row(trc(context, 'system'), c.system, Icons.account_balance),
                    _row(trc(context, 'national_day'),
                        c.nationalDay == null
                            ? c.nationalDayName
                            : '${c.nationalDayName} (${c.nationalDay})',
                        Icons.celebration),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SectionHeader(title: trc(context, 'country_protocol')),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(c.protocolNote,
                    style: const TextStyle(height: 1.8, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 14),
            SectionHeader(title: trc(context, 'country_titles')),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(c.titlesNote,
                    style: const TextStyle(height: 1.8, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
            SourceLine(
              sourceName: c.sourceName,
              sourceOrg: c.sourceOrg,
              sourceUrl: c.sourceUrl,
              reviewed: c.reviewed,
              ruleType: 'معلومات موثقة',
            ),
          ],
        ),
      ),
    );
  }
}

/// Protocol guide: the 16 sections, each opening its articles.
class ProtocolGuidePage extends StatefulWidget {
  const ProtocolGuidePage({super.key});
  @override
  State<ProtocolGuidePage> createState() => _ProtocolGuidePageState();
}

class _ProtocolGuidePageState extends State<ProtocolGuidePage> {
  List<String> _sections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await Repo.i.sections();
    if (mounted) {
      setState(() {
        _sections = s;
        _loading = false;
      });
    }
  }

  static const _icons = {
    'المبادئ العامة للبروتوكول': Icons.account_balance,
    'العلاقات الدبلوماسية': Icons.handshake,
    'الأسبقية الدبلوماسية': Icons.format_list_numbered,
    'الألقاب الرسمية': Icons.workspace_premium,
    'الأعلام والرموز الوطنية': Icons.flag,
    'المراسم الرئاسية': Icons.apartment,
    'استقبال الوفود': Icons.groups,
    'المراسم الملكية': Icons.castle,
    'الزيارات الرسمية': Icons.flight_takeoff,
    'المؤتمرات الدولية': Icons.forum,
    'الاجتماعات الثنائية': Icons.people,
    'توقيع الاتفاقيات': Icons.draw,
    'المآدب الرسمية': Icons.restaurant,
    'المراسلات الدبلوماسية': Icons.mail,
    'الإتيكيت الدولي': Icons.emoji_people,
    'مراسم العزاء والتعازي الرسمية': Icons.spa,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'guide_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sections.isEmpty
              ? EmptyState(
                  icon: Icons.error_outline,
                  text: trc(context, 'guide_empty'),
                  onRetry: _load,
                  retryLabel: trc(context, 'retry'),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _sections.length,
              itemBuilder: (ctx, i) {
                final s = _sections[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.navy,
                      child: Icon(_icons[s] ?? Icons.book,
                          color: AppColors.gold, size: 20),
                    ),
                    title: Text(s,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_back_ios, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SectionArticlesPage(section: s)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SectionArticlesPage extends StatefulWidget {
  final String section;
  const SectionArticlesPage({super.key, required this.section});
  @override
  State<SectionArticlesPage> createState() => _SectionArticlesPageState();
}

class _SectionArticlesPageState extends State<SectionArticlesPage> {
  List<Article> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final a = await Repo.i.articlesBySection(widget.section);
    if (mounted) {
      setState(() {
        _articles = a;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.section)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? EmptyState(
                  icon: Icons.article_outlined,
                  text: trc(context, 'section_empty'),
                  onRetry: _load,
                  retryLabel: trc(context, 'retry'),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _articles.length,
              itemBuilder: (ctx, i) {
                final a = _articles[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined,
                        color: AppColors.navy),
                    title: Text(a.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      a.body.length > 110
                          ? '${a.body.substring(0, 110)}…'
                          : a.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Chip(
                      label: Text(a.ruleType,
                          style: const TextStyle(fontSize: 10)),
                      backgroundColor: const Color(0xFFF3EDDD),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ArticleReaderPage(article: a)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
