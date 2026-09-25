import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/app_state.dart';
import '../widgets/floating_embers.dart';
import '../widgets/logo_constellation.dart';
import '../widgets/custom_cards.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey? bellKey;
  final GlobalKey? liveKey;
  final GlobalKey? tournamentKey;
  final GlobalKey? logoKey;

  const HomeScreen({super.key, this.bellKey, this.liveKey, this.tournamentKey, this.logoKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _logoTaps = 0;
  bool _hasShownUpdateDialog = false;
  AppState? _appStateRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _appStateRef = Provider.of<AppState>(context, listen: false);
      _appStateRef!.addListener(_checkUpdate);
      _checkUpdate();
    });
  }

  @override
  void dispose() {
    _appStateRef?.removeListener(_checkUpdate);
    super.dispose();
  }

  void _checkUpdate() {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.isUpdateAvailable && !_hasShownUpdateDialog) {
      _hasShownUpdateDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Row(
            children: [
              const Icon(Icons.system_update_alt, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text("Mise à jour !", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(appState.updateMessage, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => launchUrl(Uri.parse(appState.updateUrl), mode: LaunchMode.externalApplication),
              child: Text("TÉLÉCHARGER", style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: const Color(0xFF00D4FF), fontSize: 16)),
            )
          ],
        ),
      );
    }
  }

  String _formatTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 1) return 'Il y a ${difference.inDays} jours';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inHours > 0) return 'Il y a ${difference.inHours}h';
    if (difference.inMinutes > 0) return 'Il y a ${difference.inMinutes}m';
    return 'À l\'instant';
  }

  void _showNotificationSettings(BuildContext context) {
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
            child: Consumer<AppState>(
              builder: (context, appState, child) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                      const SizedBox(height: 20),
                      Text('NOTIFICATIONS', style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Choisis les alertes que tu souhaites recevoir sur ton téléphone.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 24),
                      
                      _buildSwitchTile('📢 Nouvelles Annonces', appState.notifyAnnouncements, (val) => appState.toggleNotifyAnnouncements(val)),
                      const SizedBox(height: 12),
                      _buildSwitchTile('🔴 Annonce Live', appState.notifyLiveAnnounced, (val) => appState.toggleNotifyLiveAnnounced(val)),
                      const SizedBox(height: 12),
                      _buildSwitchTile('🔴 Lancement du Live', appState.notifyLiveStart, (val) => appState.toggleNotifyLiveStart(val)),
                      const SizedBox(height: 12),
                      _buildSwitchTile('🏆 Annonce Tournoi', appState.notifyTournamentAnnounced, (val) => appState.toggleNotifyTournamentAnnounced(val)),
                      const SizedBox(height: 12),
                      _buildSwitchTile('🏆 Début du Tournoi', appState.notifyTournamentStart, (val) => appState.toggleNotifyTournamentStart(val)),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00D4FF),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1115),
          ),
        ),
        
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.8, -0.6),
              radius: 0.8,
              colors: [
                const Color(0xFF00D4FF).withValues(alpha: 0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
        
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.8, 0.6),
              radius: 0.8,
              colors: [
                const Color(0xFFFF8C00).withValues(alpha: 0.15),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),

        const Positioned.fill(
          child: FloatingEmbers(),
        ),

        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.person_outline, color: appState.currentUser != null ? Colors.green : Colors.grey),
                          onPressed: () {
                            if (appState.currentUser == null) {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                            } else {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: Text("Mon Compte", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(appState.currentUser!.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await FirebaseAuth.instance.sendPasswordResetEmail(email: appState.currentUser!.email!);
                                              if (!ctx.mounted) return;
                                              Navigator.pop(ctx);
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email de réinitialisation envoyé !')));
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black),
                                          child: Text("CHANGER MDP", style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            appState.logout();
                                            Navigator.pop(ctx);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                          child: Text("DÉCONNECTER", style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          key: widget.bellKey,
                          icon: const Icon(Icons.notifications_active_outlined, color: Colors.white70),
                          onPressed: () => _showNotificationSettings(context),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    SizedBox(
                      key: widget.logoKey,
                      width: 160, height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Positioned.fill(
                            child: LogoConstellation(),
                          ),
                          GestureDetector(
                            onTap: () {
                              _logoTaps++;
                              if (_logoTaps >= 5) {
                                appState.unlockAdmin();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Mode Administrateur débloqué !', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                                    backgroundColor: const Color(0xFF00D4FF),
                                  ),
                                );
                                _logoTaps = 0;
                              }
                            },
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 145, height: 145,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_esports, size: 80, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ASTT E-SPORT',
                      style: GoogleFonts.chakraPetch(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [const Shadow(color: Color(0xFF00D4FF), blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  children: [
                    if (appState.displayLiveScheduled || appState.displayTournamentScheduled)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (appState.displayLiveScheduled)
                            ScheduledEventCard(
                              key: const ValueKey('live_scheduled'),
                              type: "LIVE",
                              title: appState.liveTitle,
                              description: appState.liveDesc,
                              scheduledDate: appState.liveScheduledDate!,
                              color: const Color(0xFF00D4FF),
                              icon: Icons.videocam,
                              onFinished: () => Provider.of<AppState>(context, listen: false).refreshUI(),
                            ),
                          if (appState.displayLiveScheduled && appState.displayTournamentScheduled)
                            const SizedBox(width: 16),
                          if (appState.displayTournamentScheduled)
                            ScheduledEventCard(
                              key: const ValueKey('tournoi_scheduled'),
                              type: "TOURNOI",
                              title: appState.tournamentTitle,
                              description: appState.tournamentDesc,
                              scheduledDate: appState.tournamentStartDate!,
                              color: const Color(0xFFFF8C00),
                              icon: Icons.emoji_events,
                              onFinished: () => Provider.of<AppState>(context, listen: false).refreshUI(),
                            ),
                        ],
                      )
                    else
                      Center(
                        child: Column(
                          children: [
                            Text("BIENVENUE SUR L'APP", style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 4),
                            const Text("Toute l'actualité de la section e-sport.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    if (appState.isUpdateAvailable)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.redAccent),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                                  const SizedBox(width: 8),
                                  Text("MISE À JOUR DISPONIBLE", style: GoogleFonts.chakraPetch(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(appState.updateMessage, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => launchUrl(Uri.parse(appState.updateUrl), mode: LaunchMode.externalApplication),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                  child: Text("TÉLÉCHARGER LA MISE À JOUR", style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (appState.displayLive) 
                      Container(
                        key: widget.liveKey, 
                        child: LiveCard(twitchUrl: appState.twitchUrl, title: appState.liveTitle, desc: appState.liveDesc)
                      ),
                    if (appState.displayLive) 
                      const SizedBox(height: 16),
                    
                    if (appState.displayTournament) 
                      Container(
                        key: widget.tournamentKey, 
                        child: TournamentCard(
                          linkUrl: appState.tournamentUrl, 
                          title: appState.tournamentTitle, 
                          desc: appState.tournamentDesc,
                          registrationEndDate: appState.tournamentRegistrationEndDate,
                          onFinished: () => Provider.of<AppState>(context, listen: false).refreshUI(),
                        )
                      ),
                    if (appState.displayTournament) 
                      const SizedBox(height: 16),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(child: Text('Erreur de chargement des annonces', style: TextStyle(color: Colors.red)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF00D4FF)));
                        }
                        
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('Aucune annonce pour le moment', style: TextStyle(color: Colors.grey)));
                        }
                        
                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final title = data['title'] ?? 'Sans titre';
                            final description = data['description'] ?? '';
                            final linkText = data['linkText'];
                            final linkUrl = data['linkUrl'] ?? data['actionUrl'];
                            final timestamp = data['createdAt'] as Timestamp?;
                            final timeAgo = timestamp != null ? _formatTimeAgo(timestamp.toDate()) : 'Récemment';
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: AnnouncementCard(
                                title: title,
                                description: description,
                                timeAgo: timeAgo,
                                linkText: linkText,
                                linkUrl: linkUrl,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const double spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
