import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GrowthDataSeeder {
  // İlk 12 Ayın Örnek Referans Verileri (Siteden alınan şablona göre)
  static final Map<String, dynamic> _ilk12Ay = {
    "ay_0": {
      "kiz": {"kilo": {"alt": 2.4, "ideal": 3.2, "ust": 4.2}, "boy": {"alt": 45.4, "ideal": 49.1, "ust": 52.9}},
      "erkek": {"kilo": {"alt": 2.5, "ideal": 3.3, "ust": 4.3}, "boy": {"alt": 46.1, "ideal": 49.9, "ust": 53.8}}
    },
    "ay_1": {
      "kiz": {"kilo": {"alt": 3.2, "ideal": 4.2, "ust": 5.4}, "boy": {"alt": 49.8, "ideal": 53.7, "ust": 57.6}},
      "erkek": {"kilo": {"alt": 3.4, "ideal": 4.5, "ust": 5.8}, "boy": {"alt": 50.8, "ideal": 54.7, "ust": 58.6}}
    },
    "ay_2": {
      "kiz": {"kilo": {"alt": 4.0, "ideal": 5.1, "ust": 6.5}, "boy": {"alt": 53.0, "ideal": 57.1, "ust": 61.1}},
      "erkek": {"kilo": {"alt": 4.3, "ideal": 5.6, "ust": 7.1}, "boy": {"alt": 54.4, "ideal": 58.4, "ust": 62.4}}
    },
    "ay_3": {
      "kiz": {"kilo": {"alt": 4.5, "ideal": 5.8, "ust": 7.5}, "boy": {"alt": 55.6, "ideal": 59.8, "ust": 64.0}},
      "erkek": {"kilo": {"alt": 5.0, "ideal": 6.4, "ust": 8.0}, "boy": {"alt": 57.3, "ideal": 61.4, "ust": 65.5}}
    },
    // Not: Gerçek projede 4,5,6...12. ayları buraya ekleyebilirsin.
  };

  static Future<void> seedDataToFirebase() async {
    try {
      final collection = FirebaseFirestore.instance.collection('growth_standards');

      // 1. Aşama: İlk 12 Ayı Gerçek Verilerle Yükle
      _ilk12Ay.forEach((ayKey, data) async {
        await collection.doc(ayKey).set(data);
      });

      // 2. Aşama: 13. Aydan 72. Aya (6 Yaş) Kadar Olan Kayıtları Veritabanında Otomatik Aç
      // Böylece veritabanı yapısı hazır olur, sen sonra panelden gerçek değerleri girersin.
      for (int i = 4; i <= 72; i++) { // Yukarıda 3'e kadar girdik, 4'ten 72'ye kadar taslağı oluşturalım
        if(!_ilk12Ay.containsKey('ay_$i')){
          await collection.doc('ay_$i').set({
            "kiz": {"kilo": {"alt": 0.0, "ideal": 0.0, "ust": 0.0}, "boy": {"alt": 0.0, "ideal": 0.0, "ust": 0.0}},
            "erkek": {"kilo": {"alt": 0.0, "ideal": 0.0, "ust": 0.0}, "boy": {"alt": 0.0, "ideal": 0.0, "ust": 0.0}}
          });
        }
      }

      debugPrint("MÜKEMMEL! 72 Aylık veritabanı iskeleti başarıyla oluşturuldu.");
    } catch (e) {
      debugPrint("HATA OLUŞTU: $e");
    }
  }
}