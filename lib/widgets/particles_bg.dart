import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ParticlesBackground extends StatefulWidget {
  const ParticlesBackground({super.key});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final List<Particle> particles = [];
  final int particleCount = 15; 

  @override
  void initState() {
    super.initState();
    // Utilisation d'un Ticker pur au lieu d'un AnimationController
    // Cela évite la saccade (reset) toutes les 10 secondes. Le mouvement est infini et fluide.
    _ticker = createTicker((elapsed) {
      setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (particles.isEmpty) {
          for (int i = 0; i < particleCount; i++) {
            particles.add(Particle(
              x: Random().nextDouble() * constraints.maxWidth,
              y: Random().nextDouble() * 160, 
              vx: (Random().nextDouble() - 0.5) * 0.2, 
              vy: (Random().nextDouble() - 0.5) * 0.2,
            ));
          }
        }
        return CustomPaint(
          size: Size(constraints.maxWidth, 160), 
          painter: ParticlePainter(particles: particles),
        );
      },
    );
  }
}

class Particle {
  double x, y, vx, vy;
  Particle({required this.x, required this.y, required this.vx, required this.vy});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()..color = const Color(0xFF00D4FF).withOpacity(0.4);
    
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      p.x += p.vx;
      p.y += p.vy;

      if (p.x < 0 || p.x > size.width) p.vx = -p.vx;
      if (p.y < 0 || p.y > size.height) p.vy = -p.vy;

      canvas.drawCircle(Offset(p.x, p.y), 1.0, particlePaint);

      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final dx = p.x - p2.x;
        final dy = p.y - p2.y;
        final distance = sqrt(dx * dx + dy * dy);

        if (distance < 50) {
          final linePaint = Paint()
            ..color = Colors.white.withOpacity(max(0, 0.2 - distance / 250))
            ..strokeWidth = 0.5;
          canvas.drawLine(Offset(p.x, p.y), Offset(p2.x, p2.y), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
