import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LogoConstellation extends StatefulWidget {
  const LogoConstellation({super.key});

  @override
  State<LogoConstellation> createState() => _LogoConstellationState();
}

class _LogoConstellationState extends State<LogoConstellation> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _time = 0.0;
  final List<Vector3> _baseVertices = [];

  @override
  void initState() {
    super.initState();
    // Utilisation d'un Ticker pur pour que le temps avance à l'infini (supprime la saccade toutes les 20s)
    _ticker = createTicker((elapsed) {
      setState(() {
        _time = elapsed.inMilliseconds / 1000.0; // Temps en secondes
      });
    });
    _ticker.start();

    // Generate points on a sphere using Fibonacci lattice
    const int numPoints = 40;
    final phi = pi * (3.0 - sqrt(5.0)); // golden angle
    
    for (int i = 0; i < numPoints; i++) {
      double y = 1 - (i / (numPoints - 1)) * 2; // y goes from 1 to -1
      double radius = sqrt(1 - y * y); // radius at y
      
      double theta = phi * i; // golden angle increment
      
      double x = cos(theta) * radius;
      double z = sin(theta) * radius;
      
      // We will scale this by the actual sphere radius in the painter
      _baseVertices.add(Vector3(x, y, z));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      // Vitesse réduite d'un tiers (0.2 au lieu de 0.3)
      painter: Shield3DPainter(vertices: _baseVertices, time: _time * 0.2),
      size: const Size(300, 300),
    );
  }
}

class Vector3 {
  final double x, y, z;
  Vector3(this.x, this.y, this.z);
}

class ProjectedPoint {
  final Offset offset;
  final double z;
  final Color color;
  ProjectedPoint(this.offset, this.z, this.color);
}

class Shield3DPainter extends CustomPainter {
  final List<Vector3> vertices;
  final double time;

  Shield3DPainter({required this.vertices, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sphereRadius = 70.0; // Encore plus ajusté au logo

    // Rotation angles
    final rotY = time * 1.5;
    final rotX = time * 0.5;
    final rotZ = time * 0.2;

    List<ProjectedPoint> projected = [];

    for (int i = 0; i < vertices.length; i++) {
      final v = vertices[i];
      
      // Rotate around Z
      double x1 = v.x * cos(rotZ) - v.y * sin(rotZ);
      double y1 = v.x * sin(rotZ) + v.y * cos(rotZ);
      double z1 = v.z;

      // Rotate around X
      double x2 = x1;
      double y2 = y1 * cos(rotX) - z1 * sin(rotX);
      double z2 = y1 * sin(rotX) + z1 * cos(rotX);

      // Rotate around Y
      double x3 = x2 * cos(rotY) + z2 * sin(rotY);
      double y3 = y2;
      double z3 = -x2 * sin(rotY) + z2 * cos(rotY);

      // Perspective projection
      double distance = 3.0; // Camera distance
      double zProj = distance / (distance - z3);
      
      double px = cx + x3 * sphereRadius * zProj;
      double py = cy + y3 * sphereRadius * zProj;

      // Determine color based on index to mix orange and blue
      Color color = (i % 3 == 0) ? const Color(0xFFFF8C00) : const Color(0xFF00D4FF);

      projected.add(ProjectedPoint(Offset(px, py), z3, color));
    }

    // Sort by Z for proper rendering (back to front)
    List<int> indices = List.generate(projected.length, (i) => i);
    indices.sort((a, b) => projected[a].z.compareTo(projected[b].z));

    // Draw lines between closest points (wireframe)
    for (int i = 0; i < projected.length; i++) {
      for (int j = i + 1; j < projected.length; j++) {
        final p1 = projected[i];
        final p2 = projected[j];
        
        // Don't draw lines if both are way in the back
        if (p1.z < -0.5 && p2.z < -0.5) continue;

        final dx = p1.offset.dx - p2.offset.dx;
        final dy = p1.offset.dy - p2.offset.dy;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < 65) {
          // Fade out points in the back
          double avgZ = (p1.z + p2.z) / 2;
          double alphaZ = ((avgZ + 1) / 2).clamp(0.1, 1.0); // Z is between -1 and 1
          
          double alphaDist = max(0.0, 0.5 - dist / 130);
          double finalAlpha = alphaZ * alphaDist * 0.8;

          final grad = ui.Gradient.linear(
            p1.offset, p2.offset,
            [p1.color.withValues(alpha: finalAlpha), p2.color.withValues(alpha: finalAlpha)]
          );
          
          final linePaint = Paint()
            ..shader = grad
            ..strokeWidth = 1.0;
          canvas.drawLine(p1.offset, p2.offset, linePaint);
        }
      }
    }

    // Draw vertices (glowing nodes)
    for (int idx in indices) {
      final p = projected[idx];
      double alpha = ((p.z + 1) / 2).clamp(0.2, 1.0);
      double size = 1.5 + ((p.z + 1) / 2) * 1.5;

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      
      canvas.drawCircle(p.offset, size * 1.5, paint);
      
      canvas.drawCircle(p.offset, size * 0.5, Paint()..color = Colors.white.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(covariant Shield3DPainter oldDelegate) => true;
}
