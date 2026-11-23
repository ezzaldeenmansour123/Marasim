import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'db.dart';
import 'notifications.dart';
import 'pdf_export.dart';
import 'widgets.dart';

/// Hub of the practical tools.
class ToolsHubPage extends StatelessWidget {
  const ToolsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      ('حاسبة الأسبقية', Icons.format_list_numbered,
          'رتّب الشخصيات وفق قواعد الأسبقية الدبلوماسية', const PrecedencePage()),
      ('مخطط الجلوس', Icons.event_seat,
          'طاولة مستديرة أو مستطيلة أو على شكل U', const SeatingPlansPage()),
      ('منظم المناسبات', Icons.event,
          'أنشئ مناسبة بضيوفها وبرنامجها وقوائمها', const EventsPage()),
      ('مولد المستندات', Icons.description,
          'دعوات وخطابات وبرامج — تصدير PDF', const DocGeneratorPage()),
      ('مدقق البروتوكول', Icons.fact_check,
          'راجع خطة مناسبة واكتشف الأخطاء', const CheckerPickerPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('الأدوات العملية')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tools.length,
        itemBuilder: (ctx, i) {
          final t = tools[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.navy,
                child: Icon(t.$2, color: AppColors.gold, size: 22),
              ),
              title: Text(t.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(t.$3),
              trailing: const Icon(Icons.arrow_back_ios, size: 14),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => t.$4)),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════ 1. حاسبة الأسبقية ═══════════

class _Person {
  String name, country, rankKey, credentialDate;
  _Person(
      {this.name = '',
      this.country = '',
      this.rankKey = 'ambassador',
      this.credentialDate = ''});
}

class PrecedencePage extends StatefulWidget {
  const PrecedencePage({super.key});
  @override
  State<PrecedencePage> createState() => _PrecedencePageState();
}

class _PrecedencePageState extends State<PrecedencePage> {
  final List<_Person> _persons = [
    _Person(name: 'سفير دولة الإمارات', country: 'الإمارات', rankKey: 'ambassador', credentialDate: '2024-03-10'),
    _Person(name: 'سفير المملكة العربية السعودية', country: 'السعودية', rankKey: 'ambassador', credentialDate: '2023-11-02'),
    _Person(name: 'وزير الخارجية', country: 'اليمن', rankKey: 'foreign_minister'),
  ];
  List<_Person>? _ordered;

  void _compute() {
    final maps = _persons
        .where((p) => p.name.trim().isNotEmpty)
        .map((p) => {
              'name': p.name,
              'country': p.country,
              'rank_category': p.rankKey,
              'credential_date': p.credentialDate,
            })
        .toList();
    final ordered = orderByPrecedence(maps);
    setState(() {
      _ordered = ordered
          .map((m) => _Person(
                name: m['name'] as String,
                country: (m['country'] ?? '') as String,
                rankKey: m['rank_category'] as String,
                credentialDate: (m['credential_date'] ?? '') as String,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الأسبقية')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'أضف الشخصيات (الاسم والمنصب والدولة وتاريخ تقديم أوراق الاعتماد للسفراء)، ثم اضغط «احسب الترتيب».',
                style: TextStyle(color: AppColors.stone)),
            const SizedBox(height: 12),
            ..._persons.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: p.name,
                              decoration: const InputDecoration(
                                  labelText: 'الاسم / المنصب'),
                              onChanged: (v) => p.name = v,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () =>
                                setState(() => _persons.removeAt(i)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(p.rankKey),
                              initialValue: p.rankKey,
                              decoration:
                                  const InputDecoration(labelText: 'الفئة'),
                              items: precedenceRanks
                                  .map((r) => DropdownMenuItem(
                                      value: r.$1, child: Text(r.$2)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => p.rankKey = v ?? 'ambassador'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: p.country,
                              decoration:
                                  const InputDecoration(labelText: 'الدولة'),
                              onChanged: (v) => p.country = v,
                            ),
                          ),
                        ],
                      ),
                      if (p.rankKey == 'ambassador') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: p.credentialDate,
                          decoration: const InputDecoration(
                              labelText: 'تاريخ تقديم أوراق الاعتماد (YYYY-MM-DD)',
                              hintText: '2024-03-10'),
                          onChanged: (v) => p.credentialDate = v,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة شخص'),
                  onPressed: () => setState(() => _persons.add(_Person())),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calculate),
                  label: const Text('احسب الترتيب'),
                  onPressed: _compute,
                ),
              ],
            ),
            if (_ordered != null) ...[
              const SizedBox(height: 16),
              const SectionHeader(title: 'الترتيب المقترح'),
              const SizedBox(height: 8),
              ..._ordered!.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.navy,
                      child: Text('${i + 1}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${rankLabel(p.rankKey)}${p.country.isNotEmpty ? ' — ${p.country}' : ''}${p.credentialDate.isNotEmpty ? ' • اعتماد: ${p.credentialDate}' : ''}'),
                  ),
                );
              }),
              const SizedBox(height: 10),
              const SourceLine(
                sourceName: 'اتفاقية فيينا للعلاقات الدبلوماسية 1961، المادتان 13 و16',
                sourceOrg: 'الأمم المتحدة — مجموعة المعاهدات',
                sourceUrl:
                    'https://treaties.un.org/doc/Treaties/1964/06/19640624%2002-10%20AM/Ch_III_3p.pdf',
                reviewed: '2026-11-24',
                ruleType: 'ملزمة دوليًا',
              ),
              const SizedBox(height: 8),
              const Text(
                  'القاعدة: يتقدم رؤساء البعثات في فئتهم بحسب تاريخ وساعة تولي مهامهم (المادة 16)، ويُحدَّد تاريخ التولي بتقديم أوراق الاعتماد (المادة 13). أما ترتيب الفئات فيتبع المادة 14.',
                  style: TextStyle(color: AppColors.stone, height: 1.7)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('مشاركة الترتيب'),
                onPressed: () {
                  final lines = _ordered!.asMap().entries.map((e) =>
                      '${e.key + 1}. ${e.value.name} — ${rankLabel(e.value.rankKey)}${e.value.country.isNotEmpty ? ' (${e.value.country})' : ''}');
                  Share.share('ترتيب الأسبقية:\n${lines.join('\n')}');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════ 2. مخطط الجلوس ═══════════

class SeatingPlansPage extends StatefulWidget {
  const SeatingPlansPage({super.key});
  @override
  State<SeatingPlansPage> createState() => _SeatingPlansPageState();
}

class _SeatingPlansPageState extends State<SeatingPlansPage> {
  List<SeatingPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await Repo.i.allPlans();
    if (mounted) setState(() => _plans = plans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مخطط الجلوس')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SeatingEditorPage()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('مخطط جديد'),
      ),
      body: _plans.isEmpty
          ? const EmptyState(
              icon: Icons.event_seat,
              text: 'لا توجد مخططات محفوظة بعد.\nأنشئ مخططًا لمائدة مستديرة أو مستطيلة أو على شكل U.')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _plans.length,
              itemBuilder: (ctx, i) {
                final plan = _plans[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event_seat, color: AppColors.navy),
                    title: Text(plan.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${plan.shape} • ${plan.seats} مقاعد • ${plan.updatedAt.split('T').first}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await Repo.i.deletePlan(plan.id);
                        _load();
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SeatingEditorPage(plan: plan)));
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _SeatGuest {
  String name, title, country, rankKey;
  _SeatGuest(
      {this.name = '',
      this.title = '',
      this.country = '',
      this.rankKey = 'ambassador'});
}

class SeatingEditorPage extends StatefulWidget {
  final SeatingPlan? plan;
  const SeatingEditorPage({super.key, this.plan});
  @override
  State<SeatingEditorPage> createState() => _SeatingEditorPageState();
}

class _SeatingEditorPageState extends State<SeatingEditorPage> {
  final _nameCtrl = TextEditingController();
  String _shape = 'مستديرة';
  int _seats = 8;
  final List<_SeatGuest> _guests = [];
  int? _planId;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _planId = widget.plan!.id;
      _nameCtrl.text = widget.plan!.name;
      _shape = widget.plan!.shape;
      _seats = widget.plan!.seats;
      Repo.i.planAssignments(widget.plan!.id).then((rows) {
        if (!mounted) return;
        setState(() {
          _guests.addAll(rows.map((r) => _SeatGuest(
                name: (r['guest_name'] ?? '') as String,
                title: (r['guest_title'] ?? '') as String,
                country: (r['country'] ?? '') as String,
              )));
        });
      });
    }
  }

  void _autoArrange() {
    final maps = _guests
        .map((g) => {
              'name': g.name,
              'rank_category': g.rankKey,
              'credential_date': '',
            })
        .toList();
    final ordered = orderByPrecedence(maps);
    setState(() {
      _guests.clear();
      _guests.addAll(ordered.map((m) => _SeatGuest(
            name: m['name'] as String,
            rankKey: m['rank_category'] as String,
          )));
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الترتيب حسب الأسبقية الدبلوماسية')));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل اسمًا للمخطط أولًا')));
      return;
    }
    final now = DateTime.now().toIso8601String();
    _planId ??= await Repo.i.insertPlan({
      'name': _nameCtrl.text.trim(),
      'shape': _shape,
      'seats': _seats,
      'created_at': now,
      'updated_at': now,
    });
    await Repo.i.saveAssignments(
      _planId!,
      _guests.asMap().entries.map((e) => {
            'seat_index': e.key + 1,
            'guest_name': e.value.name,
            'guest_title': e.value.title,
            'country': e.value.country,
          }).toList(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ المخطط')));
      Navigator.pop(context);
    }
  }

  Widget _roundTable() {
    const size = 300.0;
    final shown = _guests.take(_seats).toList();
    return SizedBox(
      height: size + 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 3),
            ),
            alignment: Alignment.center,
            child: const Text('المائدة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          ...shown.asMap().entries.map((e) {
            final angle = (e.key / shown.length) * 2 * math.pi - math.pi / 2;
            final x = (size / 2) + (size / 2 - 30) * math.cos(angle);
            final y = (size / 2) + (size / 2 - 30) * math.sin(angle);
            final g = e.value;
            return Positioned(
              left: x - 34,
              top: y - 18,
              child: Container(
                width: 68,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: e.key == 0 ? AppColors.gold : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.navy),
                ),
                child: Text(
                  '${e.key + 1}. ${g.name.isEmpty ? '—' : g.name}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          e.key == 0 ? FontWeight.bold : FontWeight.normal),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _rowsTable() {
    final shown = _guests.take(_seats).toList();
    final half = (shown.length / 2).ceil();
    final top = shown.take(half).toList();
    final bottom = shown.skip(half).toList();
    Widget row(List<_SeatGuest> list, int start) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: list.asMap().entries.map((e) {
            final g = e.value;
            final idx = start + e.key;
            return Container(
              margin: const EdgeInsets.all(3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: idx == 0 ? AppColors.gold : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.navy),
              ),
              child: Text('${idx + 1}. ${g.name.isEmpty ? '—' : g.name}',
                  style: const TextStyle(fontSize: 11)),
            );
          }).toList(),
        );
    return Column(
      children: [
        row(top, 0),
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
              _shape == 'مستطيلة' ? 'المائدة المستطيلة' : 'المائدة (شكل U)',
              style: const TextStyle(color: Colors.white)),
        ),
        row(bottom, half),
      ],
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مخطط الجلوس'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white, size: 18),
            label:
                const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم المخطط'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_shape),
                    initialValue: _shape,
                    decoration: const InputDecoration(labelText: 'شكل المائدة'),
                    items: const ['مستديرة', 'مستطيلة', 'U']
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _shape = v ?? 'مستديرة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      const Text('المقاعد:'),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(
                            () => _seats = (_seats - 2).clamp(4, 40)),
                      ),
                      Text('$_seats',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(
                            () => _seats = (_seats + 2).clamp(4, 40)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
                child: _shape == 'مستديرة' ? _roundTable() : _rowsTable()),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.sort),
                  label: const Text('ترتيب تلقائي حسب الأسبقية'),
                  onPressed: _guests.isEmpty ? null : _autoArrange,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة ضيف'),
                  onPressed: () =>
                      setState(() => _guests.add(_SeatGuest())),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._guests.asMap().entries.map((e) {
              final i = e.key;
              final g = e.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text('${i + 1}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: g.name,
                              decoration:
                                  const InputDecoration(labelText: 'اسم الضيف'),
                              onChanged: (v) => g.name = v,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey(g.rankKey),
                                    initialValue: g.rankKey,
                                    decoration: const InputDecoration(
                                        labelText: 'الفئة'),
                                    items: precedenceRanks
                                        .map((r) => DropdownMenuItem(
                                            value: r.$1,
                                            child: Text(r.$2,
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: (v) => setState(
                                        () => g.rankKey = v ?? 'ambassador'),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: g.country,
                                    decoration: const InputDecoration(
                                        labelText: 'الدولة'),
                                    onChanged: (v) => g.country = v,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 18),
                            onPressed: i == 0
                                ? null
                                : () => setState(() {
                                      final t = _guests[i - 1];
                                      _guests[i - 1] = _guests[i];
                                      _guests[i] = t;
                                    }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 18),
                            onPressed: i == _guests.length - 1
                                ? null
                                : () => setState(() {
                                      final t = _guests[i + 1];
                                      _guests[i + 1] = _guests[i];
                                      _guests[i] = t;
                                    }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            onPressed: () =>
                                setState(() => _guests.removeAt(i)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════ 3. منظم المناسبات ═══════════

const eventTypes = ['زيارة رسمية', 'مؤتمر', 'احتفال', 'اجتماع ثنائي', 'مأدبة رسمية'];

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<EventItem> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final evs = await Repo.i.allEvents();
    if (mounted) setState(() => _events = evs);
  }

  Future<void> _create() async {
    final titleCtrl = TextEditingController();
    final placeCtrl = TextEditingController();
    String type = eventTypes.first;
    DateTime date = DateTime.now().add(const Duration(days: 7));
    int guests = 50;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('مناسبة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'اسم المناسبة')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(type),
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'نوع المناسبة'),
                  items: eventTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setD(() => type = v ?? type),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: placeCtrl,
                    decoration: const InputDecoration(labelText: 'المكان')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('التاريخ:'),
                    const SizedBox(width: 8),
                    TextButton(
                      child: Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) setD(() => date = picked);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('عدد الضيوف المتوقع:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: guests.toDouble(),
                        min: 5,
                        max: 500,
                        divisions: 99,
                        label: '$guests',
                        onChanged: (v) => setD(() => guests = v.round()),
                      ),
                    ),
                    Text('$guests'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إنشاء')),
          ],
        ),
      ),
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final id = await Repo.i.insertEvent({
      'title': titleCtrl.text.trim(),
      'type': type,
      'date': dateStr,
      'place': placeCtrl.text.trim(),
      'guests_expected': guests,
      'notes': '',
      'created_at': DateTime.now().toIso8601String(),
    });
    // Auto checklist from the event_checklist template.
    final tpl = await Repo.i.templateByKey('event_checklist');
    final lines = (tpl?.bodyAr ?? '')
        .split('\n')
        .map((l) => l.replaceAll(RegExp(r'^[\-\d\.\)\s]+'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final fallback = [
      'تأكيد قائمة الضيوف والدعوات',
      'تجهيز قاعة الاستقبال والأعلام',
      'مراجعة ترتيب الجلوس والأسبقية',
      'تجهيز برنامج المناسبة وتوزيعه',
      'تنسيق التغطية الإعلامية والتصوير',
    ];
    final items = lines.isNotEmpty ? lines : fallback;
    for (var i = 0; i < items.length; i++) {
      await Repo.i.insertChecklistItem({
        'event_id': id,
        'text': items[i],
        'done': 0,
        'sort_order': i,
      });
    }
    // Reminder on the event day at 09:00 (if notifications are on).
    final notifOn = await Repo.i.getSetting('notif_events', '1');
    if (notifOn == '1') {
      await NotificationService.schedule(
        id: 10000 + id,
        title: 'مناسبة اليوم: ${titleCtrl.text.trim()}',
        body: 'تبدأ اليوم في ${placeCtrl.text.trim()} — راجع قائمة التحقق.',
        when: DateTime(date.year, date.month, date.day, 9),
      );
    }
    if (mounted) {
      _load();
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => EventDetailPage(eventId: id)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('منظم المناسبات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('مناسبة جديدة'),
      ),
      body: _events.isEmpty
          ? const EmptyState(
              icon: Icons.event,
              text: 'لا توجد مناسبات بعد.\nأنشئ مناسبة وسيُنشأ لها برنامج وقائمة تحقق وتذكير تلقائيًا.')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _events.length,
              itemBuilder: (ctx, i) {
                final e = _events[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: AppColors.navy),
                    title: Text(e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${e.type} • ${e.date} • ${e.place}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await Repo.i.deleteEvent(e.id);
                        await NotificationService.cancel(10000 + e.id);
                        _load();
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  EventDetailPage(eventId: e.id)));
                      _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}

class EventDetailPage extends StatefulWidget {
  final int eventId;
  const EventDetailPage({super.key, required this.eventId});
  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  EventItem? _event;
  List<Map<String, Object?>> _guests = [];
  List<Map<String, Object?>> _program = [];
  List<Map<String, Object?>> _checklist = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await Repo.i.eventById(widget.eventId);
    final g = await Repo.i.eventGuests(widget.eventId);
    final pr = await Repo.i.eventProgram(widget.eventId);
    final cl = await Repo.i.checklist(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = e;
      _guests = g;
      _program = pr;
      _checklist = cl;
    });
  }

  Future<void> _addGuest() async {
    final nameCtrl = TextEditingController();
    String rank = 'ambassador';
    final countryCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة ضيف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الضيف')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey(rank),
              initialValue: rank,
              decoration: const InputDecoration(labelText: 'الفئة'),
              items: precedenceRanks
                  .map((r) =>
                      DropdownMenuItem(value: r.$1, child: Text(r.$2)))
                  .toList(),
              onChanged: (v) => rank = v ?? rank,
            ),
            const SizedBox(height: 8),
            TextField(
                controller: countryCtrl,
                decoration: const InputDecoration(labelText: 'الدولة')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة')),
        ],
      ),
    );
    if (ok != true || nameCtrl.text.trim().isEmpty) return;
    await Repo.i.insertEventGuest({
      'event_id': widget.eventId,
      'name': nameCtrl.text.trim(),
      'title': rankLabel(rank),
      'country': countryCtrl.text.trim(),
      'rank_category': rank,
      'credential_date': '',
      'sort_order': _guests.length,
    });
    _load();
  }

  Future<void> _addProgram() async {
    final timeCtrl = TextEditingController(text: '10:00');
    final titleCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة فقرة للبرنامج'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(labelText: 'الوقت')),
            const SizedBox(height: 8),
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'عنوان الفقرة')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة')),
        ],
      ),
    );
    if (ok != true || titleCtrl.text.trim().isEmpty) return;
    await Repo.i.insertProgramItem({
      'event_id': widget.eventId,
      'time': timeCtrl.text.trim(),
      'title': titleCtrl.text.trim(),
      'notes': '',
      'sort_order': _program.length,
    });
    _load();
  }

  Future<void> _addChecklist() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة بند لقائمة التحقق'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'البند')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إضافة')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    await Repo.i.insertChecklistItem({
      'event_id': widget.eventId,
      'text': ctrl.text.trim(),
      'done': 0,
      'sort_order': _checklist.length,
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    if (e == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('المناسبة')),
          body: const Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(e.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الضيوف'),
              Tab(text: 'البرنامج'),
              Tab(text: 'قائمة التحقق'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.fact_check),
              tooltip: 'تدقيق البروتوكول',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CheckerPage(eventId: e.id)),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Chip(label: Text(e.type)),
                  const SizedBox(width: 6),
                  Chip(label: Text(e.date)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(e.place,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.stone))),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _guestsTab(),
                  _programTab(),
                  _checklistTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guestsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text('الضيوف (${_guests.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة ضيف'),
                onPressed: _addGuest,
              ),
            ],
          ),
        ),
        Expanded(
          child: _guests.isEmpty
              ? const EmptyState(
                  icon: Icons.groups, text: 'لا يوجد ضيوف بعد.')
              : ListView.builder(
                  itemCount: _guests.length,
                  itemBuilder: (ctx, i) {
                    final g = _guests[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.navy,
                        child: Text('${i + 1}',
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text((g['name'] ?? '') as String),
                      subtitle: Text(
                          '${g['title'] ?? ''}${(g['country'] as String?)?.isNotEmpty == true ? ' — ${g['country']}' : ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () async {
                          await Repo.i.deleteEventGuest(g['id'] as int);
                          _load();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _programTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Text('برنامج المناسبة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة فقرة'),
                onPressed: _addProgram,
              ),
            ],
          ),
        ),
        Expanded(
          child: _program.isEmpty
              ? const EmptyState(
                  icon: Icons.schedule, text: 'لا توجد فقرات بعد.')
              : ListView.builder(
                  itemCount: _program.length,
                  itemBuilder: (ctx, i) {
                    final p = _program[i];
                    return ListTile(
                      leading: Chip(
                          label: Text((p['time'] ?? '') as String)),
                      title: Text((p['title'] ?? '') as String),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () async {
                          await Repo.i.deleteProgramItem(p['id'] as int);
                          _load();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _checklistTab() {
    final done = _checklist.where((c) => (c['done'] as int) == 1).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text('قائمة التحقق ($done/${_checklist.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('إضافة بند'),
                onPressed: _addChecklist,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _checklist.length,
            itemBuilder: (ctx, i) {
              final c = _checklist[i];
              final isDone = (c['done'] as int) == 1;
              return CheckboxListTile(
                value: isDone,
                title: Text((c['text'] ?? '') as String,
                    style: TextStyle(
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : null)),
                onChanged: (v) async {
                  await Repo.i.setChecklistDone(c['id'] as int, v ?? false);
                  _load();
                },
                secondary: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await Repo.i.deleteChecklistItem(c['id'] as int);
                    _load();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════ 4. مولد المستندات ═══════════

class DocGeneratorPage extends StatefulWidget {
  final String? templateKey;
  const DocGeneratorPage({super.key, this.templateKey});
  @override
  State<DocGeneratorPage> createState() => _DocGeneratorPageState();
}

class _DocGeneratorPageState extends State<DocGeneratorPage> {
  List<TemplateDoc> _templates = [];
  TemplateDoc? _selected;
  final Map<String, TextEditingController> _fields = {};
  String _preview = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tpls = await Repo.i.allTemplates();
    if (!mounted) return;
    setState(() {
      _templates = tpls;
      if (widget.templateKey != null) {
        _selected = tpls.firstWhere(
            (t) => t.key == widget.templateKey,
            orElse: () => tpls.first);
      }
    });
    if (_selected != null) _rebuildFields();
  }

  static final _ph = RegExp(r'\{\{([^}]+)\}\}');

  void _rebuildFields() {
    for (final c in _fields.values) {
      c.dispose();
    }
    _fields.clear();
    final t = _selected;
    if (t == null) return;
    for (final m in _ph.allMatches(t.bodyAr)) {
      final key = m.group(1)!.trim();
      _fields.putIfAbsent(key, () => TextEditingController());
    }
    _updatePreview();
  }

  void _updatePreview() {
    final t = _selected;
    if (t == null) return;
    var text = t.bodyAr;
    for (final e in _fields.entries) {
      text = text.replaceAll('{{${e.key}}}', e.value.text.trim());
    }
    setState(() => _preview = text);
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مولد المستندات')),
      body: _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selected?.key),
                    initialValue: _selected?.key,
                    decoration:
                        const InputDecoration(labelText: 'اختر النموذج'),
                    items: _templates
                        .map((t) => DropdownMenuItem(
                            value: t.key, child: Text(t.titleAr)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selected = _templates
                            .firstWhere((t) => t.key == v);
                      });
                      _rebuildFields();
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_selected != null) ...[
                    ..._fields.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextField(
                            controller: e.value,
                            decoration:
                                InputDecoration(labelText: e.key),
                            onChanged: (_) => _updatePreview(),
                          ),
                        )),
                    const SizedBox(height: 8),
                    const SectionHeader(title: 'المعاينة'),
                    const SizedBox(height: 6),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(_preview,
                            style: const TextStyle(height: 1.9)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('تصدير PDF'),
                          onPressed: _preview.isEmpty
                              ? null
                              : () => sharePdf(
                                  'marasim_${_selected!.key}.pdf',
                                  _selected!.titleAr,
                                  _preview),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('نسخ النص'),
                          onPressed: _preview.isEmpty
                              ? null
                              : () {
                                  Clipboard.setData(
                                      ClipboardData(text: _preview));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('تم نسخ النص')));
                                },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('مشاركة'),
                          onPressed: _preview.isEmpty
                              ? null
                              : () => Share.share(
                                  '${_selected!.titleAr}\n\n$_preview'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                        'ملاحظة: تصدير DOCX غير متوفر في هذه النسخة (سيُضاف لاحقًا) — التصدير المتاح هو PDF.',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.stone)),
                  ],
                ],
              ),
            ),
    );
  }
}

