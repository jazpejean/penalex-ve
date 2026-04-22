
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();

  static Future<void> ensureUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'nivel_actual': 1,
      'xp_total': 0,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true),);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  static Future<String?> uploadProfileImage(ImageSource source) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final XFile? selected = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (selected == null) return null;

    final bytes = await selected.readAsBytes();
    final Reference ref = _storage.ref('user_profiles/${user.uid}.jpg');
    final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

    await ref.putData(bytes, metadata);
    final String downloadUrl = await ref.getDownloadURL();

    await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true),);

    await user.updatePhotoURL(downloadUrl);
    await user.reload();
    return downloadUrl;
  }

  static String rankLabel(int nivel) {
    if (nivel <= 100) return 'Asistente Judicial';
    if (nivel <= 500) return 'Abogado Litigante';
    return 'Magistrado';
  }
}
