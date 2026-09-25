import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final TextEditingController _announceTitleController = TextEditingController();
  final TextEditingController _announceDescController = TextEditingController();
  final TextEditingController _announceLinkTextController = TextEditingController();
  final TextEditingController _announceLinkUrlController = TextEditingController();
  final TextEditingController _tournamentUrlController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _twitchUrlController = TextEditingController();
  final TextEditingController _discordUrlController = TextEditingController();
  final TextEditingController _youtubeUrlController = TextEditingController();
  
  final TextEditingController _liveTitleController = TextEditingController();
  final TextEditingController _liveDescController = TextEditingController();
  int _liveState = 0;
  DateTime? _liveScheduledDate;
  
  final TextEditingController _tournamentTitleController = TextEditingController();
  final TextEditingController _tournamentDescController = TextEditingController();
  int _tournamentState = 0;
  DateTime? _tournamentRegistrationEndDate;
  DateTime? _tournamentStartDate;

  final TextEditingController _updateVersionController = TextEditingController();
  final TextEditingController _updateUrlController = TextEditingController();
  final TextEditingController _updateMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.tournamentUrl != null) {
        _tournamentUrlController.text = appState.tournamentUrl!;
      }
      if (appState.twitchUrl.isNotEmpty) {
        _twitchUrlController.text = appState.twitchUrl;
      } else {
        _twitchUrlController.text = "https://twitch.tv/mon_asso";
      }
      if (appState.discordUrl.isNotEmpty) {
        _discordUrlController.text = appState.discordUrl;
      } else {
        _discordUrlController.text = "https://discord.gg/...";
      }
      if (appState.youtubeUrl.isNotEmpty) {
        _youtubeUrlController.text = appState.youtubeUrl;
      } else {
        _youtubeUrlController.text = "https://youtube.com/...";
      }
      
      _liveTitleController.text = appState.liveTitle;
      _liveDescController.text = appState.liveDesc;
      _tournamentTitleController.text = appState.tournamentTitle;
      _tournamentDescController.text = appState.tournamentDesc;

      _updateVersionController.text = appState.latestAppVersionName;
      _updateUrlController.text = appState.updateUrl;
      _updateMessageController.text = appState.updateMessage;
      
      setState(() {
        _liveState = appState.liveState;
        _liveScheduledDate = appState.liveScheduledDate;
        _tournamentState = appState.tournamentState;
        _tournamentRegistrationEndDate = appState.tournamentRegistrationEndDate;
        _tournamentStartDate = appState.tournamentStartDate;
      });
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final error = await appState.login(_emailController.text.trim(), _passwordController.text);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = error;
      });
    }
  }

  void _showAnnouncementModal({String? docId, String? currentTitle, String? currentDesc, String? currentLinkText, String? currentLinkUrl}) {
    _announceTitleController.text = currentTitle ?? '';
    _announceDescController.text = currentDesc ?? '';
    _announceLinkTextController.text = currentLinkText ?? '';
    _announceLinkUrlController.text = currentLinkUrl ?? '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2129),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(docId == null ? 'NOUVELLE ANNONCE' : 'MODIFIER L\'ANNONCE', style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                  controller: _announceTitleController,
                  decoration: InputDecoration(labelText: 'Titre', filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _announceDescController,
                  minLines: 3,
                  maxLines: null,
                  decoration: InputDecoration(labelText: 'Description', filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _announceLinkTextController,
                        decoration: InputDecoration(labelText: 'Texte Bouton', filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _announceLinkUrlController,
                        decoration: InputDecoration(labelText: 'URL Bouton', filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final title = _announceTitleController.text.trim();
                      final description = _announceDescController.text.trim();
                      final linkText = _announceLinkTextController.text.trim();
                      final linkUrl = _announceLinkUrlController.text.trim();
                      
                      if (title.isEmpty || description.isEmpty) {
                        ScaffoldMessenger.of(modalContext).showSnackBar(const SnackBar(content: Text('Titre et description requis.')));
                        return;
                      }

                      try {
                        if (docId == null) {
                          await FirebaseFirestore.instance.collection('announcements').add({
                            'title': title, 'description': description,
                            if (linkText.isNotEmpty) 'linkText': linkText,
                            if (linkUrl.isNotEmpty) 'linkUrl': linkUrl,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await FirebaseFirestore.instance.collection('announcements').doc(docId).update({
                            'title': title, 'description': description,
                            'linkText': linkText.isNotEmpty ? linkText : FieldValue.delete(),
                            'linkUrl': linkUrl.isNotEmpty ? linkUrl : FieldValue.delete(),
                          });
                        }
                        if (modalContext.mounted) { Navigator.pop(modalContext); }
                      } catch (e) {
                        if (modalContext.mounted) {
                          ScaffoldMessenger.of(modalContext).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text('ENREGISTRER', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAnnouncement(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        title: Text('Supprimer ?', style: GoogleFonts.chakraPetch(color: Colors.white)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER', style: TextStyle(color: Colors.grey))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('SUPPRIMER')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
    }
  }

  Future<void> _selectDateTime(BuildContext context, DateTime? initialDate, Function(DateTime) onDateSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );
      if (pickedTime != null && context.mounted) {
        onDateSelected(DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        ));
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _announceTitleController.dispose();
    _announceDescController.dispose();
    _announceLinkTextController.dispose();
    _announceLinkUrlController.dispose();
    _tournamentUrlController.dispose();
    _twitchUrlController.dispose();
    _discordUrlController.dispose();
    _youtubeUrlController.dispose();
    _liveTitleController.dispose();
    _liveDescController.dispose();
    _tournamentTitleController.dispose();
    _tournamentDescController.dispose();
    _updateVersionController.dispose();
    _updateUrlController.dispose();
    _updateMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.currentUser == null) {
      return _buildLoginScreen();
    }

    return SafeArea(
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ESPACE STAFF', style: GoogleFonts.chakraPetch(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () => appState.logout(),
                  ),
                ],
              ),
            ),
            const TabBar(
              indicatorColor: Color(0xFF00D4FF),
              labelColor: Color(0xFF00D4FF),
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(icon: Icon(Icons.videocam), text: 'LIVE'),
                Tab(icon: Icon(Icons.emoji_events), text: 'TOURNOI'),
                Tab(icon: Icon(Icons.announcement), text: 'ANNONCES'),
                Tab(icon: Icon(Icons.settings), text: 'DIVERS'),
                Tab(icon: Icon(Icons.people), text: 'COMPTES'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLiveTab(appState),
                  _buildTournamentTab(appState),
                  _buildAnnouncementsTab(),
                  _buildSettingsTab(appState),
                  _buildUsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CONNEXION STAFF', style: GoogleFonts.chakraPetch(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Authentifiez-vous pour administrer l\'application.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 32),
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Mot de passe', filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), obscureText: true),
            const SizedBox(height: 24),
            if (_errorMessage != null) Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent))),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : Text('SE CONNECTER', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTab(AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestion du Live', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _liveState,
                  dropdownColor: const Color(0xFF1E2129),
                  decoration: InputDecoration(labelText: 'Statut du Live', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Inactif')),
                    DropdownMenuItem(value: 1, child: Text('Programmé')),
                    DropdownMenuItem(value: 2, child: Text('En Direct')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _liveState = val);
                  },
                ),
                if (_liveState == 1) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Date prévue :'),
                    subtitle: Text(_liveScheduledDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_liveScheduledDate!) : 'Non définie'),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFF00D4FF)),
                    onTap: () => _selectDateTime(context, _liveScheduledDate, (date) => setState(() => _liveScheduledDate = date)),
                  ),
                ],
                const Divider(color: Colors.white10, height: 24),
                TextField(
                  controller: _liveTitleController,
                  decoration: InputDecoration(labelText: 'Titre de la tuile', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _liveDescController,
                  minLines: 3,
                  maxLines: null,
                  decoration: InputDecoration(labelText: 'Description', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      appState.setLiveState(
                        _liveState, 
                        title: _liveTitleController.text.trim(), 
                        desc: _liveDescController.text.trim(),
                        scheduledDate: _liveScheduledDate
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Live mis à jour !'), backgroundColor: Colors.green));
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Sauvegarder'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF00D4FF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTournamentTab(AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestion du Tournoi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _tournamentState,
                  dropdownColor: const Color(0xFF1E2129),
                  decoration: InputDecoration(labelText: 'Statut du Tournoi', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Inactif')),
                    DropdownMenuItem(value: 1, child: Text('Inscriptions Ouvertes')),
                    DropdownMenuItem(value: 2, child: Text('Événement à venir')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _tournamentState = val);
                  },
                ),
                if (_tournamentState == 1) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Fin des inscriptions :'),
                    subtitle: Text(_tournamentRegistrationEndDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_tournamentRegistrationEndDate!) : 'Non définie'),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFFFF8C00)),
                    onTap: () => _selectDateTime(context, _tournamentRegistrationEndDate, (date) => setState(() => _tournamentRegistrationEndDate = date)),
                  ),
                ],
                if (_tournamentState == 2 || _tournamentState == 1) ...[
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Début de l\'événement :'),
                    subtitle: Text(_tournamentStartDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_tournamentStartDate!) : 'Non définie'),
                    trailing: const Icon(Icons.event, color: Color(0xFFFF8C00)),
                    onTap: () => _selectDateTime(context, _tournamentStartDate, (date) => setState(() => _tournamentStartDate = date)),
                  ),
                ],
                const Divider(color: Colors.white10, height: 24),
                TextField(
                  controller: _tournamentTitleController,
                  decoration: InputDecoration(labelText: 'Titre du Tournoi', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tournamentDescController,
                  minLines: 3,
                  maxLines: null,
                  decoration: InputDecoration(labelText: 'Infos, Prix, Dates...', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tournamentUrlController,
                  decoration: InputDecoration(labelText: 'Lien du tournoi (ex: HelloAsso)', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      appState.setTournamentState(
                        _tournamentState, 
                        url: _tournamentUrlController.text.trim(), 
                        title: _tournamentTitleController.text.trim(), 
                        desc: _tournamentDescController.text.trim(),
                        regEndDate: _tournamentRegistrationEndDate,
                        startDate: _tournamentStartDate
                      );
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournoi mis à jour !'), backgroundColor: Colors.green));
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Sauvegarder'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8C00)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Text('ARCHIVES DES TOURNOIS', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tournaments').orderBy('updatedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(16.0), child: Text("Aucun tournoi archivé.", style: TextStyle(color: Colors.grey)));

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['title'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text('ID: ${doc.id}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.ondemand_video, color: (data['replayUrl'] != null && data['replayUrl'].isNotEmpty) ? const Color(0xFF00D4FF) : Colors.grey),
                            onPressed: () async {
                              final TextEditingController urlCtrl = TextEditingController(text: data['replayUrl'] ?? '');
                              final newUrl = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E2129),
                                  title: Text('Lien YouTube Replay', style: GoogleFonts.chakraPetch(color: Colors.white)),
                                  content: TextField(
                                    controller: urlCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'https://youtube.com/...',
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.2),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULER', style: TextStyle(color: Colors.grey))),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, urlCtrl.text.trim()), 
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black), 
                                      child: const Text('ENREGISTRER')
                                    ),
                                  ],
                                ),
                              );
                              if (newUrl != null) {
                                await FirebaseFirestore.instance.collection('tournaments').doc(doc.id).update({'replayUrl': newUrl});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E2129),
                              title: Text('Supprimer ?', style: GoogleFonts.chakraPetch(color: Colors.white)),
                              content: Text('Supprimer dÃ©finitivement "${data['title']}" ?', style: const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER', style: TextStyle(color: Colors.grey))),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true), 
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), 
                                  child: const Text('SUPPRIMER')
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance.collection('tournaments').doc(doc.id).delete();
                          }
                        },
                      ),
                    ],
                  ),
                );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            
            if (docs.isEmpty) {
              return const Center(child: Text("Aucune annonce active.", style: TextStyle(color: Colors.grey)));
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(data['description'] ?? '', style: const TextStyle(color: Colors.white70)),
                        if (data['linkText'] != null) ...[
                          const SizedBox(height: 8),
                          Text('ðŸ”— ${data['linkText']}', style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12)),
                        ]
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _showAnnouncementModal(
                            docId: doc.id,
                            currentTitle: data['title'],
                            currentDesc: data['description'],
                            currentLinkText: data['linkText'],
                            currentLinkUrl: data['linkUrl'] ?? data['actionUrl'],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteAnnouncement(doc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showAnnouncementModal(),
            backgroundColor: const Color(0xFF00D4FF),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('NOUVELLE ANNONCE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIENS RÉSEAUX SOCIAUX', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                TextField(
                  controller: _twitchUrlController,
                  decoration: InputDecoration(labelText: 'Lien de la chaîne Twitch', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _discordUrlController,
                  decoration: InputDecoration(labelText: 'Lien d\'invitation Discord', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _youtubeUrlController,
                  decoration: InputDecoration(labelText: 'Lien de la chaîne YouTube', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      appState.setSocialUrls(_twitchUrlController.text.trim(), _discordUrlController.text.trim(), _youtubeUrlController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réseaux mis à jour !'), backgroundColor: Colors.green));
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Sauvegarder les liens'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF00D4FF)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          Text('MISE À JOUR DE L\'APP', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Version de cette application : ${appState.currentAppVersionName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: _updateVersionController,
                  decoration: InputDecoration(labelText: 'Dernière Version Requise (ex: 1.06)', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  keyboardType: TextInputType.text,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _updateUrlController,
                  decoration: InputDecoration(labelText: 'URL de l\'APK', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _updateMessageController,
                  minLines: 3,
                  maxLines: null,
                  decoration: InputDecoration(labelText: 'Message de nouveautés', filled: true, fillColor: Colors.black.withValues(alpha: 0.2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final version = _updateVersionController.text.trim();
                    appState.publishUpdate(version, _updateUrlController.text.trim(), _updateMessageController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Infos de mise à jour publiées !'), backgroundColor: Colors.green));
                  },
                  icon: const Icon(Icons.system_update, size: 16),
                  label: const Text('PUBLIER LA MISE À JOUR'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D4FF), foregroundColor: Colors.black),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          
          Text('DEBUG & NOTIFICATIONS', style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Mode Test (Notifications)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Coupe l\'envoi des notifs via le serveur', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Switch(
                  value: appState.isTestMode, 
                  onChanged: (val) {
                    appState.setTestMode(val);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Mode Test ACTIVÉ' : 'Mode Test DÉSACTIVÉ'), backgroundColor: val ? Colors.orange : Colors.green));
                  }, 
                  activeThumbColor: Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text("Aucun compte trouvé.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final email = data['email'] ?? 'Sans email';
            final isStaff = data['isStaff'] ?? false;

            return Card(
              color: const Color(0xFF1E1E1E),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(isStaff ? 'Staff / Admin' : 'Utilisateur', style: TextStyle(color: isStaff ? const Color(0xFF00D4FF) : Colors.grey)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isStaff || email.toLowerCase() == 'airwolfex@gmail.com',
                      activeThumbColor: const Color(0xFF00D4FF),
                      onChanged: email.toLowerCase() == 'airwolfex@gmail.com'
                          ? null
                          : (val) async {
                              try {
                                await doc.reference.set({'isStaff': val}, SetOptions(merge: true));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Droits mis à jour pour ' + email, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 1),
                                  ));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Erreur Firestore: ' + e.toString(), style: const TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.redAccent,
                                  ));
                                }
                              }
                            },
                    ),
                    if (email.toLowerCase() != 'airwolfex@gmail.com')
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          try {
                            await doc.reference.delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Compte supprimé: ' + email),
                                backgroundColor: Colors.orange,
                                duration: const Duration(seconds: 1),
                              ));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Erreur suppression: ' + e.toString()),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

}

