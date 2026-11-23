#!/usr/bin/env python3
"""Builds assets/marasim.db (SQLite + FTS5) for the MARASIM protocol app.

usage:
  python3 tools/build_db.py <seed-dir> <out.db>     # build
  python3 tools/build_db.py --check <db>            # quick_check: counts + sample searches

Sources: curated seed JSON in tools/seed/ (articles, countries, templates).
Every record carries its source and review date (2026-11-24). The builder
FAILS LOUDLY on any validation error: article count < 24, any of the 16
protocol sections missing, a bad rule_type, a country missing a required
field, a bad national-day format, or duplicate template keys. Nothing is
invented: Vienna Convention citations in the seed use only the article
numbers the team verified (VCDR 1961 Arts. 13-14, 22, 29, 41); anything
else is cited generally or labelled common practice.
"""
import hashlib
import json
import os
import re
import sqlite3
import sys

SECTIONS = [
    'المبادئ العامة للبروتوكول',
    'العلاقات الدبلوماسية',
    'الأسبقية الدبلوماسية',
    'الألقاب الرسمية',
    'الأعلام والرموز الوطنية',
    'المراسم الرئاسية',
    'استقبال الوفود',
    'المراسم الملكية',
    'الزيارات الرسمية',
    'المؤتمرات الدولية',
    'الاجتماعات الثنائية',
    'توقيع الاتفاقيات',
    'المآدب الرسمية',
    'المراسلات الدبلوماسية',
    'الإتيكيت الدولي',
    'مراسم العزاء والتعازي الرسمية',
]

RULE_TYPES = {'ملزمة دوليًا', 'ممارسة شائعة', 'عرف محلي', 'خاص بدولة'}
MMDD = re.compile(r'^\d{2}-\d{2}$')

TASHKEEL = re.compile(r'[\u064B-\u065F\u06D6-\u06ED\u0640]')
ALEF = re.compile(r'[إأآٱ]')
NONWORD = re.compile(r'[^\u0621-\u064A\u0660-\u0669a-zA-Z0-9\s]')
SPACES = re.compile(r'\s+')


def norm(s):
    """Arabic normalization. MUST stay identical to normalizeAr in lib/db.dart."""
    if s is None:
        return ''
    s = str(s)
    s = s.replace('\u0648\u0670', 'ا').replace('\u0649\u0670', 'ى').replace('\u0670', 'ا')
    s = TASHKEEL.sub('', s)
    s = ALEF.sub('ا', s).replace('ى', 'ي').replace('ة', 'ه')
    s = NONWORD.sub(' ', s)
    return SPACES.sub(' ', s).strip()


def _strip_prefix(w):
    for p in ('وال', 'فال', 'بال', 'لل', 'كال'):
        if w.startswith(p) and len(w) - len(p) >= 2:
            return w[len(p):]
    if w.startswith('ال') and len(w) - 2 >= 3:
        return w[2:]
    for p in ('و', 'ف', 'ب', 'ل', 'ك'):
        if w.startswith(p) and len(w) - 1 >= 2:
            return w[1:]
    return None


def search_norm(s):
    words = norm(s).split(' ')
    out = []
    for w in words:
        if not w:
            continue
        out.append(w)
        stripped = _strip_prefix(w)
        if stripped and stripped != w:
            out.append(stripped)
    return ' '.join(out)


def fail(msg):
    print(f'ERROR: {msg}')
    sys.exit(1)


def load_json(path):
    with open(path, encoding='utf-8') as fh:
        return json.load(fh)


