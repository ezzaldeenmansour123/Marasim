import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
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
    Repo.i.allTemplates().then((t) {
      if (mounted) {
        setState(() {
          _templates = t;
          _shown = t;
          _loading = false;
        });
      }
    });
  }

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _shown = _templates);
      return;
    }
    final res = await Repo.i.searchTemplates(q);
    if (mounted) setState(() => _shown = res);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح الرابط')));
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
      appBar: AppBar(title: const Text('المكتبة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _search,
                    decoration: const InputDecoration(
                      hintText: 'ابحث في المكتبة...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: 14),
                  const SectionHeader(title: 'الوثائق والاتفاقيات الدولية'),
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
                  const SectionHeader(title: 'النماذج والقوالب الجاهزة'),
                  const SizedBox(height: 6),
                  if (_shown.isEmpty)
                    const EmptyState(
                        icon: Icons.description,
                        text: 'لا توجد نماذج مطابقة للبحث.'),
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
                  const Text(
                    'ملاحظة: الوثائق الدولية روابط إلى مصادرها الرسمية (الأمم المتحدة وغيرها) ولا تُخزَّن داخل التطبيق احترامًا لحقوق النشر.',
                    style: TextStyle(fontSize: 12, color: AppColors.stone),
                  ),
                ],
              ),
            ),
    );
  }
}
