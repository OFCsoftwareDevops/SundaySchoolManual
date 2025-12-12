import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Stream<QuerySnapshot> getChurchResponses(String churchId, String category, String date) {
  return FirebaseFirestore.instance
      .collection('assignment_responses/$category/$date/users')
      .where('churchId', isEqualTo: churchId)
      .snapshots();
}

Future<void> gradeResponse(String category, String date, String userId, String grade, String feedback) async {
  final path = 'assignment_responses/$category/$date/users/$userId';
  await FirebaseFirestore.instance.doc(path).update({
    'grade': grade,
    'feedback': feedback,
    'gradedBy': FirebaseAuth.instance.currentUser?.uid,
    'gradedAt': FieldValue.serverTimestamp(),
  });
}

class RoleService {
  static Future<bool> isChurchAdmin(String churchId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
    final list = token?.claims?['adminChurches'] as List<dynamic>?;
    return list?.contains(churchId) == true;
  }

  static Future<bool> isGroupAdmin(String churchId, String groupId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdTokenResult(true);
    final map = token?.claims?['adminGroups'] as Map<String, dynamic>?;
    final groups = map?[churchId] as List<dynamic>?;
    return groups?.contains(groupId) == true;
  }

  static Future<bool> canManageGroup(String churchId, String groupId) async {
    return await isChurchAdmin(churchId) || await isGroupAdmin(churchId, groupId);
  }
}