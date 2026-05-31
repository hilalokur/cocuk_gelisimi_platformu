import 'package:flutter/material.dart';

class Petal {
  double x, y, size, velocity, drift, rotation, spin;
  Petal({
    required this.x,
    required this.y,
    required this.size,
    required this.velocity,
    required this.drift,
    required this.rotation,
    required this.spin,
  });
}

class PetalPainter extends CustomPainter {
  final List<Petal> petals;
  PetalPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < petals.length; i++) {
      final petal = petals[i];
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.6);

      canvas.save();
      canvas.translate(petal.x * size.width, petal.y * size.height);
      canvas.rotate(petal.rotation);

      final Path path = Path();
      path.moveTo(0, petal.size);
      path.cubicTo(
        -petal.size * 1.2,
        petal.size * 0.4,
        -petal.size * 1.5,
        -petal.size * 0.5,
        0,
        -petal.size * 1.2,
      );
      path.cubicTo(
        petal.size * 1.5,
        -petal.size * 0.5,
        petal.size * 1.2,
        petal.size * 0.4,
        0,
        petal.size,
      );
      path.close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
