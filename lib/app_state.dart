import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'db.dart';

/// App-wide state: language, font size, notifications, night mode and the
/// optional (future) generative API key. All values persist in the settings
/// table so they survive restarts.
class AppState extends ChangeNotifier {
  String language = 'ar';
  double fontScale = 1.0;
  bool notifDays = true;
  bool notifEvents = true;
  bool darkMode = false;
  String apiKey = '';

  Future<void> load() async {
    language = await Repo.i.getSetting('language', 'ar');
    fontScale =
        double.tryParse(await Repo.i.getSetting('font_scale', '1.0')) ?? 1.0;
    notifDays = (await Repo.i.getSetting('notif_days', '1')) == '1';
    notifEvents = (await Repo.i.getSetting('notif_events', '1')) == '1';
    darkMode = (await Repo.i.getSetting('dark_mode', '0')) == '1';
    apiKey = await Repo.i.getSetting('api_key', '');
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    language = v;
    await Repo.i.setSetting('language', v);
    notifyListeners();
  }

  Future<void> setFontScale(double v) async {
    fontScale = v.clamp(0.9, 1.3);
    await Repo.i.setSetting('font_scale', fontScale.toStringAsFixed(2));
    notifyListeners();
  }

  Future<void> setNotifDays(bool v) async {
    notifDays = v;
    await Repo.i.setSetting('notif_days', v ? '1' : '0');
    notifyListeners();
  }

  Future<void> setNotifEvents(bool v) async {
    notifEvents = v;
    await Repo.i.setSetting('notif_events', v ? '1' : '0');
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    darkMode = v;
    await Repo.i.setSetting('dark_mode', v ? '1' : '0');
    notifyListeners();
  }

  Future<void> setApiKey(String v) async {
    apiKey = v.trim();
    await Repo.i.setSetting('api_key', apiKey);
    notifyListeners();
  }
}

