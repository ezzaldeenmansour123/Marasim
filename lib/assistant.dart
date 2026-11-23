import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'app_state.dart';
import 'db.dart';
import 'encyclopedia.dart';
import 'tools.dart';
import 'widgets.dart';

/// MARASIM AI — retrieval-only assistant over the local knowledge base.
/// Every answer is grounded in a cited article (rule + source + review
/// date). When no reliable information exists, it says so clearly.
/// Works fully offline; an optional API key (Settings) is reserved for a
/// future generative mode and is never required.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _Msg {
  final bool user;
  final String text;
  final Article? top;
  final List<Article> related;
  final bool noInfo;
  const _Msg(
      {required this.user,
      required this.text,
      this.top,
      this.related = const [],
      this.noInfo = false});
}

const _chips = [
  ('كيف أرتب جلوس وفد يضم خمس دول؟', 'ترتيب جلوس وفد دول'),
  ('ما ترتيب الأسبقية في حفل استقبال رسمي؟', 'ترتيب الأسبقية حفل استقبال'),
  ('كيف أعد برنامج زيارة لوفد دبلوماسي؟', 'برنامج زيارة وفد دبلوماسي'),
  ('كيف تتم مراسم توقيع اتفاقية دولية؟', 'مراسم توقيع اتفاقية'),
  ('ما الفرق بين الزيارة الرسمية وزيارة العمل؟', 'الفرق زيارة رسمية زيارة عمل'),
  ('كيف أرتب أعلام الدول المشاركة؟', 'ترتيب أعلام الدول'),
  ('كيف أكتب دعوة رسمية لسفير؟', 'دعوة رسمية سفير'),
];

class _AssistantPageState extends State<AssistantPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final List<_Msg> _msgs;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _msgs = [
      _Msg(user: false, text: trc(context, 'assistant_welcome')),
    ];
  }

  Future<void> _ask(String query) async {
    final q = query.trim();
    if (q.isEmpty || _busy) return;
    setState(() {
      _msgs.add(_Msg(user: true, text: q));
      _busy = true;
    });
    _controller.clear();
    _scrollToEnd();
    try {
      final results = await Repo.i.searchArticles(q, limit: 6);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _msgs.add(_Msg(
            user: false,
            text: trc(context, 'assistant_no_info').replaceFirst('{q}', q),
            noInfo: true,
          ));
        });
      } else {
        setState(() {
          _msgs.add(_Msg(
            user: false,
            text: trc(context, 'assistant_answer_intro'),
            top: results.first,
            related: results.length > 1 ? results.sublist(1) : const [],
          ));
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _msgs.add(_Msg(
          user: false,
          text: trc(context, 'assistant_search_error'),
          noInfo: true,
        ));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(trc(context, 'assistant')),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(trc(context, 'assistant_how_title')),
                content: Text(trc(context, 'assistant_how_body')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(trc(context, 'assistant_understood'))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _msgs.length,
              itemBuilder: (ctx, i) => _bubble(_msgs[i]),
            ),
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 8),
                  Text(trc(context, 'assistant_searching'),
                      style: TextStyle(color: context.mutedColor)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _chips
                        .map((c) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ActionChip(
                                label: Text(c.$1),
                                onPressed: () => _ask(c.$2),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.description_outlined,
                          color: AppColors.gold),
                      tooltip: trc(context, 'assistant_draft'),
                      onPressed: () => _showDraftSheet(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fact_check_outlined,
                          color: AppColors.gold),
                      tooltip: trc(context, 'assistant_check_plan'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckerPickerPage()),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: trc(context, 'assistant_write_question'),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _ask,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.gold),
                      onPressed: () => _ask(_controller.text),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 14, color: context.mutedColor),
                    const SizedBox(width: 4),
                    Text(trc(context, 'assistant_offline_note'),
                        style: TextStyle(
                            fontSize: 11, color: context.mutedColor)),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDraftSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trc(context, 'assistant_draft'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(trc(context, 'assistant_draft_sub'),
                  style: TextStyle(color: context.mutedColor)),
              const SizedBox(height: 12),
              ...[
                ('invitation', trc(context, 'draft_invitation')),
                ('visit_program', trc(context, 'draft_visit_program')),
                ('meeting_agenda', trc(context, 'draft_meeting_agenda')),
                ('event_checklist', trc(context, 'draft_event_checklist')),
              ].map((t) => ListTile(
                    leading: const Icon(Icons.description, color: AppColors.navy),
                    title: Text(t.$2),
                    trailing: const Icon(Icons.arrow_back_ios, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => DocGeneratorPage(templateKey: t.$1)),
                      );
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final align = m.user ? Alignment.centerLeft : Alignment.centerRight;
    final color = m.user ? AppColors.navy : Theme.of(context).cardColor;
    final textColor =
        m.user ? Colors.white : context.bodyColor;
    final linkColor = context.isDark ? AppColors.gold : AppColors.navy;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: m.user
              ? null
              : Border.all(color: context.cardBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.text, style: TextStyle(color: textColor, fontSize: 14.5)),
            if (m.top != null) ...[
              const SizedBox(height: 8),
              Text(m.top!.title,
                  style: TextStyle(
                      fontFamily: 'Amiri',
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text(m.top!.body,
                  style: TextStyle(color: textColor, fontSize: 14)),
              const SizedBox(height: 10),
              SourceLine(
                sourceName: m.top!.sourceName,
                sourceOrg: m.top!.sourceOrg,
                sourceUrl: m.top!.sourceUrl,
                reviewed: m.top!.reviewed,
                ruleType: m.top!.ruleType,
              ),
              if (m.related.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(trc(context, 'assistant_related'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor)),
                ...m.related.map((a) => InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ArticleReaderPage(article: a)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(Icons.article_outlined,
                                size: 15, color: linkColor),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(a.title,
                                    style: TextStyle(
                                        color: linkColor, fontSize: 13))),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
            if (m.noInfo) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.menu_book, size: 16),
                label: Text(trc(context, 'assistant_browse_guide')),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProtocolGuidePage()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Article reader (also used from search results and related links).
class ArticleReaderPage extends StatefulWidget {
  final Article article;
  const ArticleReaderPage({super.key, required this.article});
  @override
  State<ArticleReaderPage> createState() => _ArticleReaderPageState();
}

class _ArticleReaderPageState extends State<ArticleReaderPage> {
  bool _fav = false;

  @override
  void initState() {
    super.initState();
    Repo.i.isFav('article', widget.article.id).then((v) {
      if (mounted) setState(() => _fav = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.article;
    return Scaffold(
      appBar: AppBar(
        title: Text(a.section, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_fav ? Icons.star : Icons.star_border,
                color: AppColors.gold),
            onPressed: () async {
              await Repo.i.toggleFav('article', a.id);
              if (mounted) setState(() => _fav = !_fav);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share('${a.title}\n\n${a.body}\n\nالمصدر: ${a.sourceName} — ${a.sourceOrg}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.title,
                style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(a.body, style: const TextStyle(fontSize: 16, height: 1.9)),
            const SizedBox(height: 16),
            SourceLine(
              sourceName: a.sourceName,
              sourceOrg: a.sourceOrg,
              sourceUrl: a.sourceUrl,
              reviewed: a.reviewed,
              ruleType: a.ruleType,
            ),
          ],
        ),
      ),
    );
  }
}
