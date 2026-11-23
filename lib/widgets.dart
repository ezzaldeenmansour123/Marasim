import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'app_state.dart';

class AppColors {
  static const navy = Color(0xFF0B2239);
  static const navyLight = Color(0xFF14324F);
  static const gold = Color(0xFFC6A15B);
  static const goldLight = Color(0xFFDEBE82);
  static const pearl = Color(0xFFF7F5F0);
  static const stone = Color(0xFF6B7280);
  static const cardBorder = Color(0xFFE3DCCB);
  // Night mode palette.
  static const darkBg = Color(0xFF0A1826);
  static const darkSurface = Color(0xFF12263A);
  static const darkCard = Color(0xFF162E47);
  static const darkBorder = Color(0xFF2A4258);
  static const darkMuted = Color(0xFF9FB0C3);
  static const darkBody = Color(0xFFE8E4DA);
}

/// Theme-aware colors for text and surfaces that must stay readable in both
/// light and night mode. Use these instead of hardcoded navy/white/stone
/// when the color sits directly on the scaffold or a card background.
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get headingColor => isDark ? AppColors.pearl : AppColors.navy;
  Color get bodyColor =>
      isDark ? AppColors.darkBody : const Color(0xFF1F2937);
  Color get mutedColor => isDark ? AppColors.darkMuted : AppColors.stone;
  Color get cardBorderColor =>
      isDark ? AppColors.darkBorder : AppColors.cardBorder;
}

class AppTheme {
  static ThemeData _base({
    required Brightness brightness,
    required Color scaffold,
    required Color card,
    required Color border,
    required Color heading,
    required Color body,
    required Color muted,
    required Color inputFill,
    required Color chipBg,
    required Color navBg,
    required Color navSelected,
    required Color navUnselected,
    required Color elevatedBg,
    required Color elevatedFg,
    required double fontScale,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: brightness == Brightness.dark ? AppColors.gold : AppColors.navy,
        onPrimary:
            brightness == Brightness.dark ? AppColors.navy : Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.navy,
        surface: card,
        onSurface: heading,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: scaffold,
      canvasColor: navBg,
      fontFamily: 'Cairo',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontSize: 26 * fontScale,
            fontWeight: FontWeight.bold,
            color: heading),
        headlineMedium: TextStyle(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: heading),
        headlineSmall: TextStyle(
            fontSize: 19 * fontScale,
            fontWeight: FontWeight.bold,
            color: heading),
        titleLarge: TextStyle(
            fontSize: 18 * fontScale,
            fontWeight: FontWeight.bold,
            color: heading),
        titleMedium: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
            color: heading),
        bodyLarge: TextStyle(fontSize: 16 * fontScale, color: body),
        bodyMedium: TextStyle(fontSize: 14 * fontScale, color: body),
        bodySmall: TextStyle(fontSize: 12 * fontScale, color: muted),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: navSelected,
        unselectedItemColor: navUnselected,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        titleTextStyle: TextStyle(
            fontSize: 18 * fontScale,
            fontWeight: FontWeight.bold,
            color: heading),
        contentTextStyle:
            TextStyle(fontSize: 14 * fontScale, color: body),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: elevatedBg,
          foregroundColor: elevatedFg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(fontSize: 13 * fontScale, color: body),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
    );
  }

  static ThemeData light(double fontScale) => _base(
        brightness: Brightness.light,
        scaffold: AppColors.pearl,
        card: Colors.white,
        border: AppColors.cardBorder,
        heading: AppColors.navy,
        body: const Color(0xFF1F2937),
        muted: AppColors.stone,
        inputFill: Colors.white,
        chipBg: const Color(0xFFEFF1F5),
        navBg: Colors.white,
        navSelected: AppColors.navy,
        navUnselected: AppColors.stone,
        elevatedBg: AppColors.navy,
        elevatedFg: Colors.white,
        fontScale: fontScale,
      );

  static ThemeData dark(double fontScale) => _base(
        brightness: Brightness.dark,
        scaffold: AppColors.darkBg,
        card: AppColors.darkCard,
        border: AppColors.darkBorder,
        heading: AppColors.pearl,
        body: AppColors.darkBody,
        muted: AppColors.darkMuted,
        inputFill: AppColors.darkSurface,
        chipBg: const Color(0xFF1E3A56),
        navBg: AppColors.navy,
        navSelected: AppColors.gold,
        navUnselected: const Color(0xFF8FA3B8),
        elevatedBg: AppColors.gold,
        elevatedFg: AppColors.navy,
        fontScale: fontScale,
      );
}

