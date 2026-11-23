import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Must stay identical to norm() in tools/build_db.py.
String normalizeAr(String s) {
  s = s.replaceAll('\u0648\u0670', 'ا').replaceAll('\u0649\u0670', 'ى').replaceAll('\u0670', 'ا');
  s = s.replaceAll(RegExp(r'[\u064B-\u065F\u06D6-\u06ED\u0640]'), '');
  s = s.replaceAll(RegExp(r'[إأآٱ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');
  s = s.replaceAll(RegExp(r'[^\u0621-\u064A\u0660-\u0669a-zA-Z0-9\s]'), ' ');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Builds an FTS5 MATCH expression: every query term matches with or without
/// the "ال" prefix. Terms are ANDed; variants of one term are ORed.
String _searchExpr(String normed) {
  final groups = <String>[];
  for (final t in normed.split(' ')) {
    if (t.isEmpty) continue;
    final variants = <String>{t};
    if (t.startsWith('ال') && t.length > 4) {
      variants.add(t.substring(2));
    } else {
      variants.add('ال$t');
    }
    groups.add('(${variants.map((v) => '"$v"*').join(' OR ')})');
  }
  return groups.join(' AND ');
}

/// Diplomatic precedence ranks (general order; ambassadors within one rank
/// order by credential date — VCDR 1961 Arts. 13 and 16).
/// (key, Arabic label, rank)
const precedenceRanks = [
  ('head_state', 'رئيس دولة / ملك / أمير حاكم', 1),
  ('head_gov', 'رئيس حكومة', 2),
  ('crown', 'ولي عهد / نائب رئيس الدولة', 3),
  ('foreign_minister', 'وزير الخارجية', 4),
  ('ambassador', 'سفير', 5),
  ('minister', 'وزير', 6),
  ('charge', 'قائم بالأعمال', 7),
  ('deputy_minister', 'وكيل وزارة / نائب وزير', 8),
  ('director_general', 'مدير عام', 9),
  ('senior_official', 'مسؤول رفيع', 10),
];

int rankOf(String key) {
  for (final r in precedenceRanks) {
    if (r.$1 == key) return r.$3;
  }
  return 99;
}

String rankLabel(String key) {
  for (final r in precedenceRanks) {
    if (r.$1 == key) return r.$2;
  }
  return key;
}

/// Orders a list of guest maps (with keys rank_category, credential_date,
/// name) by the precedence rules and returns them sorted.
List<Map<String, dynamic>> orderByPrecedence(List<Map<String, dynamic>> guests) {
  final list = List<Map<String, dynamic>>.from(guests);
  list.sort((a, b) {
    final ra = rankOf((a['rank_category'] ?? '') as String);
    final rb = rankOf((b['rank_category'] ?? '') as String);
    if (ra != rb) return ra.compareTo(rb);
    final da = ((a['credential_date'] ?? '') as String);
    final db = ((b['credential_date'] ?? '') as String);
    if (da.isNotEmpty && db.isNotEmpty && da != db) return da.compareTo(db);
    if (da.isEmpty && db.isNotEmpty) return 1;
    if (da.isNotEmpty && db.isEmpty) return -1;
    return ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String);
  });
  return list;
}

class Article {
  final int id;
  final String title, section, body, ruleType, sourceName, sourceOrg, sourceUrl, reviewed;
  const Article(this.id, this.title, this.section, this.body, this.ruleType,
      this.sourceName, this.sourceOrg, this.sourceUrl, this.reviewed);
  factory Article.fromMap(Map<String, Object?> m) => Article(
        m['id'] as int,
        m['title'] as String,
        m['section'] as String,
        m['body'] as String,
        m['rule_type'] as String,
        m['source_name'] as String,
        m['source_org'] as String,
        (m['source_url'] ?? '') as String,
        (m['reviewed'] ?? '') as String,
      );
}

class Country {
  final int id;
  final String nameAr, nameEn, capital, languages, currency, timezones, system;
  final String? nationalDay;
  final String nationalDayName, protocolNote, titlesNote, flag;
  final String sourceName, sourceOrg, sourceUrl, reviewed;
  const Country(
      this.id,
      this.nameAr,
      this.nameEn,
      this.capital,
      this.languages,
      this.currency,
      this.timezones,
      this.system,
      this.nationalDay,
      this.nationalDayName,
      this.protocolNote,
      this.titlesNote,
      this.flag,
      this.sourceName,
      this.sourceOrg,
      this.sourceUrl,
      this.reviewed);
  factory Country.fromMap(Map<String, Object?> m) => Country(
        m['id'] as int,
        m['name_ar'] as String,
        m['name_en'] as String,
        m['capital'] as String,
        m['languages'] as String,
        m['currency'] as String,
        m['timezones'] as String,
        m['system'] as String,
        m['national_day'] as String?,
        m['national_day_name'] as String,
        m['protocol_note'] as String,
        m['titles_note'] as String,
        m['flag'] as String,
        m['source_name'] as String,
        m['source_org'] as String,
        (m['source_url'] ?? '') as String,
        (m['reviewed'] ?? '') as String,
      );
}

class TemplateDoc {
  final int id;
  final String key, titleAr, titleEn, category, bodyAr, bodyEn, sourceName, reviewed;
  const TemplateDoc(this.id, this.key, this.titleAr, this.titleEn, this.category,
      this.bodyAr, this.bodyEn, this.sourceName, this.reviewed);
  factory TemplateDoc.fromMap(Map<String, Object?> m) => TemplateDoc(
        m['id'] as int,
        m['key'] as String,
        m['title_ar'] as String,
        m['title_en'] as String,
        m['category'] as String,
        m['body_ar'] as String,
        m['body_en'] as String,
        m['source_name'] as String,
        (m['reviewed'] ?? '') as String,
      );
}

class NationalDayItem {
  final int countryId;
  final String mmdd, name, countryAr, flag;
  final DateTime nextDate;
  const NationalDayItem(
      this.countryId, this.mmdd, this.name, this.countryAr, this.flag, this.nextDate);
}

class EventItem {
  final int id, guestsExpected;
  final String title, type, date, place, notes, createdAt;
  const EventItem(this.id, this.title, this.type, this.date, this.place,
      this.guestsExpected, this.notes, this.createdAt);
  factory EventItem.fromMap(Map<String, Object?> m) => EventItem(
        m['id'] as int,
        m['title'] as String,
        m['type'] as String,
        m['date'] as String,
        m['place'] as String,
        (m['guests_expected'] as int?) ?? 0,
        (m['notes'] ?? '') as String,
        (m['created_at'] ?? '') as String,
      );
}

class SeatingPlan {
  final int id, seats;
  final String name, shape, createdAt, updatedAt;
  const SeatingPlan(
      this.id, this.name, this.shape, this.seats, this.createdAt, this.updatedAt);
  factory SeatingPlan.fromMap(Map<String, Object?> m) => SeatingPlan(
        m['id'] as int,
        m['name'] as String,
        m['shape'] as String,
        m['seats'] as int,
        (m['created_at'] ?? '') as String,
        (m['updated_at'] ?? '') as String,
      );
}

/// Public reference documents (links only — no copyrighted books).
class LibraryDoc {
  final String title, org, url, kind;
  const LibraryDoc(this.title, this.org, this.url, this.kind);
}

const libraryDocs = [
  LibraryDoc(
      'اتفاقية فيينا للعلاقات الدبلوماسية 1961 (النص الكامل)',
      'الأمم المتحدة — مجموعة المعاهدات',
      'https://treaties.un.org/doc/Treaties/1964/06/19640624%2002-10%20AM/Ch_III_3p.pdf',
      'اتفاقية دولية'),
  LibraryDoc(
      'اتفاقية فيينا للعلاقات القنصلية 1963 (النص الكامل)',
      'الأمم المتحدة — مجموعة المعاهدات',
      'https://treaties.un.org/doc/treaties/1967/06/19670608%2010-36%20am/ch_iii_6p.pdf',
      'اتفاقية دولية'),
  LibraryDoc(
      'ميثاق الأمم المتحدة (النص الكامل)',
      'الأمم المتحدة',
      'https://treaties.un.org/doc/Publication/CTC/uncharter.pdf',
      'وثيقة دولية'),
  LibraryDoc(
      'دليل المراسم — بروتوكول الأمم المتحدة (Manual of Protocol)',
      'الأمم المتحدة — إدارة شؤون الجمعية العامة والمؤتمرات',
      'https://www.un.org/dgacm/en/content/protocol/manual-of-protocol',
      'دليل مراسم'),
  LibraryDoc(
      'صفحة البروتوكول — الأمم المتحدة',
      'الأمم المتحدة — إدارة شؤون الجمعية العامة والمؤتمرات',
      'https://www.un.org/dgacm/en/content/protocol',
      'مرجع رسمي'),
  LibraryDoc(
      'Protocol for the Modern Diplomat',
      'وزارة الخارجية الأمريكية — معهد الخدمة الخارجية (2005)',
      'https://www.govinfo.gov/app/details/GOVPUB-S-PURL-LPS81568',
      'دليل مراسم'),
];

class Repo {
  static final Repo i = Repo._();
  Repo._();
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'marasim.db');
    if (!await File(path).exists()) {
      final data = await rootBundle.load('assets/marasim.db');
      await File(path).writeAsBytes(data.buffer.asUint8List());
    }
    _db = await openDatabase(path);
    return _db!;
  }

  Future<String> meta(String key) async {
    final d = await db;
    final rows = await d.query('meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return '';
    return (rows.first['value'] ?? '') as String;
  }

  // ── Search (FTS5) ──
  Future<List<Article>> searchArticles(String q, {int limit = 20}) async {
    final d = await db;
    final n = normalizeAr(q);
    if (n.isEmpty) return [];
    final rows = await d.rawQuery(
        'SELECT a.* FROM articles a JOIN articles_fts f ON f.rowid = a.id '
        'WHERE articles_fts MATCH ? ORDER BY rank LIMIT ?',
        [_searchExpr(n), limit]);
    return rows.map(Article.fromMap).toList();
  }

  Future<List<Country>> searchCountries(String q, {int limit = 20}) async {
    final d = await db;
    final n = normalizeAr(q);
    if (n.isEmpty) return [];
    final rows = await d.rawQuery(
        'SELECT c.* FROM countries c JOIN countries_fts f ON f.rowid = c.id '
        'WHERE countries_fts MATCH ? ORDER BY rank LIMIT ?',
        [_searchExpr(n), limit]);
    return rows.map(Country.fromMap).toList();
  }

  Future<List<TemplateDoc>> searchTemplates(String q, {int limit = 20}) async {
    final d = await db;
    final n = normalizeAr(q);
    if (n.isEmpty) return [];
    final rows = await d.rawQuery(
        'SELECT t.* FROM templates t JOIN templates_fts f ON f.rowid = t.id '
        'WHERE templates_fts MATCH ? ORDER BY rank LIMIT ?',
        [_searchExpr(n), limit]);
    return rows.map(TemplateDoc.fromMap).toList();
  }

  // ── Articles ──
  Future<List<String>> sections() async {
    final d = await db;
    final rows = await d.rawQuery(
        'SELECT DISTINCT section FROM articles ORDER BY MIN(id)');
    return rows.map((r) => r['section'] as String).toList();
  }

  Future<List<Article>> articlesBySection(String section) async {
    final d = await db;
    final rows = await d.query('articles',
        where: 'section = ?', whereArgs: [section], orderBy: 'id');
    return rows.map(Article.fromMap).toList();
  }

  Future<List<Article>> latestArticles({int limit = 6}) async {
    final d = await db;
    final rows =
        await d.query('articles', orderBy: 'id DESC', limit: limit);
    return rows.map(Article.fromMap).toList();
  }

  Future<Article?> articleById(int id) async {
    final d = await db;
    final rows = await d.query('articles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Article.fromMap(rows.first);
  }

  // ── Countries ──
  Future<List<Country>> allCountries() async {
    final d = await db;
    final rows = await d.query('countries', orderBy: 'name_ar');
    return rows.map(Country.fromMap).toList();
  }

  Future<Country?> countryById(int id) async {
    final d = await db;
    final rows = await d.query('countries', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Country.fromMap(rows.first);
  }

  Future<List<NationalDayItem>> upcomingNationalDays({int days = 30}) async {
    final d = await db;
    final rows = await d.rawQuery(
        'SELECT n.country_id, n.mmdd, n.name, c.name_ar, c.flag '
        'FROM national_days n JOIN countries c ON c.id = n.country_id');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = <NationalDayItem>[];
    for (final r in rows) {
      final mmdd = (r['mmdd'] as String).split('-');
      final month = int.parse(mmdd[0]);
      final day = int.parse(mmdd[1]);
      var next = DateTime(now.year, month, day);
      if (next.isBefore(today)) next = DateTime(now.year + 1, month, day);
      if (next.difference(today).inDays <= days) {
        out.add(NationalDayItem(r['country_id'] as int, r['mmdd'] as String,
            r['name'] as String, r['name_ar'] as String, r['flag'] as String, next));
      }
    }
    out.sort((a, b) => a.nextDate.compareTo(b.nextDate));
    return out;
  }

  // ── Templates ──
  Future<List<TemplateDoc>> allTemplates() async {
    final d = await db;
    final rows = await d.query('templates', orderBy: 'id');
    return rows.map(TemplateDoc.fromMap).toList();
  }

  Future<TemplateDoc?> templateByKey(String key) async {
    final d = await db;
    final rows =
        await d.query('templates', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return TemplateDoc.fromMap(rows.first);
  }

  // ── Favorites ──
  Future<bool> isFav(String kind, int refId) async {
    final d = await db;
    final rows = await d.query('favorites',
        where: 'kind = ? AND ref_id = ?', whereArgs: [kind, refId]);
    return rows.isNotEmpty;
  }

  Future<void> toggleFav(String kind, int refId) async {
    final d = await db;
    if (await isFav(kind, refId)) {
      await d.delete('favorites',
          where: 'kind = ? AND ref_id = ?', whereArgs: [kind, refId]);
    } else {
      await d.insert('favorites', {
        'kind': kind,
        'ref_id': refId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Article>> favArticles() async {
    final d = await db;
    final rows = await d.rawQuery(
        'SELECT a.* FROM articles a JOIN favorites f ON f.ref_id = a.id '
        "WHERE f.kind = 'article' ORDER BY f.created_at DESC");
    return rows.map(Article.fromMap).toList();
  }

  Future<List<Country>> favCountries() async {
    final d = await db;
    final rows = await d.rawQuery(
        'SELECT c.* FROM countries c JOIN favorites f ON f.ref_id = c.id '
        "WHERE f.kind = 'country' ORDER BY f.created_at DESC");
    return rows.map(Country.fromMap).toList();
  }

  // ── Settings ──
  Future<String> getSetting(String key, String def) async {
    final d = await db;
    final rows = await d.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return def;
    return (rows.first['value'] ?? def) as String;
  }

  Future<void> setSetting(String key, String value) async {
    final d = await db;
    await d.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Events ──
  Future<int> insertEvent(Map<String, Object?> values) async {
    final d = await db;
    return d.insert('events', values);
  }

  Future<List<EventItem>> allEvents() async {
    final d = await db;
    final rows = await d.query('events', orderBy: 'date ASC');
    return rows.map(EventItem.fromMap).toList();
  }

  Future<EventItem?> eventById(int id) async {
    final d = await db;
    final rows = await d.query('events', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return EventItem.fromMap(rows.first);
  }

  Future<void> deleteEvent(int id) async {
    final d = await db;
    await d.delete('event_guests', where: 'event_id = ?', whereArgs: [id]);
    await d.delete('event_program', where: 'event_id = ?', whereArgs: [id]);
    await d.delete('checklist_items', where: 'event_id = ?', whereArgs: [id]);
    await d.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> eventGuests(int eventId) async {
    final d = await db;
    return d.query('event_guests',
        where: 'event_id = ?', whereArgs: [eventId], orderBy: 'sort_order ASC');
  }

  Future<int> insertEventGuest(Map<String, Object?> values) async {
    final d = await db;
    return d.insert('event_guests', values);
  }

  Future<void> deleteEventGuest(int id) async {
    final d = await db;
    await d.delete('event_guests', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> eventProgram(int eventId) async {
    final d = await db;
    return d.query('event_program',
        where: 'event_id = ?', whereArgs: [eventId], orderBy: 'sort_order ASC');
  }

  Future<int> insertProgramItem(Map<String, Object?> values) async {
    final d = await db;
    return d.insert('event_program', values);
  }

  Future<void> deleteProgramItem(int id) async {
    final d = await db;
    await d.delete('event_program', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> checklist(int eventId) async {
    final d = await db;
    return d.query('checklist_items',
        where: 'event_id = ?', whereArgs: [eventId], orderBy: 'sort_order ASC');
  }

  Future<int> insertChecklistItem(Map<String, Object?> values) async {
    final d = await db;
    return d.insert('checklist_items', values);
  }

  Future<void> setChecklistDone(int id, bool done) async {
    final d = await db;
    await d.update('checklist_items', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteChecklistItem(int id) async {
    final d = await db;
    await d.delete('checklist_items', where: 'id = ?', whereArgs: [id]);
  }

  // ── Seating plans ──
  Future<int> insertPlan(Map<String, Object?> values) async {
    final d = await db;
    return d.insert('seating_plans', values);
  }

  Future<List<SeatingPlan>> allPlans() async {
    final d = await db;
    final rows = await d.query('seating_plans', orderBy: 'updated_at DESC');
    return rows.map(SeatingPlan.fromMap).toList();
  }

  Future<List<Map<String, Object?>>> planAssignments(int planId) async {
    final d = await db;
    return d.query('seating_assignments',
        where: 'plan_id = ?', whereArgs: [planId], orderBy: 'seat_index ASC');
  }

  Future<void> saveAssignments(
      int planId, List<Map<String, Object?>> assignments) async {
    final d = await db;
    await d.delete('seating_assignments',
        where: 'plan_id = ?', whereArgs: [planId]);
    for (final a in assignments) {
      await d.insert('seating_assignments', {'plan_id': planId, ...a});
    }
    await d.update(
        'seating_plans',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [planId]);
  }

  Future<void> deletePlan(int id) async {
    final d = await db;
    await d.delete('seating_assignments',
        where: 'plan_id = ?', whereArgs: [id]);
    await d.delete('seating_plans', where: 'id = ?', whereArgs: [id]);
  }
}
