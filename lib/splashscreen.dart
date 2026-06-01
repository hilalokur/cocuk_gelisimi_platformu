import 'package:flutter/material.dart';
import 'auth_wrapper.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _navigateToAuthWrapper(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthWrapper(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isShort = constraints.maxHeight < 720;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/bg1.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00FFF8F0),
                      Color(0x00FFF8F0),
                      Color(0xDFFFF8F0),
                      Color(0xFFFFF8F0),
                    ],
                    stops: [0.0, 0.42, 0.64, 1.0],
                  ),
                ),
              ),
              const _LeafDecoration(),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight -
                          MediaQuery.paddingOf(context).vertical,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        isShort ? 285 : 390,
                        24,
                        22,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const _TitleBlock(),
                          const SizedBox(height: 10),
                          const _HeartRule(),
                          const SizedBox(height: 14),
                          const _IntroText(),
                          SizedBox(height: isShort ? 26 : 38),
                          const _FeatureRow(),
                          SizedBox(height: isShort ? 24 : 34),
                          _StartButton(
                            onPressed: () => _navigateToAuthWrapper(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Minik Adımlar',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: Color(0xFF4E2F27),
          fontSize: 39,
          fontWeight: FontWeight.w500,
          height: 1.05,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _HeartRule extends StatelessWidget {
  const _HeartRule();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 28, height: 1, color: const Color(0xFFE0CFC3)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.favorite_rounded,
            color: Color(0xFFE0CFC3),
            size: 14,
          ),
        ),
        Container(width: 28, height: 1, color: const Color(0xFFE0CFC3)),
      ],
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Çocuğunuzun gelişimini\nsevgiyle ve güvenle takip edin.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF6A463B),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.32,
        letterSpacing: 0,
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      _FeatureItem(Icons.child_care_rounded, 'Gelişim\nTakibi'),
      _FeatureItem(Icons.vaccines_rounded, 'Aşı\nHatırlatmaları'),
      _FeatureItem(Icons.query_stats_rounded, 'Büyüme\nGrafikleri'),
      _FeatureItem(Icons.extension_rounded, 'Yaşa Uygun\nEtkinlikler'),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[Expanded(child: items[i])],
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF7B5145), size: 27),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF6A463B),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                height: 1.2,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7A4C3D), Color(0xFF4E2E26)],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A3328).withValues(alpha: 0.32),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: const Row(
            children: [
              SizedBox(width: 26),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Başlayalım',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14),
              Icon(Icons.arrow_forward_rounded, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeafDecoration extends StatelessWidget {
  const _LeafDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -22,
            bottom: 70,
            child: Transform.rotate(
              angle: -0.4,
              child: Icon(
                Icons.local_florist_rounded,
                size: 92,
                color: const Color(0xFFD2B8A6).withValues(alpha: 0.38),
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: 82,
            child: Transform.rotate(
              angle: 0.55,
              child: Icon(
                Icons.local_florist_rounded,
                size: 104,
                color: const Color(0xFFD2B8A6).withValues(alpha: 0.38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
