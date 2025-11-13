import 'dart:math';
import 'package:flutter/material.dart';
import '../game.dart';
import 'package:url_launcher/url_launcher.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _photosKey = GlobalKey();
  final GlobalKey _scheduleKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();
  final GlobalKey _pricesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // slower pulse to reduce repaints
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeYellow = const Color(0xFFFFD300);
    final themeDark = const Color(0xFF0A0A0A);
    final themeDarker = const Color(0xFF050505);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool showGrid = screenWidth <= 1600;

    return Scaffold(
      backgroundColor: themeDark,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF000000),
                  Color(0xFF0B0B0B),
                  Color(0xFF111111),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Neon grid / lines
          if (showGrid)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _NeonGridPainter()),
              ),
            ),
          // Scrollable content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top navigation (business-like)
                      _TopNavBar(
                        onLogoTap: () => _scrollToTop(),
                        onPhotosTap: () => _scrollToSection(_photosKey),
                        onPricesTap: () => _scrollToSection(_pricesKey),
                        onScheduleTap: () => _scrollToSection(_scheduleKey),
                        onContactTap: () => _scrollToSection(_contactKey),
                        color: themeYellow,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Header
                                AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, _) {
                                    final glow = 0.5 + 0.5 * _pulse.value;
                                    return ShaderMask(
                                      shaderCallback:
                                          (rect) => LinearGradient(
                                            colors: [
                                              themeYellow.withOpacity(
                                                0.6 * glow,
                                              ),
                                              themeYellow,
                                            ],
                                          ).createShader(rect),
                                      child: const Text(
                                        'CENTRU RECREAȚIONAL',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Din Țara Lăpușului, cu energie pentru tine!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 16,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                // Hero CTAr
                                _NeonButton(
                                  label:
                                      'Screenshot dacă ai adunat 2025 puncte si câștigi o partidă gratuită!',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const FlappyBallGame(),
                                      ),
                                    );
                                  },
                                  color: themeYellow,
                                  background: themeDarker,
                                ),
                                const SizedBox(height: 36),
                                // Photo carousel + Schedule
                                Flex(
                                  direction:
                                      isWide ? Axis.horizontal : Axis.vertical,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      isWide
                                          ? CrossAxisAlignment.start
                                          : CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        key: _photosKey,
                                        child: _PhotosCarousel(),
                                      ),
                                    ),
                                    SizedBox(
                                      width: isWide ? 24 : 0,
                                      height: isWide ? 0 : 24,
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        key: _scheduleKey,
                                        child: _ScheduleCard(
                                          color: themeYellow,
                                          background: themeDarker,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                // News section
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: themeYellow.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: themeYellow,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeYellow.withOpacity(0.4),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: _NewsSection(color: themeYellow),
                                ),
                                const SizedBox(height: 28),
                                // Prices section
                                Container(
                                  key: _pricesKey,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: themeDarker,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: themeYellow.withOpacity(0.8),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeYellow.withOpacity(0.25),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: _PricingCard(accent: themeYellow),
                                ),
                                const SizedBox(height: 28),
                                // Secondary actions
                                Row(
                                  children: [
                                    Expanded(
                                      child: _NeonButton(
                                        label: 'Events',
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      const _UnderDevelopmentPage(),
                                            ),
                                          );
                                        },
                                        color: themeYellow.withOpacity(0.9),
                                        background: themeDarker,
                                        compact: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _NeonButton(
                                        label: 'Contact',
                                        onPressed:
                                            () => _showContactSheet(context),
                                        color: themeYellow.withOpacity(0.9),
                                        background: themeDarker,
                                        compact: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                // Contact panel (business details)
                                Container(
                                  key: _contactKey,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: themeDarker,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: themeYellow.withOpacity(0.8),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Contact & Location',
                                        style: TextStyle(
                                          color: themeYellow,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 22,
                                        runSpacing: 12,
                                        children: [
                                          _ContactItem(
                                            icon: Icons.phone,
                                            label: '+40 760 856 851',
                                            onTap:
                                                () => _openUrl(
                                                  'tel:+40760856851',
                                                ),
                                          ),
                                          _ContactItem(
                                            icon: Icons.email,
                                            label:
                                                'c.recreational@primariatargulapus.info',
                                            onTap:
                                                () => _openUrl(
                                                  'mailto:c.recreational@primariatargulapus.info',
                                                ),
                                          ),
                                          _ContactItem(
                                            icon: Icons.location_on,
                                            label: 'str.Doinei nr.15B',
                                            onTap:
                                                () => _openUrl(
                                                  'https://maps.google.com/?q=Bd.%20Neon%20100%2C%20Bucuresti',
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Floating start game button
          Positioned(
            right: 24,
            bottom: 24,
            child: _FloatingStartButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FlappyBallGame()),
                );
              },
              color: themeYellow,
            ),
          ),
          // Round logo button for website link
          Positioned(
            right: 24,
            bottom: 100,
            child: _RoundLogoButton(
              onPressed: () => _openUrl('https://primariatargulapus.ro/ro'),
              color: themeYellow,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color background;
  final bool compact;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    required this.color,
    required this.background,
    this.compact = false,
  });

  @override
  State<_NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<_NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220), // snappier, shorter glow
  );
  late final Animation<double> _glow = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _glow,
          builder: (context, _) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 22,
                vertical: widget.compact ? 12 : 16,
              ),
              decoration: BoxDecoration(
                color: widget.background,
                borderRadius: radius,
                border: Border.all(
                  color: widget.color.withOpacity(0.8),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.35 * _glow.value),
                    blurRadius:
                        16 * _glow.value, // reduced blur for performance
                    spreadRadius: 0.6 * _glow.value,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.label.toUpperCase(),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: widget.compact ? 14 : 18,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NeonGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = const Color(0xFFFFD300).withOpacity(0.12)
          ..strokeWidth = 1.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    // Diagonal neon lines
    const spacing = 48.0; // fewer lines to draw
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      final p1 = Offset(x, 0);
      final p2 = Offset(x + size.height, size.height);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (double x = size.width + size.height; x > -size.height; x -= spacing) {
      final p1 = Offset(x, 0);
      final p2 = Offset(x - size.height, size.height);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // Random neon dots
    final rnd = Random(7);
    final dotPaint = Paint()..color = const Color(0xFFFFD300).withOpacity(0.16);
    for (int i = 0; i < 50; i++) {
      // fewer dots
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.5 + rnd.nextDouble() * 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension _ScrollHelpers on _MainMenuPageState {
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.1,
    );
  }
}

class _TopNavBar extends StatelessWidget {
  final VoidCallback onLogoTap;
  final VoidCallback onPhotosTap;
  final VoidCallback onPricesTap;
  final VoidCallback onScheduleTap;
  final VoidCallback onContactTap;
  final Color color;

  const _TopNavBar({
    required this.onLogoTap,
    required this.onPhotosTap,
    required this.onPricesTap,
    required this.onScheduleTap,
    required this.onContactTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.7),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Row(
          children: [
            GestureDetector(
              onTap: onLogoTap,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/neon_yllow_logo.png',
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Centru Recreațional',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            _NavButton(label: 'Galrie', onTap: onPhotosTap, color: color),
            const SizedBox(width: 16),
            _NavButton(label: 'Tarife', onTap: onPricesTap, color: color),
            const SizedBox(width: 16),
            _NavButton(label: 'Orar', onTap: onScheduleTap, color: color),
            const SizedBox(width: 16),
            _NavButton(label: 'Contact', onTap: onContactTap, color: color),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _NavButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

void _showContactSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0A0A0A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.contact_phone, color: Color(0xFFFFD300)),
                SizedBox(width: 8),
                Text(
                  'Contact us',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _ContactItem(
                  icon: Icons.phone,
                  label: '+40 760 856 851',
                  onTap: () => _openUrl('tel:+40 760 856 851'),
                ),
                _ContactItem(
                  icon: Icons.email,
                  label: 'c.recreational@primariatargulapus.info',
                  onTap:
                      () => _openUrl(
                        'mailto:c.recreational@primariatargulapus.info',
                      ),
                ),
                _ContactItem(
                  icon: Icons.location_on,
                  label: 'str.Doinei nr.15B',
                  onTap:
                      () => _openUrl(
                        'https://maps.google.com/?q=Bd.%20Neon%20100%2C%20Bucuresti',
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ContactItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFD300), size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // fallback to in-app web view
    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
}

class _PhotosCarousel extends StatefulWidget {
  @override
  State<_PhotosCarousel> createState() => _PhotosCarouselState();
}

class _PhotosCarouselState extends State<_PhotosCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.45,
    initialPage: 1,
  );

  final List<String> _images = const [
    'assets/images/cr_game.png',
    'assets/images/Bowling_area.png',
    'assets/images/loc_joaca.png',
    'assets/images/spa.png',
    'assets/images/sport.png',

    'assets/images/bowling_ball.png',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache images for smoother first render
    for (final path in _images) {
      precacheImage(AssetImage(path), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 420,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _images.length,
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double scale = 1.0;
              if (_pageController.position.haveDimensions) {
                final page = _pageController.page ?? 0.0;
                scale = (1 - ((page - i).abs() * 0.08)).clamp(0.9, 1.0);
              }
              return Align(
                alignment: Alignment.center,
                child: Transform.scale(
                  scale: scale,
                  child: _NeonCardImage(path: _images[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NeonCardImage extends StatelessWidget {
  final String path;
  const _NeonCardImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Downscale very large images when caching to reduce memory/bandwidth
    final targetCacheWidth = screenW.clamp(600, 1400).toInt();
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFFFD300).withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD300).withOpacity(0.25),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            cacheWidth: targetCacheWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, _, __) {
              return Container(
                color: const Color(0xFF0A0A0A),
                alignment: Alignment.center,
                child: const Text(
                  'Add images in assets/images/',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final Color color;
  final Color background;
  const _ScheduleCard({required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    final entriesBowling = const [
      ['Mon-Fri', '14:00 - 22:00'],
      ['Sat', '14:00 - 22:00'],
      ['Sun', '14:00 - 22:00'],
    ];
    final entriesFitness = const [
      ['Mon-Fri', '06:00 - 22:00'],
      ['Sat', '14:00 - 22:00'],
      ['Sun', '14:00 - 22:00'],
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orar Bowling',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in entriesBowling)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row[0],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(row[1], style: TextStyle(color: color, fontSize: 16)),
                ],
              ),
            ),
          const SizedBox(height: 14),
          // Fitness schedule section
          Text(
            'Orar Fitness',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          for (final row in entriesFitness)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    row[0],
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(row[1], style: TextStyle(color: color, fontSize: 16)),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Color accent;
  const _PricingCard({required this.accent});

  Widget _row(String label, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            price,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tarife',
          style: TextStyle(
            color: accent,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        // Bowling
        Text(
          'Bowling între 14:00-17:00',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        _row('Partidă Standard', '10 RON/Partidă'),
        _row('Închiriere pistă', '80 RON/H'),
        const SizedBox(height: 12),
        Text(
          'Bowling între 17:00-22:00',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        _row('Partidă Standard', '15 RON/Partidă'),
        _row('Închiriere pistă', '100 RON/H'),
        const SizedBox(height: 12),
        // Spa
        Text(
          'Spa',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        _row('Intrare Standard', '15 RON/15 min'),

        const SizedBox(height: 12),
        // Subscriptions
        Text(
          'Abonamente',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        _row('Abonament Standard', '120 RON/Luna'),
        _row('Abonament Elev', '100 RON/Luna'),
        _row('Abonament Pensionar', '100 RON/Luna'),
        _row('Abonament Standard + Saună', '150 RON/Luna'),
        const SizedBox(height: 12),
        // Fitness classes
        Text(
          'Sala Fitness',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        _row('Intrare individuala', '20 RON/H'),
        const SizedBox(height: 12),
        Text(
          'Acces General',
          style: TextStyle(color: accent, fontWeight: FontWeight.w700),
        ),
        _row('Intrare individuala', '20 RON/H'),
        const SizedBox(height: 12),

        // Group gymnastics
      ],
    );
  }
}

class _FloatingStartButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  const _FloatingStartButton({required this.onPressed, required this.color});

  @override
  State<_FloatingStartButton> createState() => _FloatingStartButtonState();
}

class _FloatingStartButtonState extends State<_FloatingStartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final glow = (sin(_ctrl.value * 2 * pi) + 1) / 2; // 0..1
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.35 + glow * 0.35),
                  blurRadius: 24 + glow * 20,
                  spreadRadius: 1 + glow * 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_esports, color: widget.color),
                const SizedBox(width: 10),
                Text(
                  'Start Game',
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoundLogoButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;
  const _RoundLogoButton({required this.onPressed, required this.color});

  @override
  State<_RoundLogoButton> createState() => _RoundLogoButtonState();
}

class _RoundLogoButtonState extends State<_RoundLogoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final glow = (sin(_ctrl.value * 2 * pi) + 1) / 2; // 0..1
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3 + glow * 0.3),
                  blurRadius: 16 + glow * 12,
                  spreadRadius: 0.5 + glow * 1.5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/sigla_insta.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF0A0A0A),
                    child: Icon(Icons.public, color: widget.color, size: 28),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NewsSection extends StatefulWidget {
  final Color color;
  const _NewsSection({required this.color});

  @override
  State<_NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<_NewsSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample news data - replace with real data
  final List<Map<String, String>> _allNews = [];

  List<Map<String, String>> get _filteredNews {
    if (_searchQuery.isEmpty) return _allNews;
    final query = _searchQuery.toLowerCase();
    return _allNews.where((news) {
      return news['title']!.toLowerCase().contains(query) ||
          news['content']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Știri & Anunțuri',
          style: TextStyle(
            color: widget.color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withOpacity(0.6), width: 2),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Caută știri...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search, color: widget.color),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: widget.color),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // News list
        _filteredNews.isEmpty
            ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'În curand vom avea știri!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ),
            )
            : Column(
              children:
                  _filteredNews.map((news) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.color.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  news['title']!,
                                  style: TextStyle(
                                    color: widget.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Text(
                                news['date']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news['content']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
      ],
    );
  }
}

class _UnderDevelopmentPage extends StatefulWidget {
  const _UnderDevelopmentPage();

  @override
  State<_UnderDevelopmentPage> createState() => _UnderDevelopmentPageState();
}

class _UnderDevelopmentPageState extends State<_UnderDevelopmentPage>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeYellow = const Color(0xFFFFD300);
    final themeDark = const Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeYellow),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinning construction icon
            AnimatedBuilder(
              animation: _rotateAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Icon(
                    Icons.build_circle,
                    size: 120,
                    color: themeYellow,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Bouncing "Under Development" text
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: Text(
                    'În Dezvoltare',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: themeYellow,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: themeYellow.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Pulsing subtitle
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: Text(
                    'Lucrăm la ceva minunat!',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
            // Fun animated dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final adjustedValue =
                        ((_pulseController.value + delay) % 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16 + adjustedValue * 8,
                      height: 16 + adjustedValue * 8,
                      decoration: BoxDecoration(
                        color: themeYellow.withOpacity(0.8),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: themeYellow.withOpacity(0.5),
                            blurRadius: 10 + adjustedValue * 10,
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 40),
            // Back button
            _NeonButton(
              label: 'Înapoi',
              onPressed: () => Navigator.of(context).pop(),
              color: themeYellow,
              background: themeDark,
            ),
          ],
        ),
      ),
    );
  }
}