def build(seed_dir, out):
    articles = load_json(os.path.join(seed_dir, 'articles.json'))
    countries = load_json(os.path.join(seed_dir, 'countries.json'))
    templates = load_json(os.path.join(seed_dir, 'templates.json'))

    # ── Validation (fail loudly) ──
    if len(articles) < 24:
        fail(f'expected >= 24 articles, got {len(articles)}')
    seen_sections = set()
    for a in articles:
        for f in ('title', 'section', 'body', 'rule_type', 'source_name', 'source_org'):
            if not str(a.get(f, '')).strip():
                fail(f"article {a.get('id')}: empty field {f}")
        if a['section'] not in SECTIONS:
            fail(f"article {a.get('id')}: unknown section {a['section']!r}")
        if a['rule_type'] not in RULE_TYPES:
            fail(f"article {a.get('id')}: bad rule_type {a['rule_type']!r}")
        seen_sections.add(a['section'])
    missing = [s for s in SECTIONS if s not in seen_sections]
    if missing:
        fail(f'sections with no article: {missing}')

    if len(countries) < 25:
        fail(f'expected >= 25 countries, got {len(countries)}')
    for c in countries:
        for f in ('name_ar', 'name_en', 'capital', 'languages', 'currency',
                  'timezones', 'system', 'national_day_name', 'protocol_note',
                  'titles_note', 'flag'):
            if not str(c.get(f, '')).strip():
                fail(f"country {c.get('id')}: empty field {f}")
        nd = c.get('national_day')
        if nd is not None and not MMDD.match(str(nd)):
            fail(f"country {c.get('id')}: bad national_day {nd!r}")

    if len(templates) < 7:
        fail(f'expected >= 7 templates, got {len(templates)}')
    keys = [t.get('key') for t in templates]
    if len(set(keys)) != len(keys):
        fail('duplicate template keys')
    for t in templates:
        for f in ('key', 'title_ar', 'title_en', 'category', 'body_ar', 'body_en'):
            if not str(t.get(f, '')).strip():
                fail(f"template {t.get('id')}: empty field {f}")

    # ── Build ──
    if os.path.exists(out):
        os.remove(out)
    con = sqlite3.connect(out)
    cur = con.cursor()
    cur.executescript('''
    CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT);
    CREATE TABLE articles(id INTEGER PRIMARY KEY, title TEXT, section TEXT,
        body TEXT, rule_type TEXT, source_name TEXT, source_org TEXT,
        source_url TEXT, reviewed TEXT);
    CREATE TABLE countries(id INTEGER PRIMARY KEY, name_ar TEXT, name_en TEXT,
        capital TEXT, languages TEXT, currency TEXT, timezones TEXT,
        system TEXT, national_day TEXT, national_day_name TEXT,
        protocol_note TEXT, titles_note TEXT, flag TEXT,
        source_name TEXT, source_org TEXT, source_url TEXT, reviewed TEXT);
    CREATE TABLE templates(id INTEGER PRIMARY KEY, key TEXT UNIQUE,
        title_ar TEXT, title_en TEXT, category TEXT, body_ar TEXT,
        body_en TEXT, source_name TEXT, reviewed TEXT);
    CREATE TABLE national_days(country_id INTEGER, mmdd TEXT, name TEXT);
    CREATE TABLE favorites(kind TEXT, ref_id INTEGER, created_at TEXT,
        PRIMARY KEY(kind, ref_id));
    CREATE TABLE events(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT,
        type TEXT, date TEXT, place TEXT, guests_expected INTEGER,
        notes TEXT, created_at TEXT);
    CREATE TABLE event_guests(id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER, name TEXT, title TEXT, country TEXT,
        rank_category TEXT, credential_date TEXT, sort_order INTEGER);
    CREATE TABLE event_program(id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER, time TEXT, title TEXT, notes TEXT, sort_order INTEGER);
    CREATE TABLE checklist_items(id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER, text TEXT, done INTEGER DEFAULT 0, sort_order INTEGER);
    CREATE TABLE seating_plans(id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT, shape TEXT, seats INTEGER, created_at TEXT, updated_at TEXT);
    CREATE TABLE seating_assignments(id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER, seat_index INTEGER, guest_name TEXT,
        guest_title TEXT, country TEXT);
    CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT);
    CREATE VIRTUAL TABLE articles_fts USING fts5(
        title, body, section, tokenize='unicode61 remove_diacritics 0');
    CREATE VIRTUAL TABLE countries_fts USING fts5(
        name_ar, name_en, capital, tokenize='unicode61 remove_diacritics 0');
    CREATE VIRTUAL TABLE templates_fts USING fts5(
        title_ar, title_en, body_ar, tokenize='unicode61 remove_diacritics 0');
    ''')

    for a in articles:
        cur.execute('INSERT INTO articles VALUES(?,?,?,?,?,?,?,?,?)',
                    (a['id'], a['title'], a['section'], a['body'], a['rule_type'],
                     a['source_name'], a['source_org'], a.get('source_url', ''),
                     a.get('reviewed', '2026-11-24')))
        cur.execute('INSERT INTO articles_fts(rowid, title, body, section) VALUES(?,?,?,?)',
                    (a['id'], search_norm(a['title']), search_norm(a['body']),
                     search_norm(a['section'])))
    print(f'articles: {len(articles)} ({len(seen_sections)} sections)')

    nd_count = 0
    for c in countries:
        cur.execute('INSERT INTO countries VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                    (c['id'], c['name_ar'], c['name_en'], c['capital'],
                     c['languages'], c['currency'], c['timezones'], c['system'],
                     c.get('national_day'), c['national_day_name'],
                     c['protocol_note'], c['titles_note'], c['flag'],
                     c['source_name'], c['source_org'], c.get('source_url', ''),
                     c.get('reviewed', '2026-11-24')))
        cur.execute('INSERT INTO countries_fts(rowid, name_ar, name_en, capital) VALUES(?,?,?,?)',
                    (c['id'], search_norm(c['name_ar']), search_norm(c['name_en']),
                     search_norm(c['capital'])))
        if c.get('national_day'):
            cur.execute('INSERT INTO national_days VALUES(?,?,?)',
                        (c['id'], c['national_day'], c['national_day_name']))
            nd_count += 1
    print(f'countries: {len(countries)} (national days: {nd_count})')

    for t in templates:
        cur.execute('INSERT INTO templates VALUES(?,?,?,?,?,?,?,?,?)',
                    (t['id'], t['key'], t['title_ar'], t['title_en'], t['category'],
                     t['body_ar'], t['body_en'], t['source_name'],
                     t.get('reviewed', '2026-11-24')))
        cur.execute('INSERT INTO templates_fts(rowid, title_ar, title_en, body_ar) VALUES(?,?,?,?)',
                    (t['id'], search_norm(t['title_ar']), search_norm(t['title_en']),
                     search_norm(t['body_ar'])))
    print(f'templates: {len(templates)}')

    for fts in ('articles_fts', 'countries_fts', 'templates_fts'):
        cur.execute(f"INSERT INTO {fts}({fts}) VALUES('optimize')")

    import datetime
    cur.executemany('INSERT INTO meta VALUES(?,?)', [
        ('db_version', '1'),
        ('built', datetime.date.today().isoformat()),
        ('articles', str(len(articles))),
        ('countries', str(len(countries))),
        ('templates', str(len(templates))),
        ('national_days', str(nd_count)),
        ('credits', 'Protocol knowledge: curated by the MARASIM team from the '
                    'Vienna Convention on Diplomatic Relations 1961, the Vienna '
                    'Convention on Consular Relations 1963, UN documents and '
                    'published foreign-ministry protocol guides; every article '
                    'cites its source. Country facts: UN member-state directory '
                    'and CIA World Factbook (public facts).'),
    ])
    con.commit()
    con.execute('VACUUM')
    con.close()
    h = hashlib.sha256(open(out, 'rb').read()).hexdigest()
    open(out + '.sha256', 'w').write(h)
    print(f'OK size={os.path.getsize(out)/1e6:.2f}MB sha256={h[:12]}…')


