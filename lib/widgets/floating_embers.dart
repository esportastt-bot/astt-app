import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FloatingEmbers extends StatefulWidget {
  const FloatingEmbers({super.key});

  @override
  State<FloatingEmbers> createState() => _FloatingEmbersState();
}

class Ember {
  double x, y, speedY, speedX, size, maxOpacity;
  bool isOrange;

  Ember({
    required this.x,
    required this.y,
    required this.speedY,
    required this.speedX,
    required this.size,
    required this.maxOpacity,
    required this.isOrange,
  });
}

class _FloatingEmbersState extends State<FloatingEmbers> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<Ember> _embers = [];
  final int _count = 35; // Nombre de points (discret)
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initEmbers(Size size) {
    if (_embers.isEmpty) {
      for (int i = 0; i < _count; i++) {
        _embers.add(_spawnEmber(size, randomY: true));
      }
    }
  }

  Ember _spawnEmber(Size size, {bool randomY = false}) {
    return Ember(
      x: _rand.nextDouble() * size.width,
      y: randomY ? _rand.nextDouble() * size.height : size.height + 10,
      speedY: 0.2 + _rand.nextDouble() * 0.6, // Vitesse de remontée lente
      speedX: (_rand.nextDouble() - 0.5) * 0.3, // Léger mouvement latéral
      size: 0.8 + _rand.nextDouble() * 1.5, // Très petits points
      maxOpacity: 0.15 + _rand.nextDouble() * 0.3, // Opacité faible (très discret)
      isOrange: _rand.nextBool(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initEmbers(size);
        return CustomPaint(
          size: size,
          painter: EmbersPainter(embers: _embers, onRespawn: (ember) {
            final newEmber = _spawnEmber(size);
            ember.x = newEmber.x;
            ember.y = newEmber.y;
            ember.speedY = newEmber.speedY;
            ember.speedX = newEmber.speedX;
            ember.size = newEmber.size;
            ember.maxOpacity = newEmber.maxOpacity;
            ember.isOrange = newEmber.isOrange;
          }),
        );
      },
    );
  }
}

class EmbersPainter extends CustomPainter {
  final List<Ember> embers;
  final Function(Ember) onRespawn;

  EmbersPainter({required this.embers, required this.onRespawn});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // Le point de disparition complète (10% depuis le haut de l'écran, donc plus haut)
    final double fadeThreshold = size.height * 0.1; 

    for (var ember in embers) {
      ember.y -= ember.speedY; // Remonte
      ember.x += ember.speedX; // Dérive latérale

      if (ember.y < fadeThreshold) {
        onRespawn(ember); // Le point a disparu, on le recrée en bas
        continue;
      }

      // Calcul de l'opacité (100% en bas, fond vers 0% en montant)
      double progress = (ember.y - fadeThreshold) / (size.height - fadeThreshold);
      progress = progress.clamp(0.0, 1.0);
      
      // On utilise une courbe pour que ça fonde doucement
      double currentOpacity = ember.maxOpacity * Curves.easeOut.transform(progress);

      paint.color = ember.isOrange 
          ? const Color(0xFFFF8C00).withOpacity(currentOpacity)
          : const Color(0xFF00D4FF).withOpacity(currentOpacity);
      
      canvas.drawCircle(Offset(ember.x, ember.y), ember.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
