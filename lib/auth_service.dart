import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> createUserWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> updateUserProfile({required String uid, String? username, String? photoUrl, String? university, String? specialty, String? year, String? role}) async {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (university != null) data['university'] = university;
    if (specialty != null) data['specialty'] = specialty;
    if (year != null) data['year'] = year;
    if (role != null) data['role'] = role;
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(credential);
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> enableUser(String uid) async {
    // Firebase Auth لا يدعم تعطيل/تفعيل عبر SDK، لكن يمكن تحديث حقل في Firestore
    await _firestore.collection('users').doc(uid).update({'disabled': false});
  }

  Future<void> disableUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'disabled': true});
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
    // حذف من Auth يحتاج Admin SDK أو Cloud Function
  }

  Stream<QuerySnapshot> getAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _firestore.collection('users').where('role', isEqualTo: role).snapshots();
  }
}