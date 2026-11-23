import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'app_state.dart';
import 'db.dart';
import 'notifications.dart';
import 'pdf_export.dart';
import 'widgets.dart';

/// Display label for a stored table shape value.
String _shapeLabel(BuildContext context, String shape) {
  return trc(context, switch (shape) {
    'مستطيلة' => 'shape_rect',
    'U' => 'shape_u',
    _ => 'shape_round',
  });
}

/// Display label for a stored event-type value.
String _eventTypeLabel(BuildContext context, String type) {
  return trc(context, switch (type) {
    'مؤتمر' => 'event_type_conference',
    'احتفال' => 'event_type_celebration',
    'اجتماع ثنائي' => 'event_type_bilateral',
    'مأدبة رسمية' => 'event_type_banquet',
    _ => 'event_type_visit',
  });
}

/// List separator in the current UI language.
String _listSep(BuildContext context) =>
    Provider.of<AppState>(context, listen: false).language == 'en'
        ? ', '
        : '، ';

/// Hub of the practical tools.
class ToolsHubPage extends StatelessWidget {
  const ToolsHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      (trc(context, 'tool_precedence'), Icons.format_list_numbered,
          trc(context, 'tool_precedence_sub'), const PrecedencePage()),
      (trc(context, 'tool_seating'), Icons.event_seat,
          trc(context, 'tool_seating_sub'), const SeatingPlansPage()),
      (trc(context, 'tool_events'), Icons.event,
          trc(context, 'tool_events_sub'), const EventsPage()),
      (trc(context, 'tool_docs'), Icons.description,
          trc(context, 'tool_docs_sub'), const DocGeneratorPage()),
      (trc(context, 'tool_checker'), Icons.fact_check,
          trc(context, 'tool_checker_sub'), const CheckerPickerPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'tools_title'))),
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
  static int _nextId = 0;
  // Stable id so list cards keep their TextFormField state when a person
  // above them is removed (without it, fields show the wrong person's text).
  final int id;
  String name, country, rankKey, credentialDate;
  _Person(
      {this.name = '',
      this.country = '',
      this.rankKey = 'ambassador',
      this.credentialDate = ''})
      : id = _nextId++;
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
    final named = _persons.where((p) => p.name.trim().isNotEmpty).toList();
    if (named.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trc(context, 'prec_need_one'))));
      return;
    }
    // Ambassadors order by credential date: reject a malformed date instead
    // of silently sorting it as a string.
    final badDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    for (final p in named) {
      if (p.rankKey == 'ambassador' && p.credentialDate.trim().isNotEmpty) {
        final d = p.credentialDate.trim();
        if (!badDate.hasMatch(d) || DateTime.tryParse(d) == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(trc(context, 'prec_bad_date')
                  .replaceFirst('{name}', p.name.trim()))));
          return;
        }
      }
    }
    final maps = named
        .map((p) => {
              'name': p.name,
              'country': p.country,
              'rank_category': p.rankKey,
              'credential_date': p.credentialDate,
            })
        .toList();
    final ordered = orderByPrecedence(maps);
    final ignored = _persons.length - named.length;
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
    if (ignored > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trc(context, 'prec_ignored')
              .replaceFirst('{n}', '$ignored'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'tool_precedence'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                trc(context, 'prec_intro'),
                style: TextStyle(color: context.mutedColor)),
            const SizedBox(height: 12),
            ..._persons.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              return Card(
                key: ValueKey('person-${p.id}'),
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
                              decoration: InputDecoration(
                                  labelText: trc(context, 'prec_name_post')),
                              onChanged: (v) => p.name = v,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => setState(() {
                                  _persons.removeAt(i);
                                  _ordered = null;
                                }),
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
                                  InputDecoration(
                                      labelText: trc(context, 'prec_category')),
                              items: precedenceRanks
                                  .map((r) => DropdownMenuItem(
                                      value: r.$1,
                                      child: Text(
                                          rankLabelTr(context, r.$1))))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                    p.rankKey = v ?? 'ambassador';
                                    _ordered = null;
                                  }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: p.country,
                              decoration:
                                  InputDecoration(
                                      labelText: trc(context, 'prec_country')),
                              onChanged: (v) => p.country = v,
                            ),
                          ),
                        ],
                      ),
                      if (p.rankKey == 'ambassador') ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: p.credentialDate,
                          decoration: InputDecoration(
                              labelText: trc(context, 'prec_cred_date'),
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
                  label: Text(trc(context, 'prec_add_person')),
                  onPressed: () => setState(() {
                        _persons.add(_Person());
                        _ordered = null;
                      }),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calculate),
                  label: Text(trc(context, 'prec_compute')),
                  onPressed: _compute,
                ),
              ],
            ),
            if (_ordered != null) ...[
              const SizedBox(height: 16),
              SectionHeader(title: trc(context, 'prec_result')),
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
                        '${rankLabelTr(context, p.rankKey)}${p.country.isNotEmpty ? ' — ${p.country}' : ''}${p.credentialDate.isNotEmpty ? ' • ${trc(context, 'prec_accred')} ${p.credentialDate}' : ''}'),
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
              Text(
                  trc(context, 'prec_rule_text'),
                  style: TextStyle(color: context.mutedColor, height: 1.7)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.share),
                label: Text(trc(context, 'prec_share')),
                onPressed: () async {
                  final lines = _ordered!.asMap().entries.map((e) =>
                      '${e.key + 1}. ${e.value.name} — ${rankLabelTr(context, e.value.rankKey)}${e.value.country.isNotEmpty ? ' (${e.value.country})' : ''}');
                  try {
                    await Share.share(
                        '${trc(context, 'tool_precedence')}:\n${lines.join('\n')}');
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(trc(context, 'prec_share_fail'))));
                    }
                  }
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
      appBar: AppBar(title: Text(trc(context, 'tool_seating'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SeatingEditorPage()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: Text(trc(context, 'seat_new')),
      ),
      body: _plans.isEmpty
          ? EmptyState(
              icon: Icons.event_seat,
              text: trc(context, 'seat_empty'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _plans.length,
              itemBuilder: (ctx, i) {
                final plan = _plans[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.event_seat, color: context.headingColor),
                    title: Text(plan.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${_shapeLabel(context, plan.shape)} • ${plan.seats} ${trc(context, 'seat_seats')} • ${plan.updatedAt.split('T').first}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(trc(context, 'seat_delete_title')),
                            content: Text(trc(context, 'seat_delete_body')
                                .replaceFirst('{name}', plan.name)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(trc(context, 'cancel'))),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(trc(context, 'delete'))),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        try {
                          await Repo.i.deletePlan(plan.id);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(trc(context, 'seat_delete_fail'))));
                          }
                          return;
                        }
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
  static int _nextId = 0;
  // Stable id so guest cards keep their TextFormField state on reorder/delete.
  final int id;
  String name, title, country, rankKey;
  _SeatGuest(
      {this.name = '',
      this.title = '',
      this.country = '',
      this.rankKey = 'ambassador'})
      : id = _nextId++;
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
      // Defensive: a stored shape/seat count outside the current UI range
      // would crash the dropdown (value not in items) or draw wrongly.
      _shape = const ['مستديرة', 'مستطيلة', 'U'].contains(widget.plan!.shape)
          ? widget.plan!.shape
          : 'مستديرة';
      _seats = widget.plan!.seats.clamp(4, 40);
      Repo.i.planAssignments(widget.plan!.id).then((rows) {
        if (!mounted) return;
        setState(() {
          _guests.addAll(rows.map((r) => _SeatGuest(
                name: (r['guest_name'] ?? '') as String,
                title: (r['guest_title'] ?? '') as String,
                country: (r['country'] ?? '') as String,
                rankKey: (r['rank_category'] as String?)?.isNotEmpty == true &&
                        precedenceRanks
                            .any((rk) => rk.$1 == r['rank_category'])
                    ? r['rank_category'] as String
                    : 'ambassador',
              )));
        });
      });
    }
  }

  void _autoArrange() {
    final maps = _guests
        .map((g) => {
              'name': g.name,
              'title': g.title,
              'country': g.country,
              'rank_category': g.rankKey,
              'credential_date': '',
            })
        .toList();
    final ordered = orderByPrecedence(maps);
    setState(() {
      _guests.clear();
      _guests.addAll(ordered.map((m) => _SeatGuest(
            name: m['name'] as String,
            title: (m['title'] ?? '') as String,
            country: (m['country'] ?? '') as String,
            rankKey: m['rank_category'] as String,
          )));
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(trc(context, 'seat_arranged'))));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(trc(context, 'seat_need_name'))));
      return;
    }
    // Blank-name guests would be saved as empty seats: drop them and say so.
    final toSave =
        _guests.where((g) => g.name.trim().isNotEmpty).toList();
    final dropped = _guests.length - toSave.length;
    if (dropped > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trc(context, 'seat_ignored')
              .replaceFirst('{n}', '$dropped'))));
    }
    if (toSave.length > _seats) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(trc(context, 'seat_too_many')
              .replaceFirst('{n}', '${toSave.length}')
              .replaceFirst('{seats}', '$_seats'))));
    }
    final now = DateTime.now().toIso8601String();
    try {
      // Repo has no updatePlan: re-saving an edited plan deletes the old row
      // and inserts the new values, otherwise name/shape/seats edits are lost.
      if (_planId != null) {
        await Repo.i.deletePlan(_planId!);
        _planId = null;
      }
      _planId = await Repo.i.insertPlan({
        'name': _nameCtrl.text.trim(),
        'shape': _shape,
        'seats': _seats,
        'created_at': now,
        'updated_at': now,
      });
      await Repo.i.saveAssignments(
        _planId!,
        toSave.asMap().entries.map((e) => {
              'seat_index': e.key + 1,
              'guest_name': e.value.name,
              'guest_title': e.value.title,
              'country': e.value.country,
              'rank_category': e.value.rankKey,
            }).toList(),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(trc(context, 'seat_save_fail'))));
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(trc(context, 'seat_saved'))));
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
            child: Text(trc(context, 'seat_table'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  color: e.key == 0
                      ? AppColors.gold
                      : (context.isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: context.isDark
                          ? AppColors.darkBorder
                          : AppColors.navy),
                ),
                child: Text(
                  '${e.key + 1}. ${g.name.isEmpty ? '—' : g.name}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.navy,
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
                color: idx == 0
                    ? AppColors.gold
                    : (context.isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        context.isDark ? AppColors.darkBorder : AppColors.navy),
              ),
              child: Text('${idx + 1}. ${g.name.isEmpty ? '—' : g.name}',
                  style: const TextStyle(fontSize: 11, color: AppColors.navy)),
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
              _shape == 'مستطيلة'
                  ? trc(context, 'seat_table_rect')
                  : trc(context, 'seat_table_u'),
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
        title: Text(trc(context, 'tool_seating')),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save, color: Colors.white, size: 18),
            label:
                Text(trc(context, 'save'), style: const TextStyle(color: Colors.white)),
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
              decoration: InputDecoration(labelText: trc(context, 'seat_name')),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_shape),
                    initialValue: _shape,
                    decoration: InputDecoration(labelText: trc(context, 'seat_shape')),
                    items: const ['مستديرة', 'مستطيلة', 'U']
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(_shapeLabel(context, s))))
                        .toList(),
                    onChanged: (v) => setState(() => _shape = v ?? 'مستديرة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(trc(context, 'seat_seats_label')),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(
                            () => _seats = (_seats - 1).clamp(4, 40)),
                      ),
                      Text('$_seats',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(
                            () => _seats = (_seats + 1).clamp(4, 40)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
                child: _shape == 'مستديرة' ? _roundTable() : _rowsTable()),
            if (_guests.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(trc(context, 'seat_no_guests'),
                    style: TextStyle(color: context.mutedColor)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.sort),
                  label: Text(trc(context, 'seat_auto')),
                  onPressed: _guests.isEmpty ? null : _autoArrange,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(trc(context, 'seat_add_guest')),
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
                key: ValueKey('guest-${g.id}'),
                margin: const EdgeInsets.only(bottom: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text('${i + 1}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.headingColor)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: g.name,
                              decoration:
                                  InputDecoration(
                                      labelText: trc(context, 'seat_guest_name')),
                              onChanged: (v) => g.name = v,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    key: ValueKey(g.rankKey),
                                    initialValue: g.rankKey,
                                    decoration: InputDecoration(
                                        labelText: trc(context, 'prec_category')),
                                    items: precedenceRanks
                                        .map((r) => DropdownMenuItem(
                                            value: r.$1,
                                            child: Text(
                                                rankLabelTr(context, r.$1),
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
                                    decoration: InputDecoration(
                                        labelText: trc(context, 'prec_country')),
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
    String? titleError;
    String? placeError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(trc(context, 'event_new')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                        labelText: trc(context, 'event_title_label'),
                        errorText: titleError)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(type),
                  initialValue: type,
                  decoration: InputDecoration(labelText: trc(context, 'event_type')),
                  items: eventTypes
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(_eventTypeLabel(context, t))))
                      .toList(),
                  onChanged: (v) => setD(() => type = v ?? type),
                ),
                const SizedBox(height: 8),
                TextField(
                    controller: placeCtrl,
                    decoration: InputDecoration(
                        labelText: trc(context, 'event_place'),
                        errorText: placeError)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(trc(context, 'event_date')),
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
                    Text(trc(context, 'event_guests_expected')),
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
                child: Text(trc(context, 'cancel'))),
            ElevatedButton(
                onPressed: () {
                  // Validate inside the dialog: an empty title/place used to
                  // close the dialog silently and create nothing.
                  setD(() {
                    titleError = titleCtrl.text.trim().isEmpty
                        ? trc(context, 'event_need_title')
                        : null;
                    placeError = placeCtrl.text.trim().isEmpty
                        ? trc(context, 'event_need_place')
                        : null;
                  });
                  if (titleError == null && placeError == null) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: Text(trc(context, 'event_create'))),
          ],
        ),
      ),
    );
    if (ok != true) {
      titleCtrl.dispose();
      placeCtrl.dispose();
      return;
    }
    // Read values now; the controllers are disposed below.
    final title = titleCtrl.text.trim();
    final place = placeCtrl.text.trim();
    titleCtrl.dispose();
    placeCtrl.dispose();
    if (title.isEmpty || place.isEmpty) return;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final id = await Repo.i.insertEvent({
      'title': title,
      'type': type,
      'date': dateStr,
      'place': place,
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
    // A notification failure must not break event creation.
    final notifOn = await Repo.i.getSetting('notif_events', '1');
    if (notifOn == '1') {
      try {
        await NotificationService.schedule(
          id: 10000 + id,
          title: 'مناسبة اليوم: $title',
          body: 'تبدأ اليوم في $place — راجع قائمة التحقق.',
          when: DateTime(date.year, date.month, date.day, 9),
        );
      } catch (_) {}
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
      appBar: AppBar(title: Text(trc(context, 'events_title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: Text(trc(context, 'event_new')),
      ),
      body: _events.isEmpty
          ? EmptyState(
              icon: Icons.event,
              text: trc(context, 'event_empty'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _events.length,
              itemBuilder: (ctx, i) {
                final e = _events[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.event, color: context.headingColor),
                    title: Text(e.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${_eventTypeLabel(context, e.type)} • ${e.date} • ${e.place}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(trc(context, 'event_delete_title')),
                            content: Text(trc(context, 'event_delete_body')
                                .replaceFirst('{name}', e.title)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(trc(context, 'cancel'))),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(trc(context, 'delete'))),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        try {
                          await Repo.i.deleteEvent(e.id);
                          await NotificationService.cancel(10000 + e.id);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(trc(context, 'event_delete_fail'))));
                          }
                          return;
                        }
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
    String? nameError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(trc(context, 'guest_add_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      labelText: trc(context, 'seat_guest_name'),
                      errorText: nameError)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey(rank),
                initialValue: rank,
                decoration: InputDecoration(labelText: trc(context, 'prec_category')),
                items: precedenceRanks
                    .map((r) => DropdownMenuItem(
                        value: r.$1, child: Text(rankLabelTr(context, r.$1))))
                    .toList(),
                // StatefulBuilder rebuilds the dialog so the new rank shows.
                onChanged: (v) => setD(() => rank = v ?? rank),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: countryCtrl,
                  decoration: InputDecoration(labelText: trc(context, 'prec_country'))),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(trc(context, 'cancel'))),
            ElevatedButton(
                onPressed: () {
                  // Empty name used to close the dialog silently, adding
                  // nothing; keep the dialog open with a visible error.
                  setD(() => nameError = nameCtrl.text.trim().isEmpty
                      ? trc(context, 'guest_need_name')
                      : null);
                  if (nameError == null) Navigator.pop(ctx, true);
                },
                child: Text(trc(context, 'guest_add'))),
          ],
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    final country = countryCtrl.text.trim();
    nameCtrl.dispose();
    countryCtrl.dispose();
    if (ok != true || name.isEmpty) return;
    await Repo.i.insertEventGuest({
      'event_id': widget.eventId,
      'name': name,
      'title': rankLabel(rank),
      'country': country,
      'rank_category': rank,
      'credential_date': '',
      'sort_order': _guests.length,
    });
    _load();
  }

  Future<void> _addProgram() async {
    final timeCtrl = TextEditingController(text: '10:00');
    final titleCtrl = TextEditingController();
    String? timeError;
    String? titleError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(trc(context, 'program_add_title')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: timeCtrl,
                  decoration: InputDecoration(
                      labelText: trc(context, 'program_time'), hintText: '10:00',
                      errorText: timeError)),
              const SizedBox(height: 8),
              TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                      labelText: trc(context, 'program_item_title'),
                      errorText: titleError)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(trc(context, 'cancel'))),
            ElevatedButton(
                onPressed: () {
                  setD(() {
                    final t = timeCtrl.text.trim();
                    timeError = t.isEmpty
                        ? trc(context, 'program_need_time')
                        : !RegExp(r'^\d{1,2}:\d{2}$').hasMatch(t)
                            ? trc(context, 'program_time_format')
                            : null;
                    titleError = titleCtrl.text.trim().isEmpty
                        ? trc(context, 'program_need_title')
                        : null;
                  });
                  if (timeError == null && titleError == null) {
                    Navigator.pop(ctx, true);
                  }
                },
                child: Text(trc(context, 'guest_add'))),
          ],
        ),
      ),
    );
    final time = timeCtrl.text.trim();
    final title = titleCtrl.text.trim();
    timeCtrl.dispose();
    titleCtrl.dispose();
    if (ok != true || title.isEmpty || time.isEmpty) return;
    await Repo.i.insertProgramItem({
      'event_id': widget.eventId,
      'time': time,
      'title': title,
      'notes': '',
      'sort_order': _program.length,
    });
    _load();
  }

  Future<void> _addChecklist() async {
    final ctrl = TextEditingController();
    String? textError;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          scrollable: true,
          title: Text(trc(context, 'checklist_add_title')),
          content: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                  labelText: trc(context, 'checklist_item'),
                  errorText: textError)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(trc(context, 'cancel'))),
            ElevatedButton(
                onPressed: () {
                  setD(() => textError = ctrl.text.trim().isEmpty
                      ? trc(context, 'checklist_need_text')
                      : null);
                  if (textError == null) Navigator.pop(ctx, true);
                },
                child: Text(trc(context, 'guest_add'))),
          ],
        ),
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || text.isEmpty) return;
    await Repo.i.insertChecklistItem({
      'event_id': widget.eventId,
      'text': text,
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
          appBar: AppBar(title: Text(trc(context, 'event_detail_title'))),
          body: const Center(child: CircularProgressIndicator()));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(e.title),
          bottom: TabBar(
            tabs: [
              Tab(text: trc(context, 'tab_guests')),
              Tab(text: trc(context, 'tab_program')),
              Tab(text: trc(context, 'tab_checklist')),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.fact_check),
              tooltip: trc(context, 'event_check_protocol'),
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
                          style: TextStyle(color: context.mutedColor))),
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
              Text(trc(context, 'guests_count')
                  .replaceFirst('{n}', '${_guests.length}'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(trc(context, 'seat_add_guest')),
                onPressed: _addGuest,
              ),
            ],
          ),
        ),
        Expanded(
          child: _guests.isEmpty
              ? EmptyState(
                  icon: Icons.groups, text: trc(context, 'guests_empty'))
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
              Text(trc(context, 'program_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(trc(context, 'program_add')),
                onPressed: _addProgram,
              ),
            ],
          ),
        ),
        Expanded(
          child: _program.isEmpty
              ? EmptyState(
                  icon: Icons.schedule, text: trc(context, 'program_empty'))
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
              Text(trc(context, 'checklist_count')
                .replaceFirst('{done}', '$done')
                .replaceFirst('{total}', '${_checklist.length}'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text(trc(context, 'checklist_add')),
                onPressed: _addChecklist,
              ),
            ],
          ),
        ),
        Expanded(
          child: _checklist.isEmpty
              ? EmptyState(
                  icon: Icons.checklist, text: trc(context, 'checklist_empty'))
              : ListView.builder(
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
  bool _loaded = false;
  bool _exporting = false;

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
      _loaded = true;
      // tpls.first would throw on an empty table; and a templateKey that
      // matches nothing must not crash the dropdown either.
      if (tpls.isNotEmpty) {
        if (widget.templateKey != null) {
          _selected = tpls.firstWhere(
              (t) => t.key == widget.templateKey,
              orElse: () => tpls.first);
        }
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
    if (t == null) {
      setState(() => _preview = '');
      return;
    }
    for (final m in _ph.allMatches(t.bodyAr)) {
      final key = m.group(1)!.trim();
      _fields.putIfAbsent(key, () => TextEditingController());
    }
    _updatePreview();
  }

  /// Names of template fields still empty — every placeholder is required
  /// before generating, copying, or sharing, so no `{{...}}` leaks out.
  List<String> _missingFields() => _fields.entries
      .where((e) => e.value.text.trim().isEmpty)
      .map((e) => e.key)
      .toList();

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportPdf() async {
    if (_selected == null || _exporting) return;
    // Resolve strings before the first await (context after an async gap).
    final missingExport = trc(context, 'docs_missing_export');
    final pdfFail = trc(context, 'docs_pdf_fail');
    final sep = _listSep(context);
    _updatePreview();
    final missing = _missingFields();
    if (missing.isNotEmpty) {
      _showMessage(missingExport
          .replaceFirst('{fields}', missing.join(sep)));
      return;
    }
    setState(() => _exporting = true);
    try {
      await sharePdf(
          'marasim_${_selected!.key}.pdf', _selected!.titleAr, _preview);
    } catch (_) {
      _showMessage(pdfFail);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _copyText() async {
    if (_selected == null) return;
    final missingCopy = trc(context, 'docs_missing_copy');
    final copied = trc(context, 'docs_copied');
    final sep = _listSep(context);
    _updatePreview();
    final missing = _missingFields();
    if (missing.isNotEmpty) {
      _showMessage(missingCopy
          .replaceFirst('{fields}', missing.join(sep)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: _preview));
    _showMessage(copied);
  }

  Future<void> _shareText() async {
    if (_selected == null) return;
    final missingShare = trc(context, 'docs_missing_share');
    final shareFail = trc(context, 'docs_share_fail');
    final sep = _listSep(context);
    _updatePreview();
    final missing = _missingFields();
    if (missing.isNotEmpty) {
      _showMessage(missingShare
          .replaceFirst('{fields}', missing.join(sep)));
      return;
    }
    try {
      await Share.share('${_selected!.titleAr}\n\n$_preview');
    } catch (_) {
      _showMessage(shareFail);
    }
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
      appBar: AppBar(title: Text(trc(context, 'docs_title'))),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? EmptyState(
                  icon: Icons.description,
                  text: trc(context, 'docs_empty'))
              : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selected?.key),
                    initialValue: _selected?.key,
                    decoration:
                        InputDecoration(labelText: trc(context, 'docs_choose')),
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
                    SectionHeader(title: trc(context, 'docs_preview')),
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
                          label: Text(trc(context, 'docs_export_pdf')),
                          onPressed: _preview.isEmpty || _exporting
                              ? null
                              : _exportPdf,
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: Text(trc(context, 'docs_copy')),
                          onPressed: _preview.isEmpty || _exporting
                              ? null
                              : _copyText,
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: Text(trc(context, 'docs_share')),
                          onPressed: _preview.isEmpty || _exporting
                              ? null
                              : _shareText,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                        trc(context, 'docs_docx_note'),
                        style:
                            TextStyle(fontSize: 12, color: context.mutedColor)),
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
      appBar: AppBar(title: Text(trc(context, 'tool_checker'))),
      body: _events.isEmpty
          ? EmptyState(
              icon: Icons.fact_check,
              text: trc(context, 'checker_empty'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _events.length,
              itemBuilder: (ctx, i) {
                final e = _events[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.fact_check,
                        color: context.headingColor),
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
    // Resolve every UI string before the first await: using context
    // after an async gap would warn, and the widget may be disposed.
    final tNoProgram = trc(context, 'chk_no_program');
    final tNoProgramDetail = trc(context, 'chk_no_program_detail');
    final tNoProgramRule = trc(context, 'chk_no_program_rule');
    final tNoProgramRec = trc(context, 'chk_no_program_rec');
    final tNoReception = trc(context, 'chk_no_reception');
    final tNoReceptionDetail = trc(context, 'chk_no_reception_detail');
    final tNoReceptionRule = trc(context, 'chk_no_reception_rule');
    final tNoReceptionRec = trc(context, 'chk_no_reception_rec');
    final tNoRank = trc(context, 'chk_no_rank');
    final tNoRankDetail = trc(context, 'chk_no_rank_detail');
    final tNoRankRule = trc(context, 'chk_no_rank_rule');
    final tNoRankRec = trc(context, 'chk_no_rank_rec');
    final tNotOrdered = trc(context, 'chk_not_ordered');
    final tNotOrderedDetail = trc(context, 'chk_not_ordered_detail');
    final tNotOrderedRule = trc(context, 'chk_not_ordered_rule');
    final tNotOrderedRec = trc(context, 'chk_not_ordered_rec');
    final tNatDay = trc(context, 'chk_nat_day');
    final tNatDayDetail = trc(context, 'chk_nat_day_detail');
    final tNatDayRule = trc(context, 'chk_nat_day_rule');
    final tNatDayRec = trc(context, 'chk_nat_day_rec');
    final tNoSpeeches = trc(context, 'chk_no_speeches');
    final tNoSpeechesDetail = trc(context, 'chk_no_speeches_detail');
    final tNoSpeechesRule = trc(context, 'chk_no_speeches_rule');
    final tNoSpeechesRec = trc(context, 'chk_no_speeches_rec');
    final tChecklist = trc(context, 'chk_checklist');
    final tChecklistDetail = trc(context, 'chk_checklist_detail');
    final tChecklistRule = trc(context, 'chk_checklist_rule');
    final tChecklistRec = trc(context, 'chk_checklist_rec');
    final e = await Repo.i.eventById(widget.eventId);
    // Deleted event used to leave the loading spinner forever.
    if (e == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
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
        tNoProgram,
        tNoProgramDetail,
        tNoProgramRule,
        visitsSrc,
        '',
        tNoProgramRec,
      ));
    }
    // 2. Program without a reception item.
    if (program.isNotEmpty &&
        !program.any((p) => ((p['title'] ?? '') as String).contains('استقبال'))) {
      issues.add(_Issue(
        'تنبيه',
        tNoReception,
        tNoReceptionDetail,
        tNoReceptionRule,
        receptionSrc,
        '',
        tNoReceptionRec,
      ));
    }
    // 3. Guests without a rank/title.
    final noRank = guests
        .where((g) => ((g['rank_category'] ?? '') as String).isEmpty)
        .toList();
    if (noRank.isNotEmpty) {
      issues.add(_Issue(
        'خطأ',
        tNoRank,
        tNoRankDetail
            .replaceFirst('{n}', '${noRank.length}'),
        tNoRankRule,
        titlesSrc,
        '',
        tNoRankRec,
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
        issues.add(_Issue(
          'خطأ',
          tNotOrdered,
          tNotOrderedDetail,
          tNotOrderedRule,
          precedenceSrc,
          '',
          tNotOrderedRec,
        ));
      }
    }
    // 5. Event date coincides with a guest country's national day.
    final days = await Repo.i.upcomingNationalDays(days: 400);
    final eventDate = e.date;
    // Guard a short/malformed stored date: substring(5) used to throw.
    final eventMmdd =
        eventDate.length >= 10 ? eventDate.substring(5, 10) : '';
    for (final g in guests) {
      final country = (g['country'] ?? '') as String;
      if (country.isEmpty || eventMmdd.isEmpty) continue;
      for (final nd in days) {
        if (nd.countryAr != country) continue;
        final mmdd =
            '${nd.nextDate.month.toString().padLeft(2, '0')}-${nd.nextDate.day.toString().padLeft(2, '0')}';
        if (eventMmdd == mmdd) {
          issues.add(_Issue(
            'تنبيه',
            tNatDay,
            tNatDayDetail
                .replaceFirst('{date}', e.date)
                .replaceFirst('{name}', nd.name)
                .replaceFirst('{country}', nd.countryAr),
            tNatDayRule,
            'موسوعة الدول — مراسم',
            '',
            tNatDayRec,
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
        tNoSpeeches,
        tNoSpeechesDetail,
        tNoSpeechesRule,
        await _sourceFor('المآدب الرسمية'),
        '',
        tNoSpeechesRec,
      ));
    }
    // 7. Incomplete checklist.
    final undone = checklist.where((c) => (c['done'] as int) == 0).length;
    if (checklist.isNotEmpty && undone > 0) {
      issues.add(_Issue(
        'تنبيه',
        tChecklist,
        tChecklistDetail
            .replaceFirst('{n}', '$undone')
            .replaceFirst('{total}', '${checklist.length}'),
        tChecklistRule,
        'قوائم التحقق — مراسم',
        '',
        tChecklistRec,
      ));
    }

    if (!mounted) return;
    setState(() {
      _event = e;
      _issues = issues;
      _clean = issues.isEmpty;
      _loading = false;
    });
    } catch (_) {
      // A DB failure used to leave the loading spinner forever.
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(trc(context, 'checker_result'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? EmptyState(
                  icon: Icons.event_busy,
                  text: trc(context, 'checker_not_found'))
              : _clean
                  ? EmptyState(
                      icon: Icons.check_circle,
                      text: trc(context, 'checker_clean'))
                  : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _issues.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                            trc(context, 'checker_found')
                                .replaceFirst('{n}', '${_issues.length}')
                                .replaceFirst('{name}', _event?.title ?? ''),
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
                                  label: Text(trc(context,
                                      iss.severity == 'خطأ'
                                          ? 'sev_error'
                                          : 'sev_warning'),
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
                            Text('${trc(context, 'chk_rule_prefix')} ${iss.rule}',
                                style: TextStyle(
                                    height: 1.7, color: context.mutedColor)),
                            Text('${trc(context, 'chk_source_prefix')} ${iss.sourceName}',
                                style: TextStyle(
                                    fontSize: 12, color: context.mutedColor)),
                            const SizedBox(height: 6),
                            Text('${trc(context, 'chk_rec_prefix')} ${iss.recommendation}',
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
