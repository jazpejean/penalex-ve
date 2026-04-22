import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  static const Color azulMarino = Color(0xFF0F172A);
  static const Color dorado = Color(0xFFC5A059);
  static const Color tarjeta = Color(0xFF111827);

  String _rankLabel(int nivel) {
    if (nivel <= 100) return 'Asistente Judicial';
    if (nivel <= 500) return 'Abogado Litigante';
    return 'Magistrado';
  }

  String _initials(String? displayName, String? email) {
    final String name = displayName?.trim().isNotEmpty == true ? displayName! : email ?? 'U';
    final List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("Ranking Quiz Judicial"),
        backgroundColor: azulMarino,
      ),
      drawer: const AppDrawer(currentRoute: "/ranking"),
      backgroundColor: azulMarino,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .orderBy("xp_total", descending: true)
            .limit(50)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: dorado));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Aún no hay jugadores en el ranking.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> users = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> item = users[index].data();
              final String name = item["displayName"] as String? ?? item["email"] as String? ?? "Usuario";
              final String rank = _rankLabel((item["nivel_actual"] as int?) ?? 1);
              final int xp = (item["xp_total"] as int?) ?? 0;
              final String? photoUrl = item["photoUrl"] as String?;
              final bool isTop3 = index < 3;

              return Card(
                color: tarjeta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isTop3 ? dorado : const Color(0xFF1E293B),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null
                            ? Text(
                                _initials(item["displayName"] as String?, item["email"] as String?),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  "${index + 1}.",
                                  style: TextStyle(
                                      color: isTop3 ? dorado : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(rank, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text("XP: $xp", style: const TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (isTop3)
                        Icon(
                          index == 0 ? Icons.emoji_events : Icons.workspace_premium,
                          color: dorado,
                        )
                      else
                        Text(
                          "$xp",
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
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
