import re

with open('lib/screens/codes_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# find ListView.builder and replace everything after it
listview_idx = content.find('return ListView.builder(')

if listview_idx != -1:
    new_content = content[:listview_idx] + """return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final code = data['code'] ?? 'CODE INCONNU';
              final game = data['game'] ?? 'Jeu inconnu';
              final isUsed = data['isUsed'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isUsed ? const Color(0xFF151515) : const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUsed ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF00D4FF).withOpacity(0.5),
                    width: isUsed ? 1 : 2,
                  ),
                  boxShadow: isUsed ? [] : [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    if (isUsed)
                      Positioned(
                        right: 20,
                        top: 10,
                        child: Icon(Icons.do_disturb_alt, size: 100, color: Colors.redAccent.withOpacity(0.1)),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  game,
                                  style: GoogleFonts.chakraPetch(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isUsed ? Colors.grey[600] : Colors.white,
                                    decoration: isUsed ? TextDecoration.lineThrough : null,
                                    decorationColor: Colors.redAccent,
                                  ),
                                ),
                              ),
                              if (isUsed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.block, color: Colors.redAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text("UTILISÉ", style: GoogleFonts.chakraPetch(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.new_releases, color: Colors.greenAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Text("DISPONIBLE", style: GoogleFonts.chakraPetch(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isUsed ? Colors.redAccent.withOpacity(0.2) : Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    code,
                                    style: GoogleFonts.courierPrime(
                                      fontSize: 22,
                                      letterSpacing: 3,
                                      fontWeight: FontWeight.bold,
                                      color: isUsed ? Colors.redAccent.withOpacity(0.7) : const Color(0xFF00D4FF),
                                      decoration: isUsed ? TextDecoration.lineThrough : null,
                                      decorationColor: Colors.redAccent,
                                      decorationThickness: 2.0,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.copy, color: isUsed ? Colors.white30 : Colors.white),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: code));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copié dans le presse-papier !')));
                                  },
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: Icon(isUsed ? Icons.undo : Icons.check_circle, color: isUsed ? Colors.white70 : Colors.greenAccent),
                                label: Text(
                                  isUsed ? 'Annuler' : 'Marquer utilisé',
                                  style: TextStyle(color: isUsed ? Colors.white70 : Colors.greenAccent, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  doc.reference.update({'isUsed': !isUsed});
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
              );
            },
          );
        },
      ),
    );
  }
}
"""
    with open('lib/screens/codes_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Clean rewrite successful.")
else:
    print("Could not find listview.")
