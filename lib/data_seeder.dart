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

class BoyKiloSeeder {
  static Future<void> seedBoyKilo() async {
    final collection = FirebaseFirestore.instance.collection('boy_kilo');
    final batch = FirebaseFirestore.instance.batch();

    // Senin için hazırladığım WHO (Dünya Sağlık Örgütü) Kusursuz Veri Listesi
    // 0-12 ay her ay, 12-72 ay arası 3'er aylık periyotlar.
    final List<Map<String, dynamic>> boyKiloData = [
      { "ay": 0, "kiz_kilo": 3.2, "kiz_boy": 49.1, "erkek_kilo": 3.3, "erkek_boy": 49.9 },
      { "ay": 1, "kiz_kilo": 4.2, "kiz_boy": 53.7, "erkek_kilo": 4.5, "erkek_boy": 54.7 },
      { "ay": 2, "kiz_kilo": 5.1, "kiz_boy": 57.1, "erkek_kilo": 5.6, "erkek_boy": 58.4 },
      { "ay": 3, "kiz_kilo": 5.8, "kiz_boy": 59.8, "erkek_kilo": 6.4, "erkek_boy": 61.4 },
      { "ay": 4, "kiz_kilo": 6.4, "kiz_boy": 62.1, "erkek_kilo": 7.0, "erkek_boy": 63.9 },
      { "ay": 5, "kiz_kilo": 6.9, "kiz_boy": 64.0, "erkek_kilo": 7.5, "erkek_boy": 65.9 },
      { "ay": 6, "kiz_kilo": 7.3, "kiz_boy": 65.7, "erkek_kilo": 7.9, "erkek_boy": 67.6 },
      { "ay": 7, "kiz_kilo": 7.6, "kiz_boy": 67.3, "erkek_kilo": 8.3, "erkek_boy": 69.2 },
      { "ay": 8, "kiz_kilo": 7.9, "kiz_boy": 68.7, "erkek_kilo": 8.6, "erkek_boy": 70.6 },
      { "ay": 9, "kiz_kilo": 8.2, "kiz_boy": 70.1, "erkek_kilo": 8.9, "erkek_boy": 72.0 },
      { "ay": 10, "kiz_kilo": 8.5, "kiz_boy": 71.5, "erkek_kilo": 9.2, "erkek_boy": 73.3 },
      { "ay": 11, "kiz_kilo": 8.7, "kiz_boy": 72.8, "erkek_kilo": 9.4, "erkek_boy": 74.5 },
      { "ay": 12, "kiz_kilo": 8.9, "kiz_boy": 74.0, "erkek_kilo": 9.6, "erkek_boy": 75.7 },
      { "ay": 15, "kiz_kilo": 9.6, "kiz_boy": 77.5, "erkek_kilo": 10.3, "erkek_boy": 79.1 },
      { "ay": 18, "kiz_kilo": 10.2, "kiz_boy": 80.7, "erkek_kilo": 10.9, "erkek_boy": 82.3 },
      { "ay": 21, "kiz_kilo": 10.9, "kiz_boy": 83.7, "erkek_kilo": 11.5, "erkek_boy": 85.1 },
      { "ay": 24, "kiz_kilo": 11.5, "kiz_boy": 86.4, "erkek_kilo": 12.2, "erkek_boy": 87.8 },
      { "ay": 27, "kiz_kilo": 12.1, "kiz_boy": 88.6, "erkek_kilo": 12.7, "erkek_boy": 89.9 },
      { "ay": 30, "kiz_kilo": 12.7, "kiz_boy": 90.7, "erkek_kilo": 13.3, "erkek_boy": 91.9 },
      { "ay": 33, "kiz_kilo": 13.3, "kiz_boy": 92.9, "erkek_kilo": 13.8, "erkek_boy": 94.0 },
      { "ay": 36, "kiz_kilo": 13.9, "kiz_boy": 95.1, "erkek_kilo": 14.3, "erkek_boy": 96.1 },
      { "ay": 39, "kiz_kilo": 14.4, "kiz_boy": 97.1, "erkek_kilo": 14.8, "erkek_boy": 98.0 },
      { "ay": 42, "kiz_kilo": 15.0, "kiz_boy": 99.0, "erkek_kilo": 15.3, "erkek_boy": 99.9 },
      { "ay": 45, "kiz_kilo": 15.5, "kiz_boy": 100.9, "erkek_kilo": 15.8, "erkek_boy": 101.6 },
      { "ay": 48, "kiz_kilo": 16.1, "kiz_boy": 102.7, "erkek_kilo": 16.3, "erkek_boy": 103.3 },
      { "ay": 51, "kiz_kilo": 16.6, "kiz_boy": 104.5, "erkek_kilo": 16.8, "erkek_boy": 105.0 },
      { "ay": 54, "kiz_kilo": 17.2, "kiz_boy": 106.2, "erkek_kilo": 17.3, "erkek_boy": 106.7 },
      { "ay": 57, "kiz_kilo": 17.7, "kiz_boy": 107.8, "erkek_kilo": 17.8, "erkek_boy": 108.4 },
      { "ay": 60, "kiz_kilo": 18.2, "kiz_boy": 109.4, "erkek_kilo": 18.3, "erkek_boy": 110.0 },
      { "ay": 63, "kiz_kilo": 18.7, "kiz_boy": 110.8, "erkek_kilo": 18.8, "erkek_boy": 111.5 },
      { "ay": 66, "kiz_kilo": 19.2, "kiz_boy": 112.2, "erkek_kilo": 19.4, "erkek_boy": 113.0 },
      { "ay": 69, "kiz_kilo": 19.7, "kiz_boy": 113.6, "erkek_kilo": 19.9, "erkek_boy": 114.5 },
      { "ay": 72, "kiz_kilo": 20.2, "kiz_boy": 115.1, "erkek_kilo": 20.5, "erkek_boy": 116.0 }
    ];

    for (var data in boyKiloData) {
      // Belge adını direkt ayın sayısı yapıyoruz (örn: "0", "12", "36")
      // Böylece eski veriler varsa silinmez, sadece kusursuzca güncellenir!
      var docRef = collection.doc(data['ay'].toString());
      batch.set(docRef, data);
    }

    await batch.commit();
    print("Boy-Kilo verileri (0-72 Ay) başarıyla Firebase'e fırlatıldı! 🚀");
  }
}