/// All user-visible UI chrome (labels, buttons, hints, empty states, dialogs)
/// in Arabic and English. Article and country CONTENT stays Arabic with
/// English names — translating the knowledge base itself is a separate
/// effort, noted in the README.
const _strings = {
  // Navigation
  'home': {'ar': 'الرئيسية', 'en': 'Home'},
  'library': {'ar': 'المكتبة', 'en': 'Library'},
  'tools': {'ar': 'الأدوات', 'en': 'Tools'},
  'more': {'ar': 'المزيد', 'en': 'More'},
  'assistant': {'ar': 'المساعد الذكي', 'en': 'AI Assistant'},
  // Home
  'search_hint': {
    'ar': 'ابحث في البروتوكول والدول والنماذج...',
    'en': 'Search protocol, countries, templates...'
  },
  'assistant_desc': {
    'ar': 'اسأل عن أي قاعدة بروتوكولية — إجابات موثقة بالمصادر، دون إنترنت',
    'en': 'Ask any protocol question — sourced answers, fully offline'
  },
  'protocol': {'ar': 'البروتوكول الدبلوماسي', 'en': 'Diplomatic Protocol'},
  'ceremonies': {'ar': 'المراسم الرسمية', 'en': 'Official Ceremonies'},
  'flags': {'ar': 'الأعلام والرموز', 'en': 'Flags & Symbols'},
  'precedence': {'ar': 'الأسبقية والألقاب', 'en': 'Precedence & Titles'},
  'etiquette': {'ar': 'الإتيكيت الدولي', 'en': 'International Etiquette'},
  'events': {'ar': 'إدارة المناسبات', 'en': 'Event Management'},
  'countries': {'ar': 'موسوعة الدول', 'en': 'Countries Encyclopedia'},
  'countries_sub': {
    'ar': 'معلومات الدول وبروتوكولها المحلي',
    'en': 'Country facts and local protocol'
  },
  'latest': {'ar': 'أحدث المقالات', 'en': 'Latest Articles'},
  'upcoming': {'ar': 'المناسبات الوطنية القادمة', 'en': 'Upcoming National Days'},
  'no_national_days': {
    'ar': 'لا توجد أعياد وطنية خلال الثلاثين يومًا القادمة.',
    'en': 'No national days in the next 30 days.'
  },
  'view_all': {'ar': 'عرض الكل', 'en': 'View all'},
  'hero_caption': {
    'ar': 'مراسم — منصة البروتوكول الدولي',
    'en': 'MARASIM — International Protocol Platform'
  },
  // Search
  'search': {'ar': 'ابحث...', 'en': 'Search...'},
  'tab_articles': {'ar': 'المقالات', 'en': 'Articles'},
  'tab_countries': {'ar': 'الدول', 'en': 'Countries'},
  'tab_templates': {'ar': 'النماذج', 'en': 'Templates'},
  'search_empty_hint': {
    'ar': 'اكتب كلمة للبحث في المقالات والدول والنماذج.',
    'en': 'Type a word to search articles, countries and templates.'
  },
  'search_no_results': {'ar': 'لا توجد نتائج مطابقة.', 'en': 'No matching results.'},
  // Assistant
  'assistant_welcome': {
    'ar':
        'مرحبًا، أنا مساعد مراسم الذكي. أسألني عن أي قاعدة بروتوكولية، وسأجيبك من قاعدة المعرفة الموثوقة مع ذكر المصدر. أعمل دون إنترنت.',
    'en':
        'Hello, I am the MARASIM assistant. Ask me any protocol question and I will answer from the trusted knowledge base, citing the source. I work fully offline.'
  },
  'assistant_searching': {
    'ar': 'أبحث في قاعدة المعرفة...',
    'en': 'Searching the knowledge base...'
  },
  'assistant_no_info': {
    'ar': 'لا توجد معلومة موثوقة في قاعدة المعرفة حول «{q}». لا أستطيع الإجابة من دون مصدر موثوق — جرّب صياغة أخرى، أو تصفّح دليل البروتوكول، أو اسأل عن موضوع ذي صلة.',
    'en':
        'There is no reliable information in the knowledge base on «{q}». I cannot answer without a trusted source — try another phrasing, browse the protocol guide, or ask about a related topic.'
  },
  'assistant_search_error': {
    'ar': 'حدث خطأ أثناء البحث في قاعدة المعرفة. جرّب مرة أخرى، أو تصفّح دليل البروتوكول مباشرة.',
    'en':
        'An error occurred while searching the knowledge base. Please try again, or browse the protocol guide directly.'
  },
  'assistant_answer_intro': {
    'ar': 'إليك الإجابة من قاعدة المعرفة:',
    'en': 'Here is the answer from the knowledge base:'
  },
  'assistant_related': {'ar': 'مواضيع ذات صلة:', 'en': 'Related topics:'},
  'assistant_offline_note': {
    'ar': 'يعمل دون إنترنت — إجابات موثقة بالمصادر',
    'en': 'Works offline — answers cited with sources'
  },
  'assistant_how_title': {'ar': 'كيف يعمل المساعد؟', 'en': 'How does the assistant work?'},
  'assistant_how_body': {
    'ar':
        'المساعد يبحث فقط في قاعدة المعرفة الموثوقة داخل التطبيق، ويذكر مصدر كل إجابة وتاريخ مراجعتها. لا يخترع قواعد أو ألقابًا أو مراتب أسبقية. إن لم تتوفر معلومة موثوقة يقول ذلك بوضوح. يعمل دون إنترنت. يمكن إضافة مفتاح API اختياري من الإعدادات لوضع توليدي مستقبلي — والتطبيق يعمل كاملًا بدونه.',
    'en':
        'The assistant searches only the trusted knowledge base inside the app and cites the source and review date of every answer. It never invents rules, titles, or precedence ranks. If no reliable information exists, it says so clearly. It works offline. An optional API key can be added in Settings for a future generative mode — the app works fully without it.'
  },
  'assistant_understood': {'ar': 'فهمت', 'en': 'Understood'},
  'assistant_draft': {'ar': 'صياغة مستند', 'en': 'Draft a document'},
  'assistant_draft_sub': {
    'ar': 'اختر النموذج، واملأ الحقول، وسيُصاغ المستند من القالب المعتمد.',
    'en': 'Choose a template, fill in the fields, and the document will be drafted from the approved form.'
  },
  'assistant_check_plan': {'ar': 'مراجعة خطة مناسبة', 'en': 'Review an event plan'},
  'assistant_write_question': {'ar': 'اكتب سؤالك هنا...', 'en': 'Type your question here...'},
  'assistant_browse_guide': {'ar': 'تصفح دليل البروتوكول', 'en': 'Browse the protocol guide'},
  'draft_invitation': {'ar': 'دعوة رسمية', 'en': 'Formal invitation'},
  'draft_visit_program': {'ar': 'برنامج زيارة رسمية', 'en': 'Official visit program'},
  'draft_meeting_agenda': {'ar': 'جدول اجتماع', 'en': 'Meeting agenda'},
  'draft_event_checklist': {'ar': 'قائمة تحقق لمناسبة', 'en': 'Event checklist'},
  // Encyclopedia / countries
  'countries_search_hint': {
    'ar': 'ابحث عن دولة أو عاصمة...',
    'en': 'Search for a country or capital...'
  },
  'countries_no_match': {
    'ar': 'لا توجد دولة مطابقة للبحث.',
    'en': 'No country matches the search.'
  },
  'country_protocol': {
    'ar': 'المراسم والبروتوكول المحلي',
    'en': 'Local ceremonies and protocol'
  },
  'country_titles': {'ar': 'الألقاب والمخاطبات', 'en': 'Titles and forms of address'},
  'capital': {'ar': 'العاصمة', 'en': 'Capital'},
  'language': {'ar': 'اللغة الرسمية', 'en': 'Official language'},
  'currency': {'ar': 'العملة', 'en': 'Currency'},
  'timezone': {'ar': 'المنطقة الزمنية', 'en': 'Time zone'},
  'system': {'ar': 'النظام السياسي', 'en': 'Political system'},
  'national_day': {'ar': 'العيد الوطني', 'en': 'National day'},
  // Protocol guide
  'guide_title': {'ar': 'دليل البروتوكول الدولي', 'en': 'International Protocol Guide'},
  'guide_empty': {
    'ar': 'تعذّر تحميل أقسام الدليل. تحقق من الاتصال وحاول مرة أخرى.',
    'en': 'The guide sections could not be loaded. Please try again.'
  },
  'section_empty': {
    'ar': 'لا توجد مقالات في هذا القسم بعد.',
    'en': 'No articles in this section yet.'
  },
  // Library
  'library_docs': {
    'ar': 'الوثائق والاتفاقيات الدولية',
    'en': 'International documents and conventions'
  },
  'library_templates': {
    'ar': 'النماذج والقوالب الجاهزة',
    'en': 'Ready-made forms and templates'
  },
  'library_search_hint': {'ar': 'ابحث في المكتبة...', 'en': 'Search the library...'},
  'library_no_templates': {
    'ar': 'لا توجد نماذج مطابقة للبحث.',
    'en': 'No templates match the search.'
  },
  'library_note': {
    'ar':
        'ملاحظة: الوثائق الدولية روابط إلى مصادرها الرسمية (الأمم المتحدة وغيرها) ولا تُخزَّن داخل التطبيق احترامًا لحقوق النشر.',
    'en':
        'Note: international documents are links to their official sources (the United Nations and others) and are not stored inside the app, in respect of copyright.'
  },
  'open_link_failed': {'ar': 'تعذر فتح الرابط', 'en': 'Could not open the link'},
  'library_load_failed': {'ar': 'تعذر تحميل المكتبة، حاول مجددًا', 'en': 'Could not load the library, please try again'},
  // Favorites
  'favorites': {'ar': 'المفضلة', 'en': 'Favorites'},
  'favorites_empty': {
    'ar': 'لا توجد عناصر مفضلة بعد.\nاضغط على النجمة في أي مقال أو دولة لحفظها هنا.',
    'en':
        'No favorites yet.\nTap the star on any article or country to save it here.'
  },
  'favorites_articles': {'ar': 'مقالات مفضلة', 'en': 'Favorite articles'},
  'favorites_countries': {'ar': 'دول مفضلة', 'en': 'Favorite countries'},
  // Settings
  'settings': {'ar': 'الإعدادات', 'en': 'Settings'},
  'settings_language': {'ar': 'اللغة / Language', 'en': 'Language / اللغة'},
  'settings_font': {'ar': 'حجم الخط', 'en': 'Font size'},
  'settings_notif_days': {'ar': 'تذكير بالأعياد الوطنية', 'en': 'National-day reminders'},
  'settings_notif_days_sub': {
    'ar': 'إشعار صباحي في يوم العيد الوطني لكل دولة',
    'en': 'A morning notification on each country’s national day'
  },
  'settings_notif_events': {'ar': 'تذكير بالمناسبات', 'en': 'Event reminders'},
  'settings_notif_events_sub': {
    'ar': 'إشعار صباح يوم المناسبة',
    'en': 'A notification on the morning of the event'
  },
  'settings_dark': {'ar': 'الوضع الليلي', 'en': 'Night mode'},
  'settings_dark_sub': {
    'ar': 'مظهر داكن مريح للعين في الإضاءة الخافتة',
    'en': 'A dark, eye-friendly look for low light'
  },
  'settings_generative': {'ar': 'الوضع التوليدي (اختياري)', 'en': 'Generative mode (optional)'},
  'settings_generative_desc': {
    'ar':
        'المساعد الحالي يعمل دون إنترنت من قاعدة المعرفة الموثوقة. لوضع توليدي متقدم مستقبلًا، يمكنك إضافة مفتاح API هنا — يُحفظ على جهازك فقط ولا يُرسل إلا لخدمة الذكاء الاصطناعي التي تختارها، والتطبيق يعمل كاملًا بدونه.',
    'en':
        'The current assistant works offline from the trusted knowledge base. For a future advanced generative mode, you can add an API key here — it is stored on your device only and is sent only to the AI service you choose; the app works fully without it.'
  },
  'settings_api_label': {'ar': 'مفتاح API (اختياري)', 'en': 'API key (optional)'},
  'settings_save_key': {'ar': 'حفظ المفتاح', 'en': 'Save key'},
  'settings_key_saved': {
    'ar': 'تم حفظ المفتاح على جهازك',
    'en': 'The key was saved on your device'
  },
  'settings_reschedule': {'ar': 'إعادة جدولة التذكيرات', 'en': 'Reschedule reminders'},
  'settings_rescheduled': {'ar': 'تمت إعادة جدولة التذكيرات', 'en': 'Reminders rescheduled'},
  // About
  'about': {'ar': 'عن مراسم', 'en': 'About MARASIM'},
  'about_title': {'ar': 'عن مراسم | About MARASIM', 'en': 'About MARASIM | عن مراسم'},
  'about_desc': {
    'ar':
        'منصة رقمية متخصصة في المعرفة الدبلوماسية والمراسم الدولية: دليل بروتوكول موثوق بمصادره، وموسوعة للدول، ومساعد ذكي يعمل دون إنترنت، وأدوات تنفيذية لتنظيم المناسبات والزيارات الرسمية.',
    'en':
        'A digital platform for diplomatic knowledge and international ceremonies: a sourced, trusted protocol guide, a countries encyclopedia, an offline AI assistant, and practical tools for organizing events and official visits.'
  },
  'about_disclaimer': {
    'ar':
        'هذا التطبيق مرجع معرفي وأداة تنظيمية؛ وليس جهة حكومية ولا منظمة دولية معتمدة. القواعد المنسوبة إلى اتفاقيات دولية مذكورة بمصادرها، وما عداها ممارسات وأعراف موضحة بصفتها.',
    'en':
        'This app is a knowledge reference and an organizational tool; it is not a government body or an accredited international organization. Rules attributed to international conventions are cited with their sources; everything else is identified as practice or custom.'
  },
  'founder_dev': {'ar': 'Founder & Developer', 'en': 'Founder & Developer'},
  'founder_of': {'ar': 'Founder of MARASIM', 'en': 'Founder of MARASIM'},
  // Common
  'save': {'ar': 'حفظ', 'en': 'Save'},
  'cancel': {'ar': 'إلغاء', 'en': 'Cancel'},
  'delete': {'ar': 'حذف', 'en': 'Delete'},
  'confirm': {'ar': 'تأكيد', 'en': 'Confirm'},
  'retry': {'ar': 'إعادة المحاولة', 'en': 'Retry'},
  'close': {'ar': 'إغلاق', 'en': 'Close'},
  'share': {'ar': 'مشاركة', 'en': 'Share'},
  'source': {'ar': 'المصدر:', 'en': 'Source:'},
  'last_review': {'ar': 'آخر مراجعة:', 'en': 'Last reviewed:'},
  'error_generic': {
    'ar': 'حدث خطأ. حاول مرة أخرى.',
    'en': 'Something went wrong. Please try again.'
  },
  'field_required': {'ar': 'هذا الحقل مطلوب', 'en': 'This field is required'},
  // Tools hub
  'tools_title': {'ar': 'الأدوات العملية', 'en': 'Practical Tools'},
  'tool_precedence': {'ar': 'حاسبة الأسبقية', 'en': 'Precedence Calculator'},
  'tool_precedence_sub': {
    'ar': 'رتّب الشخصيات وفق قواعد الأسبقية الدبلوماسية',
    'en': 'Order people by diplomatic precedence rules'
  },
  'tool_seating': {'ar': 'مخطط الجلوس', 'en': 'Seating Planner'},
  'tool_seating_sub': {
    'ar': 'طاولة مستديرة أو مستطيلة أو على شكل U',
    'en': 'Round, rectangular, or U-shaped table'
  },
  'tool_events': {'ar': 'منظم المناسبات', 'en': 'Event Organizer'},
  'tool_events_sub': {
    'ar': 'أنشئ مناسبة بضيوفها وبرنامجها وقوائمها',
    'en': 'Create an event with its guests, program, and checklists'
  },
  'tool_docs': {'ar': 'مولد المستندات', 'en': 'Document Generator'},
  'tool_docs_sub': {
    'ar': 'دعوات وخطابات وبرامج — تصدير PDF',
    'en': 'Invitations, letters, programs — PDF export'
  },
  'tool_checker': {'ar': 'مدقق البروتوكول', 'en': 'Protocol Checker'},
  'tool_checker_sub': {
    'ar': 'راجع خطة مناسبة واكتشف الأخطاء',
    'en': 'Review an event plan and spot mistakes'
  },
  // Precedence calculator
  'prec_intro': {
    'ar':
        'أضف الشخصيات (الاسم والمنصب والدولة وتاريخ تقديم أوراق الاعتماد للسفراء)، ثم اضغط «احسب الترتيب».',
    'en':
        'Add people (name, post, country, and credential date for ambassadors), then tap “Calculate order”.'
  },
  'prec_name_post': {'ar': 'الاسم / المنصب', 'en': 'Name / Post'},
  'prec_category': {'ar': 'الفئة', 'en': 'Category'},
  'prec_country': {'ar': 'الدولة', 'en': 'Country'},
  'prec_cred_date': {
    'ar': 'تاريخ تقديم أوراق الاعتماد (YYYY-MM-DD)',
    'en': 'Credential presentation date (YYYY-MM-DD)'
  },
  'prec_add_person': {'ar': 'إضافة شخص', 'en': 'Add person'},
  'prec_compute': {'ar': 'احسب الترتيب', 'en': 'Calculate order'},
  'prec_result': {'ar': 'الترتيب المقترح', 'en': 'Suggested order'},
  'prec_share': {'ar': 'مشاركة الترتيب', 'en': 'Share the order'},
  'prec_need_one': {
    'ar': 'أضف شخصًا واحدًا على الأقل مع الاسم أولًا',
    'en': 'Add at least one person with a name first'
  },
  'prec_bad_date': {
    'ar': 'تاريخ اعتماد غير صحيح لـ «{name}»: استخدم الصيغة YYYY-MM-DD',
    'en': 'Invalid credential date for “{name}”: use the format YYYY-MM-DD'
  },
  'prec_ignored': {
    'ar': 'تم تجاهل {n} بلا اسم',
    'en': 'Ignored {n} without a name'
  },
  'prec_share_fail': {'ar': 'تعذرت المشاركة، حاول مجددًا', 'en': 'Sharing failed, please try again'},
  'prec_rule_text': {
    'ar':
        'القاعدة: يتقدم رؤساء البعثات في فئتهم بحسب تاريخ وساعة تولي مهامهم (المادة 16)، ويُحدَّد تاريخ التولي بتقديم أوراق الاعتماد (المادة 13). أما ترتيب الفئات فيتبع المادة 14.',
    'en':
        'Rule: heads of mission take precedence within their class by the date and time they took up their functions (Article 16); the date of taking up functions is set by presenting credentials (Article 13). The order of classes follows Article 14.'
  },
  'prec_accred': {'ar': 'اعتماد:', 'en': 'Credentials:'},
  // Seating
  'seat_new': {'ar': 'مخطط جديد', 'en': 'New plan'},
  'seat_empty': {
    'ar': 'لا توجد مخططات محفوظة بعد.\nأنشئ مخططًا لمائدة مستديرة أو مستطيلة أو على شكل U.',
    'en': 'No saved plans yet.\nCreate a plan for a round, rectangular, or U-shaped table.'
  },
  'seat_delete_title': {'ar': 'حذف المخطط', 'en': 'Delete plan'},
  'seat_delete_body': {'ar': 'سيتم حذف مخطط «{name}» نهائيًا.', 'en': 'Plan “{name}” will be permanently deleted.'},
  'seat_delete_fail': {'ar': 'تعذر حذف المخطط، حاول مجددًا', 'en': 'Could not delete the plan, please try again'},
  'seat_seats': {'ar': 'مقاعد', 'en': 'seats'},
  'seat_name': {'ar': 'اسم المخطط', 'en': 'Plan name'},
  'seat_shape': {'ar': 'شكل المائدة', 'en': 'Table shape'},
  'seat_seats_label': {'ar': 'المقاعد:', 'en': 'Seats:'},
  'seat_table': {'ar': 'المائدة', 'en': 'Table'},
  'seat_table_rect': {'ar': 'المائدة المستطيلة', 'en': 'Rectangular table'},
  'seat_table_u': {'ar': 'المائدة (شكل U)', 'en': 'U-shaped table'},
  'seat_no_guests': {
    'ar': 'لا يوجد ضيوف بعد — أضف ضيوفًا لعرضهم على المائدة.',
    'en': 'No guests yet — add guests to show them at the table.'
  },
  'seat_auto': {'ar': 'ترتيب تلقائي حسب الأسبقية', 'en': 'Auto-arrange by precedence'},
  'seat_add_guest': {'ar': 'إضافة ضيف', 'en': 'Add guest'},
  'seat_guest_name': {'ar': 'اسم الضيف', 'en': 'Guest name'},
  'seat_arranged': {
    'ar': 'تم الترتيب حسب الأسبقية الدبلوماسية',
    'en': 'Arranged by diplomatic precedence'
  },
  'seat_need_name': {'ar': 'أدخل اسمًا للمخطط أولًا', 'en': 'Enter a plan name first'},
  'seat_ignored': {'ar': 'تم تجاهل {n} بلا اسم', 'en': 'Ignored {n} without a name'},
  'seat_too_many': {
    'ar': 'عدد الضيوف ({n}) يتجاوز عدد المقاعد ({seats}) — ستظهر أول {seats} فقط على المائدة',
    'en': 'Guests ({n}) exceed the seats ({seats}) — only the first {seats} will appear at the table'
  },
  'seat_save_fail': {'ar': 'تعذر حفظ المخطط، حاول مجددًا', 'en': 'Could not save the plan, please try again'},
  'seat_saved': {'ar': 'تم حفظ المخطط', 'en': 'Plan saved'},
  'shape_round': {'ar': 'مستديرة', 'en': 'Round'},
  'shape_rect': {'ar': 'مستطيلة', 'en': 'Rectangular'},
  'shape_u': {'ar': 'U', 'en': 'U'},
  // Events
  'events_title': {'ar': 'منظم المناسبات', 'en': 'Event Organizer'},
  'event_new': {'ar': 'مناسبة جديدة', 'en': 'New event'},
  'event_title_label': {'ar': 'اسم المناسبة', 'en': 'Event name'},
  'event_type': {'ar': 'نوع المناسبة', 'en': 'Event type'},
  'event_place': {'ar': 'المكان', 'en': 'Place'},
  'event_date': {'ar': 'التاريخ:', 'en': 'Date:'},
  'event_guests_expected': {'ar': 'عدد الضيوف المتوقع:', 'en': 'Expected guests:'},
  'event_create': {'ar': 'إنشاء', 'en': 'Create'},
  'event_need_title': {'ar': 'أدخل اسم المناسبة', 'en': 'Enter the event name'},
  'event_need_place': {'ar': 'أدخل مكان المناسبة', 'en': 'Enter the event place'},
  'event_empty': {
    'ar': 'لا توجد مناسبات بعد.\nأنشئ مناسبة وسيُنشأ لها برنامج وقائمة تحقق وتذكير تلقائيًا.',
    'en': 'No events yet.\nCreate an event and a program, checklist, and reminder will be generated automatically.'
  },
  'event_delete_title': {'ar': 'حذف المناسبة', 'en': 'Delete event'},
  'event_delete_body': {
    'ar': 'سيتم حذف مناسبة «{name}» مع ضيوفها وبرنامجها وقائمة التحقق نهائيًا.',
    'en': 'Event “{name}” will be permanently deleted with its guests, program, and checklist.'
  },
  'event_delete_fail': {'ar': 'تعذر حذف المناسبة، حاول مجددًا', 'en': 'Could not delete the event, please try again'},
  'event_type_visit': {'ar': 'زيارة رسمية', 'en': 'Official visit'},
  'event_type_conference': {'ar': 'مؤتمر', 'en': 'Conference'},
  'event_type_celebration': {'ar': 'احتفال', 'en': 'Celebration'},
  'event_type_bilateral': {'ar': 'اجتماع ثنائي', 'en': 'Bilateral meeting'},
  'event_type_banquet': {'ar': 'مأدبة رسمية', 'en': 'Official banquet'},
  // Event detail
  'event_detail_title': {'ar': 'المناسبة', 'en': 'Event'},
  'tab_guests': {'ar': 'الضيوف', 'en': 'Guests'},
  'tab_program': {'ar': 'البرنامج', 'en': 'Program'},
  'tab_checklist': {'ar': 'قائمة التحقق', 'en': 'Checklist'},
  'event_check_protocol': {'ar': 'تدقيق البروتوكول', 'en': 'Check protocol'},
  'guests_count': {'ar': 'الضيوف ({n})', 'en': 'Guests ({n})'},
  'guests_empty': {'ar': 'لا يوجد ضيوف بعد.', 'en': 'No guests yet.'},
  'program_title': {'ar': 'برنامج المناسبة', 'en': 'Event program'},
  'program_add': {'ar': 'إضافة فقرة', 'en': 'Add item'},
  'program_empty': {'ar': 'لا توجد فقرات بعد.', 'en': 'No items yet.'},
  'checklist_count': {'ar': 'قائمة التحقق ({done}/{total})', 'en': 'Checklist ({done}/{total})'},
  'checklist_add': {'ar': 'إضافة بند', 'en': 'Add item'},
  'checklist_empty': {'ar': 'لا توجد بنود بعد.', 'en': 'No items yet.'},
  'guest_add_title': {'ar': 'إضافة ضيف', 'en': 'Add guest'},
  'guest_need_name': {'ar': 'أدخل اسم الضيف', 'en': 'Enter the guest name'},
  'guest_add': {'ar': 'إضافة', 'en': 'Add'},
  'program_add_title': {'ar': 'إضافة فقرة للبرنامج', 'en': 'Add program item'},
  'program_time': {'ar': 'الوقت', 'en': 'Time'},
  'program_item_title': {'ar': 'عنوان الفقرة', 'en': 'Item title'},
  'program_need_time': {'ar': 'أدخل الوقت', 'en': 'Enter the time'},
  'program_time_format': {
    'ar': 'استخدم الصيغة HH:MM مثل 10:00',
    'en': 'Use the format HH:MM, e.g. 10:00'
  },
  'program_need_title': {'ar': 'أدخل عنوان الفقرة', 'en': 'Enter the item title'},
  'checklist_add_title': {'ar': 'إضافة بند لقائمة التحقق', 'en': 'Add checklist item'},
  'checklist_item': {'ar': 'البند', 'en': 'Item'},
  'checklist_need_text': {'ar': 'أدخل نص البند', 'en': 'Enter the item text'},
  // Document generator
  'docs_title': {'ar': 'مولد المستندات', 'en': 'Document Generator'},
  'docs_empty': {'ar': 'لا توجد نماذج متاحة.', 'en': 'No templates available.'},
  'docs_choose': {'ar': 'اختر النموذج', 'en': 'Choose a template'},
  'docs_preview': {'ar': 'المعاينة', 'en': 'Preview'},
  'docs_export_pdf': {'ar': 'تصدير PDF', 'en': 'Export PDF'},
  'docs_copy': {'ar': 'نسخ النص', 'en': 'Copy text'},
  'docs_share': {'ar': 'مشاركة', 'en': 'Share'},
  'docs_docx_note': {
    'ar': 'ملاحظة: تصدير DOCX غير متوفر في هذه النسخة (سيُضاف لاحقًا) — التصدير المتاح هو PDF.',
    'en': 'Note: DOCX export is not available in this version (coming later) — PDF export is available.'
  },
  'docs_missing_export': {
    'ar': 'أكمل الحقول التالية قبل التصدير: {fields}',
    'en': 'Complete the following fields before exporting: {fields}'
  },
  'docs_missing_copy': {
    'ar': 'أكمل الحقول التالية قبل النسخ: {fields}',
    'en': 'Complete the following fields before copying: {fields}'
  },
  'docs_missing_share': {
    'ar': 'أكمل الحقول التالية قبل المشاركة: {fields}',
    'en': 'Complete the following fields before sharing: {fields}'
  },
  'docs_copied': {'ar': 'تم نسخ النص', 'en': 'Text copied'},
  'docs_pdf_fail': {
    'ar': 'تعذر إنشاء ملف PDF أو مشاركته، حاول مجددًا',
    'en': 'Could not create or share the PDF, please try again'
  },
  'docs_share_fail': {'ar': 'تعذرت المشاركة، حاول مجددًا', 'en': 'Sharing failed, please try again'},
  // Protocol checker
  'checker_empty': {
    'ar': 'لا توجد مناسبات محفوظة لتدقيقها.\nأنشئ مناسبة أولًا من منظم المناسبات.',
    'en': 'No saved events to check.\nCreate an event first in the event organizer.'
  },
  'checker_result': {'ar': 'نتيجة التدقيق', 'en': 'Check result'},
  'checker_not_found': {'ar': 'المناسبة غير موجودة أو حُذفت.', 'en': 'The event does not exist or was deleted.'},
  'checker_clean': {
    'ar': 'لا توجد مشاكل.\nخطة المناسبة سليمة وفق القواعد التي تم فحصها.',
    'en': 'No issues.\nThe event plan is sound under the rules checked.'
  },
  'checker_found': {
    'ar': 'تم العثور على {n} ملاحظات في خطة «{name}»:',
    'en': 'Found {n} notes in the plan for “{name}”:'
  },
  'sev_error': {'ar': 'خطأ', 'en': 'Error'},
  'sev_warning': {'ar': 'تنبيه', 'en': 'Warning'},
  'chk_no_program': {'ar': 'لا يوجد برنامج للمناسبة', 'en': 'No program for the event'},
  'chk_no_program_detail': {
    'ar': 'المناسبة بلا أي فقرات في برنامجها.',
    'en': 'The event has no items in its program.'
  },
  'chk_no_program_rule': {
    'ar': 'برنامج الزيارة أو المناسبة عنصر أساسي في التحضير البروتوكولي.',
    'en': 'A visit or event program is a core element of protocol preparation.'
  },
  'chk_no_program_rec': {
    'ar': 'أضف فقرات البرنامج من صفحة المناسبة: الاستقبال، الاجتماعات، الفعاليات، المغادرة.',
    'en': 'Add program items from the event page: reception, meetings, activities, departure.'
  },
  'chk_no_reception': {'ar': 'البرنامج بلا فقرة استقبال', 'en': 'Program has no reception item'},
  'chk_no_reception_detail': {
    'ar': 'لم نعثر على فقرة استقبال في البرنامج.',
    'en': 'No reception item was found in the program.'
  },
  'chk_no_reception_rule': {
    'ar': 'مراسم الاستقبال أول عناصر برنامج أي وفد رسمي.',
    'en': 'Reception ceremonies are the first element of any official delegation program.'
  },
  'chk_no_reception_rec': {
    'ar': 'أضف فقرة «استقبال الوفد» في بداية البرنامج مع المكان والوقت.',
    'en': 'Add a “Reception of the delegation” item at the start of the program, with place and time.'
  },
  'chk_no_rank': {'ar': 'ضيوف بلا فئة أسبقية', 'en': 'Guests without a precedence category'},
  'chk_no_rank_detail': {
    'ar': '{n} من الضيوف بلا فئة منصب محددة، فلا يمكن ترتيبهم.',
    'en': '{n} guests have no post category set, so they cannot be ordered.'
  },
  'chk_no_rank_rule': {
    'ar': 'تحديد فئة كل ضيف شرط لترتيب الأسبقية والجلوس.',
    'en': 'Setting each guest’s category is required to order precedence and seating.'
  },
  'chk_no_rank_rec': {
    'ar': 'حدد فئة المنصب لكل ضيف من قائمة الضيوف.',
    'en': 'Set the post category for each guest in the guest list.'
  },
  'chk_not_ordered': {
    'ar': 'قائمة الضيوف ليست مرتبة حسب الأسبقية',
    'en': 'Guest list is not ordered by precedence'
  },
  'chk_not_ordered_detail': {
    'ar': 'ترتيب الضيوف الحالي يخالف قواعد الأسبقية.',
    'en': 'The current guest order violates the precedence rules.'
  },
  'chk_not_ordered_rule': {
    'ar': 'يتقدم رؤساء البعثات في فئتهم بحسب تاريخ وساعة تولي مهامهم.',
    'en': 'Heads of mission take precedence within their class by the date and time they took up their functions.'
  },
  'chk_not_ordered_rec': {
    'ar': 'أعد ترتيب الضيوف حسب الأسبقية (يمكنك استخدام الترتيب التلقائي في مخطط الجلوس).',
    'en': 'Reorder the guests by precedence (you can use the auto-arrange in the seating planner).'
  },
  'chk_nat_day': {
    'ar': 'تاريخ المناسبة يوافق العيد الوطني لدولة ضيف',
    'en': 'Event date coincides with a guest country’s national day'
  },
  'chk_nat_day_detail': {
    'ar': 'يوم {date} يوافق {name} ({country}).',
    'en': '{date} coincides with {name} ({country}).'
  },
  'chk_nat_day_rule': {
    'ar': 'مراعاة الأعياد الوطنية للضيوف من قواعد الإتيكيت الدبلوماسي.',
    'en': 'Respecting guests’ national days is part of diplomatic etiquette.'
  },
  'chk_nat_day_rec': {
    'ar': 'راعِ المناسبة في البرنامج (تهنئة رسمية) أو أعد جدولة التاريخ إن أمكن.',
    'en': 'Acknowledge the occasion in the program (a formal greeting) or reschedule the date if possible.'
  },
  'chk_no_speeches': {
    'ar': 'مأدبة رسمية بلا فقرة كلمات أو أنخاب',
    'en': 'Official banquet with no speeches or toasts'
  },
  'chk_no_speeches_detail': {
    'ar': 'لا توجد فقرة كلمة أو نخب في برنامج المأدبة.',
    'en': 'No speech or toast item is in the banquet program.'
  },
  'chk_no_speeches_rule': {
    'ar': 'الكلمات والأنخاب جزء معتاد من برنامج المآدب الرسمية.',
    'en': 'Speeches and toasts are a customary part of official banquet programs.'
  },
  'chk_no_speeches_rec': {
    'ar': 'أضف فقرة «كلمة ترحيبية وأنخاب» إلى البرنامج.',
    'en': 'Add a “Welcome speech and toasts” item to the program.'
  },
  'chk_checklist': {'ar': 'قائمة التحقق غير مكتملة', 'en': 'Checklist incomplete'},
  'chk_checklist_detail': {
    'ar': 'بقي {n} من {total} بنود غير منجزة.',
    'en': '{n} of {total} items are still not done.'
  },
  'chk_checklist_rule': {
    'ar': 'استكمال قائمة التحقق قبل المناسبة من أساسيات التنظيم.',
    'en': 'Completing the checklist before the event is a basic of organization.'
  },
  'chk_checklist_rec': {
    'ar': 'راجع قائمة التحقق من صفحة المناسبة وأكمل البنود المتبقية.',
    'en': 'Review the checklist on the event page and complete the remaining items.'
  },
  'chk_rule_prefix': {'ar': 'القاعدة:', 'en': 'Rule:'},
  'chk_source_prefix': {'ar': 'المصدر:', 'en': 'Source:'},
  'chk_rec_prefix': {'ar': 'التوصية:', 'en': 'Recommendation:'},
  'version': {'ar': 'الإصدار', 'en': 'Version'},
};