// ═══════════ 5. مدقق البروتوكول ═══════════

class CheckerPickerPage extends StatefulWidget {
  const CheckerPickerPage({super.key});
  @override
  State<CheckerPickerPage> createState() => _CheckerPickerPageState();
}

class _CheckerPickerPageState extends State<CheckerPickerPage> {
  List<EventItem> _events = [];

  @override
  void initState() {
    super.initState();
    Repo.i.allEvents().then((e) {
      if (mounted) setState(() => _events = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدقق البروتوكول')),
      body: _events.isEmpty
          ? const EmptyState(
              icon: Icons.fact_check,
              text: 'لا توجد مناسبات محفوظة لتدقيقها.\nأنشئ مناسبة أولًا من منظم المناسبات.')
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _events.length,
              itemBuilder: (ctx, i) {
                final e = _events[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.fact_check,
                        color: AppColors.navy),
                    title: Text(e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${e.type} • ${e.date}'),
                    trailing: const Icon(Icons.arrow_back_ios, size: 14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CheckerPage(eventId: e.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _Issue {
  final String severity; // خطأ | تنبيه
  final String title, detail, rule, sourceName, sourceOrg, recommendation;
  const _Issue(this.severity, this.title, this.detail, this.rule,
      this.sourceName, this.sourceOrg, this.recommendation);
}

class CheckerPage extends StatefulWidget {
  final int eventId;
  const CheckerPage({super.key, required this.eventId});
  @override
  State<CheckerPage> createState() => _CheckerPageState();
}

class _CheckerPageState extends State<CheckerPage> {
  EventItem? _event;
  List<_Issue> _issues = [];
  bool _loading = true;
  bool _clean = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<String> _sourceFor(String section) async {
    final arts = await Repo.i.articlesBySection(section);
    if (arts.isEmpty) return 'دليل البروتوكول — مراسم';
    return '${arts.first.sourceName} — ${arts.first.sourceOrg}';
  }

  Future<void> _run() async {
    final e = await Repo.i.eventById(widget.eventId);
    if (e == null) return;
    final guests = await Repo.i.eventGuests(widget.eventId);
    final program = await Repo.i.eventProgram(widget.eventId);
    final checklist = await Repo.i.checklist(widget.eventId);
    final issues = <_Issue>[];

    final visitsSrc = await _sourceFor('الزيارات الرسمية');
    final receptionSrc = await _sourceFor('استقبال الوفود');
    final titlesSrc = await _sourceFor('الألقاب الرسمية');
    const precedenceSrc =
        'اتفاقية فيينا للعلاقات الدبلوماسية 1961، المادتان 13 و16 — الأمم المتحدة';

    // 1. No program at all.
    if (program.isEmpty) {
      issues.add(_Issue(
        'خطأ',
        'لا يوجد برنامج للمناسبة',
        'المناسبة بلا أي فقرات في برنامجها.',
        'برنامج الزيارة أو المناسبة عنصر أساسي في التحضير البروتوكولي.',
        visitsSrc,
        '',
        'أضف فقرات البرنامج من صفحة المناسبة: الاستقبال، الاجتماعات، الفعاليات، المغادرة.',
      ));
    }
    // 2. Program without a reception item.
    if (program.isNotEmpty &&
        !program.any((p) => ((p['title'] ?? '') as String).contains('استقبال'))) {
      issues.add(_Issue(
        'تنبيه',
        'البرنامج بلا فقرة استقبال',
        'لم نعثر على فقرة استقبال في البرنامج.',
        'مراسم الاستقبال أول عناصر برنامج أي وفد رسمي.',
        receptionSrc,
        '',
        'أضف فقرة «استقبال الوفد» في بداية البرنامج مع المكان والوقت.',
      ));
    }
    // 3. Guests without a rank/title.
    final noRank = guests
        .where((g) => ((g['rank_category'] ?? '') as String).isEmpty)
        .toList();
    if (noRank.isNotEmpty) {
      issues.add(_Issue(
        'خطأ',
        'ضيوف بلا فئة أسبقية',
        '${noRank.length} من الضيوف بلا فئة منصب محددة، فلا يمكن ترتيبهم.',
        'تحديد فئة كل ضيف شرط لترتيب الأسبقية والجلوس.',
        titlesSrc,
        '',
        'حدد فئة المنصب لكل ضيف من قائمة الضيوف.',
      ));
    }
    // 4. Guests not in precedence order.
    if (guests.length >= 2) {
      final ordered = orderByPrecedence(
          guests.map((g) => Map<String, dynamic>.from(g)).toList());
      var inOrder = true;
      for (var i = 0; i < guests.length; i++) {
        if (guests[i]['name'] != ordered[i]['name']) {
          inOrder = false;
          break;
        }
      }
      if (!inOrder) {
        issues.add(const _Issue(
          'خطأ',
          'قائمة الضيوف ليست مرتبة حسب الأسبقية',
          'ترتيب الضيوف الحالي يخالف قواعد الأسبقية.',
          'يتقدم رؤساء البعثات في فئتهم بحسب تاريخ وساعة تولي مهامهم.',
          precedenceSrc,
          '',
          'أعد ترتيب الضيوف حسب الأسبقية (يمكنك استخدام الترتيب التلقائي في مخطط الجلوس).',
        ));
      }
    }
    // 5. Event date coincides with a guest country's national day.
    final days = await Repo.i.upcomingNationalDays(days: 400);
    final eventDate = e.date;
    for (final g in guests) {
      final country = (g['country'] ?? '') as String;
      if (country.isEmpty) continue;
      for (final nd in days) {
        if (nd.countryAr != country) continue;
        final mmdd =
            '${nd.nextDate.month.toString().padLeft(2, '0')}-${nd.nextDate.day.toString().padLeft(2, '0')}';
        if (eventDate.substring(5) == mmdd) {
          issues.add(_Issue(
            'تنبيه',
            'تاريخ المناسبة يوافق العيد الوطني لدولة ضيف',
            'يوم ${e.date} يوافق ${nd.name} (${nd.countryAr}).',
            'مراعاة الأعياد الوطنية للضيوف من قواعد الإتيكيت الدبلوماسي.',
            'موسوعة الدول — مراسم',
            '',
            'راعِ المناسبة في البرنامج (تهنئة رسمية) أو أعد جدولة التاريخ إن أمكن.',
          ));
        }
      }
    }
    // 6. Banquet without speeches.
    if (e.type.contains('مأدبة') &&
        !program.any((p) =>
            ((p['title'] ?? '') as String).contains('كلمة') ||
            ((p['title'] ?? '') as String).contains('خطاب') ||
            ((p['title'] ?? '') as String).contains('نخب'))) {
      issues.add(_Issue(
        'تنبيه',
        'مأدبة رسمية بلا فقرة كلمات أو أنخاب',
        'لا توجد فقرة كلمة أو نخب في برنامج المأدبة.',
        'الكلمات والأنخاب جزء معتاد من برنامج المآدب الرسمية.',
        await _sourceFor('المآدب الرسمية'),
        '',
        'أضف فقرة «كلمة ترحيبية وأنخاب» إلى البرنامج.',
      ));
    }
    // 7. Incomplete checklist.
    final undone = checklist.where((c) => (c['done'] as int) == 0).length;
    if (checklist.isNotEmpty && undone > 0) {
      issues.add(_Issue(
        'تنبيه',
        'قائمة التحقق غير مكتملة',
        'بقي $undone من ${checklist.length} بنود غير منجزة.',
        'استكمال قائمة التحقق قبل المناسبة من أساسيات التنظيم.',
        'قوائم التحقق — مراسم',
        '',
        'راجع قائمة التحقق من صفحة المناسبة وأكمل البنود المتبقية.',
      ));
    }

    if (!mounted) return;
    setState(() {
      _event = e;
      _issues = issues;
      _clean = issues.isEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نتيجة التدقيق')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clean
              ? const EmptyState(
                  icon: Icons.check_circle,
                  text: 'لا توجد مشاكل.\nخطة المناسبة سليمة وفق القواعد التي تم فحصها.')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _issues.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                            'تم العثور على ${_issues.length} ملاحظات في خطة «${_event?.title ?? ''}»:',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      );
                    }
                    final iss = _issues[i - 1];
                    final isError = iss.severity == 'خطأ';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                    isError
                                        ? Icons.error_outline
                                        : Icons.warning_amber_outlined,
                                    color: isError
                                        ? Colors.red
                                        : Colors.amber[800]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(iss.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                ),
                                Chip(
                                  label: Text(iss.severity,
                                      style: const TextStyle(fontSize: 11)),
                                  backgroundColor: isError
                                      ? const Color(0xFFFDE8E8)
                                      : const Color(0xFFFFF4D6),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(iss.detail,
                                style: const TextStyle(height: 1.7)),
                            const SizedBox(height: 6),
                            Text('القاعدة: ${iss.rule}',
                                style: const TextStyle(
                                    height: 1.7, color: AppColors.stone)),
                            Text('المصدر: ${iss.sourceName}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.stone)),
                            const SizedBox(height: 6),
                            Text('التوصية: ${iss.recommendation}',
                                style: const TextStyle(
                                    height: 1.7,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
