import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/activity_data.dart'; // activity_data yolunu gerekirse kendi klasörüne göre '../data/activity_data.dart' olarak düzelt

class ActivitySeeder {
  static Future<void> seedActivities() async {
    final collection = FirebaseFirestore.instance.collection('activities');

    // Önce eski verileri temizleyelim ki üst üste binmesin
    final currentDocs = await collection.get();
    for (var doc in currentDocs.docs) {
      await doc.reference.delete();
    }

    final batch = FirebaseFirestore.instance.batch();

    // ActivityData içindeki o Bakanlık listesini dönüyoruz
    for (var activity in ActivityData.activities) {
      var docRef = collection.doc();
      batch.set(docRef, activity.toMap());
    }

    await batch.commit();
    print("Bakanlık verileri başarıyla Firebase'e fırlatıldı! 🚀");
  }
}
