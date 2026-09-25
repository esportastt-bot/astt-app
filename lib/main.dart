import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'firebase_options.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/tournament_screen.dart'; // Nouvel import
import 'services/notification_service.dart'; // Nouvel import
import 'screens/codes_screen.dart';

import 'screens/splash_screen.dart'; // Nouvel import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialisation des notifications Push
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const AsttEsportApp(),
    ),
  );
}

class AsttEsportApp extends StatelessWidget {
  const AsttEsportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASTT E-Sport',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        textTheme: GoogleFonts.montserratTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// LAYOUT PRINCIPAL (Barre de navigation Glassmorphism)
// -----------------------------------------------------------------------------
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  
  // Clés pour le tutoriel
  final GlobalKey _bellKey = GlobalKey();
  final GlobalKey _homeTabKey = GlobalKey();
  final GlobalKey _socialTabKey = GlobalKey();
  final GlobalKey _tournamentTabKey = GlobalKey();
  final GlobalKey _liveKey = GlobalKey();
  final GlobalKey _tournamentKey = GlobalKey();
  final GlobalKey _logoKey = GlobalKey(); // Nouvelle clé pour le message de bienvenue
  
  late TutorialCoachMark tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;
    
    if (!hasSeenTutorial) {
      Future.delayed(const Duration(seconds: 1), () {
        _showTutorial();
      });
      await prefs.setBool('has_seen_tutorial', true);
    }
  }

  void _showTutorial() {
    _showTutorialPart1();
  }

  void _showTutorialPart1() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setTutorialState(true, false); // Affiche Live uniquement
    
    Future.delayed(const Duration(milliseconds: 300), () {
      final targets = [
        TargetFocus(
          identify: "welcomeTarget",
          keyTarget: _logoKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => _buildTutorialContent(
                "BIENVENUE !", 
                "Merci de nous avoir rejoints sur l'application officielle de l'ASTT E-Sport !\nLaisse-nous te faire une petite visite guidée.",
                controller
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "bellTarget",
          keyTarget: _bellKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => _buildTutorialContent(
                "Alertes & Notifications", 
                "Clique sur cette cloche pour choisir exactement les alertes que tu souhaites recevoir.",
                controller
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "liveTarget",
          keyTarget: _liveKey,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialContent(
                "Tuile de Live", 
                "Quand la section E-sport est en direct, cette carte apparaîtra tout en haut de l'écran pour rejoindre le Twitch en un clic !",
                controller
              ),
            ),
          ],
        ),
      ];

      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: const Color(0xFF0F1115),
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.9,
        onClickTarget: (target) => tutorialCoachMark.next(),
        onFinish: () => _showTutorialPart2(),
      );
      if (!mounted) return;
      tutorialCoachMark.show(context: context);
    });
  }

  void _showTutorialPart2() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setTutorialState(false, true); // Supprime Live, Affiche Tournoi

    Future.delayed(const Duration(milliseconds: 300), () {
      final targets = [
        TargetFocus(
          identify: "tournamentTarget",
          keyTarget: _tournamentKey,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialContent(
                "Inscription Tournois", 
                "De la même façon, lors d'un tournoi, cette carte te permettra de t'inscrire directement.",
                controller
              ),
            ),
          ],
        ),
      ];

      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: const Color(0xFF0F1115),
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.9,
        onClickTarget: (target) => tutorialCoachMark.next(),
        onFinish: () => _showTutorialPart3(),
      );
      if (!mounted) return;
      tutorialCoachMark.show(context: context);
    });
  }

  void _showTutorialPart3() {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setTutorialState(false, false); // Supprime Tournoi, retour à la normale

    Future.delayed(const Duration(milliseconds: 300), () {
      final targets = [
        TargetFocus(
          identify: "tournamentTabTarget",
          keyTarget: _tournamentTabKey,
          shape: ShapeLightFocus.Circle,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialContent(
                "Page Tournois", 
                "Retrouve ici tout l'historique et le suivi en direct de nos tournois !",
                controller
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "socialTarget",
          keyTarget: _socialTabKey,
          shape: ShapeLightFocus.RRect,
          radius: 32,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialContent(
                "Rejoins la Communauté", 
                "Ce bouton te donne un accès direct à notre chaîne Twitch et notre serveur Discord.\n\nTu es maintenant prêt(e) ! À très vite sur le chat, on se retrouve dans l'arène ! 🎮🔥",
                controller,
                isLast: true
              ),
            ),
          ],
        ),
      ];

      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        colorShadow: const Color(0xFF0F1115),
        hideSkip: true,
        paddingFocus: 10,
        opacityShadow: 0.9,
        onClickTarget: (target) => tutorialCoachMark.next(),
        onFinish: () => appState.endTutorial(),
      );
      if (!mounted) return;
      tutorialCoachMark.show(context: context);
    });
  }

  Widget _buildTutorialContent(String title, String description, TutorialCoachMarkController controller, {bool isLast = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        const SizedBox(height: 10),
        Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          onPressed: () => controller.next(),
          child: Text(
            isLast ? "TERMINER" : "SUIVANT", 
            style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 16)
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showSocialModal(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showSocialModal(BuildContext context) {
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
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 20),
                    Text('NOS RÉSEAUX', style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 24),
                    
                    // Discord
                    InkWell(
                      onTap: () async {
                        String url = appState.discordUrl.isNotEmpty ? appState.discordUrl : 'https://discord.com';
                        if (!url.startsWith('http://') && !url.startsWith('https://')) {
                          url = 'https://$url';
                        }
                        try {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Erreur lien: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5865F2).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFF5865F2)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.discord, color: Color(0xFF5865F2), size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Discord', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Rejoindre la communauté', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Twitch
                    InkWell(
                      onTap: () async {
                        String url = appState.twitchUrl.isNotEmpty ? appState.twitchUrl : 'https://twitch.tv';
                        if (!url.startsWith('http://') && !url.startsWith('https://')) {
                          url = 'https://$url';
                        }
                        try {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Erreur lien: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9146FF).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFF9146FF)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.live_tv, color: Color(0xFF9146FF), size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Twitch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Accéder à la chaîne', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // YouTube
                    InkWell(
                      onTap: () async {
                        String url = appState.youtubeUrl.isNotEmpty ? appState.youtubeUrl : 'https://youtube.com';
                        if (!url.startsWith('http://') && !url.startsWith('https://')) {
                          url = 'https://$url';
                        }
                        try {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Erreur lien: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFFFF0000)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_fill, color: Color(0xFFFF0000), size: 32),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('YouTube', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Découvrir nos vidéos', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, GlobalKey? key) {
    final isSelected = _selectedIndex == index;
    // L'index 1 (Réseaux) est toujours "non sélectionné" visuellement car c'est un modal.
    final isActive = isSelected && index != 1;
    final color = isActive ? const Color(0xFF00D4FF) : Colors.grey;

    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2), // Moins de padding forcé
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isActive ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // Empêche le texte de déborder
                style: GoogleFonts.chakraPetch(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool showStaff = appState.isAdminUnlocked || appState.isStaff;

    final List<Widget> pages = [
      HomeScreen(bellKey: _bellKey, liveKey: _liveKey, tournamentKey: _tournamentKey, logoKey: _logoKey),
      const SizedBox(), // Remplacé par le modal Réseaux
      const TournamentScreen(), // Nouveau tab Tournois
      const CodesScreen(),
      const StaffScreen(),
    ];

    return Scaffold(
      extendBody: true, 
      body: pages[_selectedIndex >= pages.length ? 0 : _selectedIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_outlined, Icons.home, 'ACCUEIL', _homeTabKey),
                  _buildNavItem(1, Icons.people_alt_outlined, Icons.people_alt, 'COMMUNAUTÉ', _socialTabKey),
                  _buildNavItem(2, Icons.emoji_events_outlined, Icons.emoji_events, 'TOURNOIS', _tournamentTabKey),
                  if (appState.currentUser != null) _buildNavItem(3, Icons.qr_code_outlined, Icons.qr_code, 'CODES', null),
                  if (showStaff) _buildNavItem(4, Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'STAFF', null),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
