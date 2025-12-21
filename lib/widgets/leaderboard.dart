// lib/widgets/leaderboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../UI/segment_sliding.dart';
import '../../../auth/login/auth_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int _selectedAgeGroup = 0; // 0 = Adult, 1 = Teen
  int _selectedScope = 0;    // 0 = Church, 1 = Global

  final List<String> _ageGroups = ["Adult", "Teen"];
  final List<String> _scopes = ["Church", "Global"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // Trigger initial load
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final churchId = auth.churchId;
    final isAdmin = auth.isGlobalAdmin || (auth.hasChurch && auth.adminStatus.isChurchAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Top: Adult / Teen toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: segmentedControl(
              selectedIndex: _selectedAgeGroup,
              items: _ageGroups.map((e) => SegmentItem(e)).toList(),
              onChanged: (i) => setState(() => _selectedAgeGroup = i),
            ),
          ),
          // Nested: Church / Global toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: segmentedControl(
              selectedIndex: _selectedScope,
              items: _scopes.map((e) => SegmentItem(e)).toList(),
              onChanged: (i) => setState(() => _selectedScope = i),
            ),
          ),
          Expanded(
            child: _buildLeaderboard(churchId, isAdmin, _selectedAgeGroup, _selectedScope),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(String? churchId, bool isAdmin, int ageGroup, int scope) {
    final bool isAdult = ageGroup == 0;
    final String type = isAdult ? "adult" : "teen";
    final bool isChurch = scope == 0;

    final userId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<List<UserRank>>(
      future: _fetchLeaderboard(churchId, isChurch, type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final ranks = snapshot.data ?? [];

        if (ranks.isEmpty) {
          return const Center(child: Text("No rankings yet in this category."));
        }

        final myRankIndex = ranks.indexWhere((r) => r.userId == userId);
        final myRankText = myRankIndex != -1 ? "#${myRankIndex + 1}" : "Not ranked yet";

        return Column(
          children: [
            if (userId != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Your Rank: $myRankText",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: ranks.length,
                itemBuilder: (context, index) {
                  final rank = ranks[index];
                  final isMe = rank.userId == userId;
                  final displayName = isAdmin || isMe ? rank.name : "Anonymous Student #${index + 1}";

                  return ListTile(
                    leading: _buildRankBadge(index + 1),
                    title: Text(displayName),
                    trailing: Text(
                      "${rank.totalScore} pts",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    tileColor: isMe ? Colors.deepPurple.shade50 : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) return const Icon(Icons.emoji_events, color: Colors.amber, size: 36);
    if (rank == 2) return const Icon(Icons.emoji_events, color: Colors.grey, size: 36);
    if (rank == 3) return const Icon(Icons.emoji_events, color: Colors.brown, size: 36);
    return Text(
      "#$rank",
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Future<List<UserRank>> _fetchLeaderboard(String? churchId, bool isChurch, String type) async {
    final db = FirebaseFirestore.instance;
    final List<UserRank> ranks = [];

    if (isChurch && churchId != null) {
      // Church leaderboard: query from church-specific leaderboard
      final leaderboardSnap = await db
          .collection('churches')
          .doc(churchId)
          .collection('leaderboard')
          .doc(type)
          .collection('members')
          .orderBy('totalScore', descending: true)
          .get();

      for (var doc in leaderboardSnap.docs) {
        final data = doc.data();
        final name = data['userEmail'] as String? ?? 'Unknown';
        final totalScore = data['totalScore'] as int? ?? 0;

        ranks.add(UserRank(userId: doc.id, name: name, totalScore: totalScore));
      }
    } else {
      // Global leaderboard: aggregate from all churches
      final churchesSnap = await db.collection('churches').get();
      final Map<String, int> scoreMap = {};
      final Map<String, String> nameMap = {};

      for (var churchDoc in churchesSnap.docs) {
        final cid = churchDoc.id;

        // Fetch leaderboard for this church
        final leaderboardSnap = await db
            .collection('churches')
            .doc(cid)
            .collection('leaderboard')
            .doc(type)
            .collection('members')
            .get();

        for (var doc in leaderboardSnap.docs) {
          final uid = doc.id;
          final data = doc.data();
          final totalScore = data['totalScore'] as int? ?? 0;
          final name = data['userEmail'] as String? ?? 'Unknown';

          scoreMap[uid] = (scoreMap[uid] ?? 0) + totalScore;
          nameMap[uid] = name;
        }
      }

      // Build final ranks
      for (var entry in scoreMap.entries) {
        ranks.add(UserRank(
          userId: entry.key,
          name: nameMap[entry.key] ?? 'Unknown',
          totalScore: entry.value,
        ));
      }

      ranks.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    }

    return ranks;
  }
}

class UserRank {
  final String userId;
  final String name;
  final int totalScore;

  UserRank({required this.userId, required this.name, required this.totalScore});
}