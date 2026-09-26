import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../state/app_state.dart';
import 'auth_screen.dart';

class CodesScreen extends StatefulWidget {
  const CodesScreen({super.key});

  @override
  State<CodesScreen> createState() => _CodesScreenState();
}

class _CodesScreenState extends State<CodesScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: Color(0xFF00D4FF)),
                const SizedBox(height: 24),
                Text(
                  'ACCÈS RÉSERVÉ',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connectez-vous avec l\'adresse e-mail utilisée lors de votre inscription sur HelloAsso pour accéder à vos codes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('SE CONNECTER / S\'INSCRIRE', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Codes', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              appState.logout();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('distributed_codes')
            .where('email', isEqualTo: user.email?.toLowerCase() ?? '')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }

          var docs = snapshot.data?.docs.toList() ?? [];
          docs.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videogame_asset_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("Aucun code de jeu pour le moment.", style: GoogleFonts.chakraPetch(fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 8),
                  const Text("Vos codes s'afficheront ici.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Support plusieurs noms de champs Firestore possibles
              final code = (data['code'] ?? data['gameCode'] ?? data['Code'] ?? '').toString();
              final rawGame = (data['game'] ?? data['gameName'] ?? data['Game'] ?? data['jeu'] ?? 'Jeu inconnu').toString();
              final isUsed = (data['isUsed'] ?? data['used'] ?? false) as bool;

              // Date limite d'utilisation
              String dluStr = '';
              if (rawGame.contains('Date limite:')) {
                final match = RegExp(r'Date limite:\s*([^)]+)').firstMatch(rawGame);
                if (match != null) { dluStr = match.group(1)!; }
              } else if (data['dlu'] != null) {
                dluStr = data['dlu'].toString();
              }

              // Affiche le vrai nom du jeu depuis Firestore, ou les clés disponibles si on ne trouve rien
              String displayGame = rawGame.contains('Date limite:')
                  ? rawGame.split('Date limite:').first.replaceAll('(', '').trim()
                  : rawGame;
                  
              // Remplacement de "Jeu" par "EVA" comme demandé
              if (displayGame.toLowerCase() == 'jeu' || displayGame.trim() == 'Jeu') {
                  displayGame = 'EVA';
              }
                  
              // Debug : si le code est vide, on affiche les champs existants dans Firestore pour aider
              String debugInfo = '';
              if (code.isEmpty || displayGame == 'Jeu inconnu') {
                debugInfo = ' (Champs Firestore: ${data.keys.join(", ")})';
                displayGame += debugInfo;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUsed 
                        ? [const Color(0xFF1A1A1A), const Color(0xFF111111)]
                        : [const Color(0xFF0A1929), const Color(0xFF070C14)], // Fond plus cyberpunk (bleu très profond)
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  // On garde une bordure uniforme fine pour le haut/gauche (1px)
                  border: Border.all(
                    color: isUsed ? Colors.white10 : const Color(0xFF00D4FF).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: isUsed ? [] : [
                    // Ombre Orange en haut à gauche
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 1,
                      offset: const Offset(-4, -4),
                    ),
                    // Ombre Bleue en bas à droite
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 1,
                      offset: const Offset(4, 4),
                    ),
                    // Ombre dure bleue (style 3D) en bas à droite
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                      offset: const Offset(2, 3), 
                      blurRadius: 0, 
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Logo en filigrane / fond discret
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.20, // Moins discret
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover, // Prend toute la taille de la vignette
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      if (isUsed)
                        Positioned(
                          right: -10,
                          top: 10,
                          child: Icon(Icons.close_rounded, size: 100, color: Colors.white.withValues(alpha: 0.02)),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // FIX: Limite la hauteur de la colonne
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min, // FIX: Limite la hauteur
                                    children: [
                                      Text(
                                        displayGame,
                                        style: GoogleFonts.chakraPetch(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2.0,
                                          color: isUsed ? Colors.white30 : Colors.white,
                                          shadows: isUsed ? null : [
                                            const Shadow(color: Color(0xFFFF6B00), blurRadius: 15),
                                            const Shadow(color: Colors.white, blurRadius: 2),
                                          ],
                                        ),
                                      ),
                                      if (dluStr.isNotEmpty)
                                        Text(
                                          "DLU : $dluStr",
                                          style: GoogleFonts.chakraPetch(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isUsed ? Colors.white24 : const Color(0xFF00D4FF).withValues(alpha: 0.8),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isUsed ? Colors.redAccent.withValues(alpha: 0.1) : const Color(0xFF00D4FF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isUsed ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF00D4FF).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min, // FIX
                                    children: [
                                      Icon(isUsed ? Icons.block : Icons.stars, 
                                        color: isUsed ? Colors.redAccent : const Color(0xFF00D4FF), size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        isUsed ? "UTILISÉ" : "DISPO", 
                                        style: GoogleFonts.chakraPetch(
                                          color: isUsed ? Colors.redAccent : const Color(0xFF00D4FF), 
                                          fontSize: 12, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 20),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isUsed ? Colors.white10 : const Color(0xFFFF6B00).withValues(alpha: 0.5)),
                                boxShadow: isUsed ? [] : [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      code.isNotEmpty ? code : "— Code non disponible —",
                                      style: GoogleFonts.courierPrime(
                                        fontSize: code.isNotEmpty ? 22 : 14,
                                        letterSpacing: code.isNotEmpty ? 4 : 1,
                                        fontWeight: FontWeight.bold,
                                        color: code.isNotEmpty
                                            ? (isUsed ? Colors.white24 : Colors.white)
                                            : Colors.white38,
                                        shadows: (!isUsed && code.isNotEmpty) ? [
                                          const Shadow(color: Color(0xFF00D4FF), blurRadius: 8),
                                        ] : null,
                                        fontStyle: code.isEmpty ? FontStyle.italic : null,
                                        decoration: isUsed ? TextDecoration.lineThrough : null,
                                        decorationColor: Colors.white24,
                                      ),
                                    ),
                                  ),
                                  if (!isUsed && code.isNotEmpty)
                                    InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: code));
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('Code copié !', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold)),
                                          backgroundColor: const Color(0xFF00D4FF),
                                          behavior: SnackBarBehavior.floating,
                                        ));
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.copy_rounded, color: Color(0xFF00D4FF), size: 20),
                                      ),
                                    )
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  icon: Icon(
                                    isUsed ? Icons.undo_rounded : Icons.check_circle_outline_rounded, 
                                    color: isUsed ? Colors.white54 : Colors.greenAccent
                                  ),
                                  label: Text(
                                    isUsed ? 'Annuler' : 'Marquer comme utilisé',
                                    style: TextStyle(
                                      color: isUsed ? Colors.white54 : Colors.greenAccent, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                  onPressed: () {
                                    doc.reference.update({'isUsed': !isUsed});
                                  },
                                ),
                                if (isUsed)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded, color: isUsed ? Colors.redAccent : Colors.white30),
                                    hoverColor: Colors.redAccent.withValues(alpha: 0.1),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E1E1E),
                                          title: Text("Supprimer ?", style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold)),
                                          content: const Text("Voulez-vous vraiment supprimer ce code ? Cette action est irréversible.", style: TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULER", style: TextStyle(color: Colors.grey))),
                                            TextButton(
                                              onPressed: () {
                                                doc.reference.delete();
                                                Navigator.pop(ctx);
                                              },
                                              child: const Text("SUPPRIMER", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
