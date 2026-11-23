import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_state.dart';
import 'db.dart';
import 'tools.dart';
import 'widgets.dart';

/// Digital library: real public documents (links) + in-app templates.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _search = TextEditingController();
  List<TemplateDoc> _templates = [];
  List<TemplateDoc> _shown = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await Repo.i.allTemplates();
      if (!mounted) return;
      setState(() {
        _templates = t;
        _shown = t;
        _loading = false;
      });
    } catch (_) {
      // A DB failure used to leave the loading spinner forever.
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trc(context, 'library_load_failed'))));
    }
  }

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _shown = _templates);
      return;
    }
    final res = await Repo.i.searchTemplates(q);
    // A slow earlier query must not overwrite results for newer input.
    if (!mounted || _search.text != q) return;
    setState(() => _shown = res);
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(trc(context, 'open_link_failed'))));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(trc(context, 'open_link_failed'))));
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'library'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: trc(context, 'library_search_hint'),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: 14),
                  SectionHeader(title: trc(context, 'library_docs')),
                  const SizedBox(height: 6),
                  ...libraryDocs.map((d) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: const Text('PDF',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11)),
                          ),
                          title: Text(d.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text('${d.org} • ${d.kind}'),
                          trailing:
                              const Icon(Icons.open_in_new, size: 18),
                          onTap: () => _openUrl(d.url),
                        ),
                      )),
                  const SizedBox(height: 14),
                  SectionHeader(title: trc(context, 'library_templates')),
                  const SizedBox(height: 6),
                  if (_shown.isEmpty)
                    EmptyState(
                        icon: Icons.description,
                        text: trc(context, 'library_no_templates')),
                  ..._shown.map((t) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.description,
                              color: AppColors.navy),
                          title: Text(t.titleAr,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text('${t.category} • ${t.titleEn}'),
                          trailing:
                              const Icon(Icons.arrow_back_ios, size: 14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DocGeneratorPage(templateKey: t.key)),
                          ),
                        ),
                      )),
                  const SizedBox(height: 10),
                  Text(
                    trc(context, 'library_note'),
                    style: TextStyle(fontSize: 12, color: context.mutedColor),
                  ),
                ],
              ),
            ),
    );
  }
}
