import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> with SingleTickerProviderStateMixin {
  String? _selectedTournamentId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFFF8C00), size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('tournaments').orderBy('updatedAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Chargement...', style: TextStyle(color: Colors.grey));
                      }
                      
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text("Il n'y a pour le moment pas d'historique ou de tournoi en cours.", style: TextStyle(color: Colors.grey));
                      }

                      if (_selectedTournamentId != null && !docs.any((d) => d.id == _selectedTournamentId)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedTournamentId = null;
                          });
                        });
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Sélectionner un tournoi', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            value: docs.any((d) => d.id == _selectedTournamentId) ? _selectedTournamentId : null,
                            dropdownColor: const Color(0xFF1E2129),
                            underline: Container(height: 2, color: const Color(0xFF00D4FF)),
                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00D4FF)),
                            style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTournamentId = newValue;
                              });
                            },
                            items: docs.map((DocumentSnapshot doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(data['title'] ?? 'Tournoi Sans Titre'),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              if (_selectedTournamentId == null) return const SizedBox();
                              
                              final foundDocs = docs.where((d) => d.id == _selectedTournamentId).toList();
                              final currentDoc = foundDocs.isNotEmpty ? foundDocs.first : docs.first;
                              final data = currentDoc.data() as Map<String, dynamic>;
                              final replayUrl = data['replayUrl'] as String?;
                              final hasReplay = replayUrl != null && replayUrl.isNotEmpty;
                              
                              return ElevatedButton.icon(
                                onPressed: hasReplay ? () async {
                                  try {
                                    await launchUrl(Uri.parse(replayUrl), mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    debugPrint('Erreur lien: $e');
                                  }
                                } : null,
                                icon: Icon(Icons.play_circle_fill, size: 16, color: hasReplay ? Colors.white : Colors.white38),
                                label: Text(hasReplay ? 'REVOIR LE CAST (YOUTUBE)' : 'REPLAY INDISPONIBLE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hasReplay ? const Color(0xFFFF0000) : Colors.grey.withValues(alpha: 0.2),
                                  foregroundColor: hasReplay ? Colors.white : Colors.white38,
                                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
                                  disabledForegroundColor: Colors.white38,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 36),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              );
                            }
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFF8C00),
            labelColor: const Color(0xFFFF8C00),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'CLASSEMENT'),
              Tab(text: 'MATCHS'),
            ],
          ),
          
          Expanded(
            child: _selectedTournamentId == null 
              ? const Center(child: Text('Sélectionnez un tournoi dans le menu pour voir les détails.', style: TextStyle(color: Colors.grey)))
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('tournaments').doc(_selectedTournamentId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.data!.exists) {
                      return const Center(child: Text('Ce tournoi n\'existe plus.'));
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final teams = List<dynamic>.from(data['teams'] ?? []);
                    final matches = List<dynamic>.from(data['matches'] ?? []);
                    final ranking = List<dynamic>.from(data['ranking'] ?? []);
                    
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRankingTab(ranking, matches, teams),
                        _buildMatchesTab(matches, teams),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }


  Widget _buildRankingTab(List<dynamic> ranking, List<dynamic> matches, List<dynamic> teams) {
    if (ranking.isEmpty) {
      return const Center(child: Text('Aucun classement disponible.', style: TextStyle(color: Colors.grey)));
    }

    String getTeamName(String id) {
      final foundTeams = teams.where((t) => t['id'] == id).toList();
      final team = foundTeams.isNotEmpty ? foundTeams.first : {'name': 'Inconnu'};
      return team['name'];
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
      itemCount: ranking.length,
      itemBuilder: (context, index) {
        final team = ranking[index];
        final isTop = index < 2;
        
        // Find matches for this team
        final teamMatches = matches.where((m) => m['teamAId'] == team['id'] || m['teamBId'] == team['id']).toList();

        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isTop ? const Color(0xFF00D4FF) : Colors.transparent, width: isTop ? 1 : 0),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Text(
                    '#${index + 1}',
                    style: GoogleFonts.chakraPetch(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: isTop ? const Color(0xFF00D4FF) : Colors.grey
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team['name'] ?? 'Équipe', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                _buildStatBadge('Matchs', team['played'].toString()),
                                const SizedBox(width: 6),
                                _buildStatBadge('Victoires', team['wins'].toString(), color: Colors.green),
                                const SizedBox(width: 6),
                                _buildStatBadge('%', '${team['percent']}%', color: const Color(0xFF00D4FF)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              children: [
                if (teamMatches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucun match joué.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ...teamMatches.map((m) {
                  final isA = m['teamAId'] == team['id'];
                  final oppId = isA ? m['teamBId'] : m['teamAId'];
                  final oppName = getTeamName(oppId);
                  final myWins = isA ? (m['winsA'] ?? 0) : (m['winsB'] ?? 0);
                  final oppWins = isA ? (m['winsB'] ?? 0) : (m['winsA'] ?? 0);
                  
                  Color resultColor = Colors.grey;
                  if (myWins > oppWins) { resultColor = Colors.green; }
                  else if (myWins < oppWins) { resultColor = Colors.redAccent; }
                  
                  final maps = List<dynamic>.from(m['maps'] ?? []);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(left: BorderSide(color: resultColor, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contre $oppName : $myWins - $oppWins', style: TextStyle(fontWeight: FontWeight.bold, color: resultColor, fontSize: 13)),
                        if (maps.isNotEmpty) const SizedBox(height: 4),
                        ...maps.map((map) {
                          final myPct = isA ? (map['percentA'] ?? 0) : (map['percentB'] ?? 0);
                          final oppPct = isA ? (map['percentB'] ?? 0) : (map['percentA'] ?? 0);
                          final mapName = map['mapName'] ?? 'Map';
                          if (mapName == '' && myPct == 0 && oppPct == 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mapName, 
                                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$myPct% vs $oppPct%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBadge(String label, String value, {Color color = Colors.grey}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text('$label: $value', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMatchesTab(List<dynamic> matches, List<dynamic> teams) {
    if (matches.isEmpty) {
      return const Center(child: Text('Aucun match pour le moment.', style: TextStyle(color: Colors.grey)));
    }

    String getTeamName(String id) {
      final foundTeams = teams.where((t) => t['id'] == id).toList();
      final team = foundTeams.isNotEmpty ? foundTeams.first : {'name': 'Inconnu'};
      return team['name'];
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final nameA = getTeamName(match['teamAId']);
        final nameB = getTeamName(match['teamBId']);
        
        final winsA = match['winsA'] ?? 0;
        final winsB = match['winsB'] ?? 0;
        final maps = List<dynamic>.from(match['maps'] ?? []);

        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          margin: const EdgeInsets.only(bottom: 12),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nameA,
                      style: TextStyle(fontWeight: winsA > winsB ? FontWeight.bold : FontWeight.normal, color: winsA > winsB ? Colors.green : Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$winsA - $winsB', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00D4FF))),
                  ),
                  Expanded(
                    child: Text(
                      nameB,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: winsB > winsA ? FontWeight.bold : FontWeight.normal, color: winsB > winsA ? Colors.green : Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              children: [
                if (maps.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Aucune map jouée pour l\'instant', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ...maps.map((map) {
                  final percentA = map['percentA'] ?? 0;
                  final percentB = map['percentB'] ?? 0;
                  final mapName = map['mapName'] ?? 'Map';
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Text('$percentA%', style: TextStyle(color: percentA > percentB ? Colors.green : Colors.grey, fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mapName, 
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$percentB%', style: TextStyle(color: percentB > percentA ? Colors.green : Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
