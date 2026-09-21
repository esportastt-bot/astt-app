import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

// --- Base Glass Card ---
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double opacity;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor = Colors.white10,
    this.opacity = 1.0,
    this.boxShadow,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: boxShadow,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// --- Live Card avec effet Pulsation ---
class LiveCard extends StatefulWidget {
  final String twitchUrl;
  final String title;
  final String desc;

  const LiveCard({super.key, required this.twitchUrl, required this.title, required this.desc});

  @override
  State<LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends State<LiveCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0, end: 10).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFullEventInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFA0F1115),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF00D4FF).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('EN DIRECT', style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF00D4FF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.title, style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(
                    widget.desc,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return InkWell(
          onTap: () => _showFullEventInfo(context),
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            borderColor: const Color(0xFF00D4FF).withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(_glowAnimation.value / 20),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 2,
              )
            ],
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -16,
                  right: -16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), topRight: Radius.circular(16)),
                    ),
                    child: Text('EN DIRECT', style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: const Color(0xFF9146FF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.videocam, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(
                                widget.desc, 
                                style: const TextStyle(fontSize: 12, color: Colors.white70),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String url = widget.twitchUrl;
                          if (!url.startsWith('http://') && !url.startsWith('https://')) {
                            url = 'https://$url';
                          }
                          try {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Erreur lien: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4FF),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('REJOINDRE LE STREAM', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Widget Compte à rebours réutilisable ---
class CountdownWidget extends StatefulWidget {
  final DateTime targetDate;
  final TextStyle? textStyle;
  final String finishedText;
  final VoidCallback? onFinished;
  
  const CountdownWidget({
    super.key, 
    required this.targetDate, 
    this.textStyle, 
    this.finishedText = "Terminé",
    this.onFinished,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void didUpdateWidget(CountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetDate != oldWidget.targetDate) {
      _updateTime();
      if (_timer == null || !_timer!.isActive) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _updateTime();
        });
      }
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    if (widget.targetDate.isAfter(now)) {
      if (mounted) setState(() => _timeLeft = widget.targetDate.difference(now));
    } else {
      bool justFinished = _timeLeft != Duration.zero;
      if (mounted) setState(() => _timeLeft = Duration.zero);
      _timer?.cancel();
      if (justFinished && widget.onFinished != null) {
        // Exécuter à la fin du frame pour éviter les conflits de build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onFinished!();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft == Duration.zero) {
      return Text(widget.finishedText, style: widget.textStyle ?? const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold));
    }
    
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    String timeString = "";
    if (days > 0) timeString += "${days}j ";
    timeString += "${hours.toString().padLeft(2, '0')}h ";
    timeString += "${minutes.toString().padLeft(2, '0')}m ";
    timeString += "${seconds.toString().padLeft(2, '0')}s";

    return Text(timeString, style: widget.textStyle ?? GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white));
  }
}


// --- Tournament Card (Inscriptions) ---
class TournamentCard extends StatelessWidget {
  final String? linkUrl;
  final String title;
  final String desc;
  final DateTime? registrationEndDate;
  final VoidCallback? onFinished;
  
  const TournamentCard({super.key, this.linkUrl, required this.title, required this.desc, this.registrationEndDate, this.onFinished});

  void _showFullEventInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFA0F1115),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFFF8C00).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text('TOURNOI', style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFF8C00))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        String url = linkUrl != null && linkUrl!.isNotEmpty ? linkUrl! : 'https://helloasso.com';
                        if (!url.startsWith('http://') && !url.startsWith('https://')) {
                          url = 'https://$url';
                        }
                        try {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Erreur lien: $e');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFFF8C00)),
                        backgroundColor: const Color(0xFFFF8C00).withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('S\'INSCRIRE', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showFullEventInfo(context),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        borderColor: const Color(0xFFFF8C00).withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFF8C00).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text('INSCRIPTIONS TOURNOI', style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFFF8C00))),
                ),
                if (registrationEndDate != null)
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      CountdownWidget(
                        targetDate: registrationEndDate!, 
                        textStyle: const TextStyle(fontSize: 12, color: Colors.white70),
                        onFinished: onFinished,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              desc, 
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text("Cliquez pour plus d'infos et s'inscrire", style: TextStyle(fontSize: 10, color: const Color(0xFFFF8C00).withOpacity(0.8), fontStyle: FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Scheduled Event Card (Petite tuile sous le logo) ---
class ScheduledEventCard extends StatelessWidget {
  final String type; // "LIVE" ou "TOURNOI"
  final String title;
  final String description;
  final DateTime scheduledDate;
  final Color color;
  final IconData icon;
  final VoidCallback? onFinished;

  const ScheduledEventCard({
    super.key, 
    required this.type, 
    required this.title, 
    required this.description,
    required this.scheduledDate, 
    required this.color,
    required this.icon,
    this.onFinished,
  });

  void _addToCalendar() {
    final Event event = Event(
      title: title,
      description: "Événement $type de l'association",
      location: type == "LIVE" ? "Twitch" : "Lieu à confirmer",
      startDate: scheduledDate,
      endDate: scheduledDate.add(const Duration(hours: 2)),
    );
    Add2Calendar.addEvent2Cal(event);
  }

  void _showFullEventInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFA0F1115),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(type, style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _addToCalendar();
                      },
                      icon: Icon(Icons.calendar_month, color: color),
                      label: Text('AJOUTER AU CALENDRIER', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: color)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withOpacity(0.1),
                        side: BorderSide(color: color.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _showFullEventInfo(context),
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          padding: const EdgeInsets.all(10),
          borderColor: color.withOpacity(0.3),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(type, style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title, 
                style: GoogleFonts.chakraPetch(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              CountdownWidget(
                targetDate: scheduledDate, 
                textStyle: GoogleFonts.chakraPetch(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                finishedText: type == "TOURNOI" ? "C'EST PARTI !" : "EN DIRECT !",
                onFinished: onFinished,
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _addToCalendar,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text('Rappel', style: TextStyle(fontSize: 10, color: color)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Announcement Card ---
class AnnouncementCard extends StatelessWidget {
  final String title;
  final String description;
  final String timeAgo;
  final double opacity;
  final String? linkText;
  final String? linkUrl;

  const AnnouncementCard({
    super.key, 
    required this.title, 
    required this.description, 
    required this.timeAgo, 
    this.opacity = 1.0,
    this.linkText,
    this.linkUrl,
  });

  void _showFullAnnouncement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFA0F1115),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                        child: Text('ANNONCE', style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  if (linkUrl != null && linkUrl!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          String url = linkUrl!;
                          if (!url.startsWith('http://') && !url.startsWith('https://')) {
                            url = 'https://$url';
                          }
                          try {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } catch (e) {
                            debugPrint('Erreur lien: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          (linkText != null && linkText!.isNotEmpty) ? linkText! : 'EN SAVOIR PLUS', 
                          style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showFullAnnouncement(context),
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        opacity: opacity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                  child: Text('ANNONCE', style: GoogleFonts.chakraPetch(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              description, 
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (linkUrl != null && linkUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 14, color: Color(0xFF00D4FF)),
                    const SizedBox(width: 4),
                    Text(
                      (linkText != null && linkText!.isNotEmpty) ? linkText! : 'Lien disponible', 
                      style: const TextStyle(fontSize: 12, color: Color(0xFF00D4FF), fontWeight: FontWeight.bold)
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