String tr(AppState s, String key) {
  final m = _strings[key];
  if (m == null) return key;
  return m[s.language] ?? m['ar']!;
}

/// Translation lookup from a build context (reads the current language from
/// the nearest AppState). Use inside widgets that do not hold AppState.
String trc(BuildContext context, String key) {
  final lang = Provider.of<AppState>(context, listen: false).language;
  final m = _strings[key];
  if (m == null) return key;
  return m[lang] ?? m['ar']!;
}

/// Current app version (keep in sync with pubspec.yaml).
const appVersion = '1.0.1';

/// English display labels for precedence rank keys (Arabic labels live in
/// db.dart rankLabel). Content values are never translated — only the UI.
const rankLabelsEn = {
  'head_state': 'Head of State / King / Ruling Prince',
  'head_gov': 'Head of Government',
  'crown': 'Crown Prince / Vice President',
  'foreign_minister': 'Foreign Minister',
  'ambassador': 'Ambassador',
  'minister': 'Minister',
  'charge': "Chargé d'affaires",
  'deputy_minister': 'Undersecretary / Deputy Minister',
  'director_general': 'Director General',
  'senior_official': 'Senior Official',
};

/// Rank display label in the current UI language.
String rankLabelTr(BuildContext context, String key) {
  if (Provider.of<AppState>(context, listen: false).language == 'en') {
    return rankLabelsEn[key] ?? key;
  }
  return rankLabel(key);
}