def search_expr(normed):
    groups = []
    for t in normed.split(' '):
        if not t:
            continue
        variants = {t}
        if t.startswith('ال') and len(t) > 4:
            variants.add(t[2:])
        else:
            variants.add('ال' + t)
        groups.append('(' + ' OR '.join(f'"{v}"*' for v in variants) + ')')
    return ' AND '.join(groups)


def check(db_path):
    con = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
    cur = con.cursor()
    for tbl in ('articles', 'countries', 'templates', 'national_days'):
        print(f'{tbl}: {cur.execute(f"SELECT COUNT(*) FROM {tbl}").fetchone()[0]}')
    print('sections:',
          cur.execute('SELECT COUNT(DISTINCT section) FROM articles').fetchone()[0])
    print('meta:', dict(cur.execute('SELECT key, value FROM meta').fetchall()))
    for q in ('الأسبقية', 'الأعلام', 'دعوة رسمية', 'زيارة رسمية', 'توقيع اتفاقية'):
        expr = search_expr(search_norm(q))
        a = cur.execute(
            'SELECT COUNT(*) FROM articles_fts WHERE articles_fts MATCH ?',
            (expr,)).fetchone()[0]
        c = cur.execute(
            'SELECT COUNT(*) FROM countries_fts WHERE countries_fts MATCH ?',
            (expr,)).fetchone()[0]
        t = cur.execute(
            'SELECT COUNT(*) FROM templates_fts WHERE templates_fts MATCH ?',
            (expr,)).fetchone()[0]
        print(f'search {q!r}: articles={a} countries={c} templates={t}')
    row = cur.execute(
        "SELECT id, title FROM articles WHERE section='الأسبقية الدبلوماسية' LIMIT 2"
    ).fetchall()
    print('sample precedence articles:', row)
    row = cur.execute(
        "SELECT name_ar, capital, national_day FROM countries WHERE id IN (1, 2, 3)"
    ).fetchall()
    print('sample countries:', row)
    con.close()


if __name__ == '__main__':
    if len(sys.argv) >= 3 and sys.argv[1] == '--check':
        check(sys.argv[2])
    elif len(sys.argv) >= 3:
        build(sys.argv[1], sys.argv[2])
    else:
        print('usage: build_db.py <seed-dir> <out.db> | build_db.py --check <db>')
        sys.exit(2)