/// Full-bleed animated background: the 8 bundled hero photos crossfading
/// every 6 seconds with a slow Ken Burns zoom/pan, behind a dark navy
/// gradient scrim so content stays readable. Lightweight: a single image
/// plus one repeating zoom controller, no blur.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  static const images = [
    'assets/images/hero1.jpg',
    'assets/images/hero2.jpg',
    'assets/images/hero3.jpg',
    'assets/images/hero4.jpg',
    'assets/images/hero5.jpg',
    'assets/images/hero6.jpg',
    'assets/images/hero7.jpg',
    'assets/images/hero8.jpg',
  ];
  int _index = 0;
  Timer? _timer;
  late final AnimationController _zoom;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _zoom = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) setState(() => _index = (_index + 1) % images.length);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final img in images) {
        precacheImage(AssetImage(img), context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1200),
          child: ScaleTransition(
            key: ValueKey(images[_index]),
            scale: Tween<double>(begin: 1.0, end: 1.12).animate(
                CurvedAnimation(parent: _zoom, curve: Curves.easeInOut)),
            child: Image.asset(
              images[_index],
              fit: BoxFit.cover,
              errorBuilder: (c, e, st) => Container(color: AppColors.navy),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.navy.withValues(alpha: 0.72),
                AppColors.navy.withValues(alpha: 0.55),
                AppColors.navy.withValues(alpha: 0.80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A navy tile with a gold icon, used on the home screen.
class HomeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const HomeTile(
      {super.key, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkCard : AppColors.navy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gold, size: 30),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const SectionHeader({super.key, required this.title, this.onMore});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.headingColor)),
        if (onMore != null)
          TextButton(
              onPressed: onMore, child: Text(trc(context, 'view_all'))),
      ],
    );
  }
}

/// Source citation line shown under every article/answer.
class SourceLine extends StatelessWidget {
  final String sourceName, sourceOrg, sourceUrl, reviewed, ruleType;
  const SourceLine({
    super.key,
    required this.sourceName,
    required this.sourceOrg,
    required this.sourceUrl,
    required this.reviewed,
    required this.ruleType,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final binding = ruleType == 'ملزمة دوليًا';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF3EDDD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? (binding ? AppColors.gold : AppColors.navyLight)
                      : (binding ? AppColors.navy : AppColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(ruleType,
                    style: TextStyle(
                        color: isDark && binding
                            ? AppColors.navy
                            : Colors.white,
                        fontSize: 11)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 15, color: AppColors.gold),
              const SizedBox(width: 4),
              Text(trc(context, 'source'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: context.headingColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text(sourceName, style: TextStyle(fontSize: 12.5, color: context.bodyColor)),
          Text(sourceOrg,
              style: TextStyle(fontSize: 12, color: context.mutedColor)),
          if (reviewed.isNotEmpty)
            Text('${trc(context, 'last_review')} $reviewed',
                style: TextStyle(fontSize: 11, color: context.mutedColor)),
          if (sourceUrl.isNotEmpty)
            Text(sourceUrl,
                style: const TextStyle(fontSize: 11, color: AppColors.gold),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;
  final String retryLabel;
  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
    this.onRetry,
    this.retryLabel = '',
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.mutedColor),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.mutedColor)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                  onPressed: onRetry,
                  child: Text(retryLabel.isEmpty
                      ? trc(context, 'retry')
                      : retryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
