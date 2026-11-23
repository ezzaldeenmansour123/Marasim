import 'dart:async';
import 'package:material_ui/material_ui.dart';

class AppColors {
  static const navy = Color(0xFF0B2239);
  static const navyLight = Color(0xFF14324F);
  static const gold = Color(0xFFC6A15B);
  static const goldLight = Color(0xFFDEBE82);
  static const pearl = Color(0xFFF7F5F0);
  static const stone = Color(0xFF6B7280);
  static const cardBorder = Color(0xFFE3DCCB);
}

class AppTheme {
  static ThemeData light(double fontScale) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.gold,
        surface: AppColors.pearl,
      ),
      scaffoldBackgroundColor: AppColors.pearl,
      fontFamily: 'Amiri',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
            fontSize: 26 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.navy),
        headlineMedium: TextStyle(
            fontSize: 22 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.navy),
        headlineSmall: TextStyle(
            fontSize: 19 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.navy),
        titleLarge: TextStyle(
            fontSize: 18 * fontScale,
            fontWeight: FontWeight.bold,
            color: AppColors.navy),
        titleMedium: TextStyle(
            fontSize: 16 * fontScale,
            fontWeight: FontWeight.w600,
            color: AppColors.navy),
        bodyLarge: TextStyle(fontSize: 16 * fontScale, color: const Color(0xFF1F2937)),
        bodyMedium: TextStyle(fontSize: 14 * fontScale, color: const Color(0xFF1F2937)),
        bodySmall: TextStyle(fontSize: 12 * fontScale, color: AppColors.stone),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEFF1F5),
        selectedColor: AppColors.navy,
        labelStyle: TextStyle(fontSize: 13 * fontScale),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
      ),
    );
    return base;
  }
}

/// Rotating hero images (bundled photos, cross-fade every 5 seconds).
class HeroCarousel extends StatefulWidget {
  final double height;
  const HeroCarousel({super.key, this.height = 190});
  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
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

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _index = (_index + 1) % images.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Image.asset(
                images[_index],
                key: ValueKey(images[_index]),
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => Container(
                  color: AppColors.navy,
                  alignment: Alignment.center,
                  child: Image.asset('assets/logo.png',
                      width: 90, height: 90,
                      errorBuilder: (c, e, st) => const Icon(Icons.public,
                          color: AppColors.gold, size: 48)),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.navy.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 14,
              left: 14,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مراسم — منصة البروتوكول الدولي',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Row(
                    children: List.generate(
                      images.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: i == _index ? 14 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.gold
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          color: AppColors.navy,
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
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
        if (onMore != null)
          TextButton(onPressed: onMore, child: const Text('عرض الكل')),
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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDDD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
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
                  color: ruleType == 'ملزمة دوليًا'
                      ? AppColors.navy
                      : AppColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(ruleType,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 15, color: AppColors.navy),
              const SizedBox(width: 4),
              const Text('المصدر:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(sourceName, style: const TextStyle(fontSize: 12.5)),
          Text(sourceOrg,
              style: const TextStyle(fontSize: 12, color: AppColors.stone)),
          if (reviewed.isNotEmpty)
            Text('آخر مراجعة: $reviewed',
                style: const TextStyle(fontSize: 11, color: AppColors.stone)),
          if (sourceUrl.isNotEmpty)
            Text(sourceUrl,
                style: const TextStyle(fontSize: 11, color: AppColors.navy),
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
  const EmptyState({super.key, required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.stone),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.stone)),
          ],
        ),
      ),
    );
  }
}
