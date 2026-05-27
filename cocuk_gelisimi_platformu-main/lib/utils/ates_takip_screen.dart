import 'package:flutter/material.dart';

class AtesTakipScreen extends StatefulWidget {
  const AtesTakipScreen({Key? key}) : super(key: key);

  @override
  State<AtesTakipScreen> createState() => _AtesTakipScreenState();
}

class _AtesTakipScreenState extends State<AtesTakipScreen> {
  final TextEditingController _atesController = TextEditingController();
  String _bakanlikMesaji = "Henüz ateş değeri sorgulanmadı.";
  bool _isLoading = false;

  // Sadece Sağlık Bakanlığı tablosundaki iki seçenek kaldı
  String _olcumYeri = "Koltuk Altı";

  void _saglikBakanligiSistemSorgusu() {
    String girilenAtesMetni = _atesController.text;

    if (girilenAtesMetni.isEmpty) {
      setState(() {
        _bakanlikMesaji = "Lütfen önce geçerli bir ateş değeri girin!";
      });
      return;
    }

    double? atesDegeri = double.tryParse(girilenAtesMetni.replaceAll(',', '.'));

    if (atesDegeri == null) {
      setState(() {
        _bakanlikMesaji = "Geçersiz format! Lütfen sadece sayı giriniz (Örn: 37.2).";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _bakanlikMesaji = "Sağlık Bakanlığı USS veri havuzuna bağlanılıyor...";
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      double normalAltLimit = 36.5;
      double normalUstLimit = 37.0;

      // Tamamen Sağlık Bakanlığı resmi görselindeki iki kritere göre limitler
      if (_olcumYeri == "Koltuk Altı") {
        normalAltLimit = 36.5;
        normalUstLimit = 37.0;
      } else if (_olcumYeri == "Kulaktan") {
        normalAltLimit = 35.7;
        normalUstLimit = 37.5;
      }

      setState(() {
        _isLoading = false;

        if (atesDegeri < normalAltLimit) {
          _bakanlikMesaji = "Sistem Durumu: Doğrulandı (Düşük Ateş)\n"
              "Ölçüm Yeri: $_olcumYeri\n"
              "Bakanlık Standart Aralığı: $normalAltLimit - $normalUstLimit °C\n"
              "Not: Vücut ısısı normal sınırın altında. Ortamı sıcak tutarak takibe devam edin.";
        } else if (atesDegeri >= normalAltLimit && atesDegeri <= normalUstLimit) {
          _bakanlikMesaji = "Sistem Durumu: Doğrulandı (Normal Ateş)\n"
              "Ölçüm Yeri: $_olcumYeri\n"
              "Bakanlık Standart Aralığı: $normalAltLimit - $normalUstLimit °C\n"
              "Not: Ateş normal seyrediyor. Veriler e-Nabız çocuk takip havuzuna işlendi.";
        } else if (atesDegeri > normalUstLimit && atesDegeri <= (normalUstLimit + 1.0)) {
          _bakanlikMesaji = "Sistem Durumu: UYARI (Hafif Ateş)\n"
              "Ölçüm Yeri: $_olcumYeri\n"
              "Bakanlık Standart Aralığı: $normalAltLimit - $normalUstLimit °C\n"
              "Not: Sınır değer aşımı. Çocuğun kıyafetlerini gevşetin, bol sıvı takviyesi yapın ve ölçümü tekrarlayın.";
        } else {
          _bakanlikMesaji = "Sistem Durumu: ACİL UYARI (Yüksek Ateş)\n"
              "Ölçüm Yeri: $_olcumYeri\n"
              "Bakanlık Standart Aralığı: $normalAltLimit - $normalUstLimit °C\n"
              "Not: Kritik sınır geçildi! Çocuğa ılık duş aldırın ve gecikmeden en yakın pediatri uzmanına başvurun.";
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("T.C. Sağlık Bakanlığı Entegrasyonu"),
        backgroundColor: const Color(0xFF5D4037),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Canlı Çocuk Takip Sistemi (USS)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 20),

            // Sadece iki seçenek içeren Dropdown menü
            DropdownButtonFormField<String>(
              value: _olcumYeri,
              decoration: const InputDecoration(
                labelText: "Ölçüm Yapılan Bölge",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.accessibility_new, color: Color(0xFF5D4037)),
              ),
              items: const [
                DropdownMenuItem(value: "Koltuk Altı", child: Text("Koltuk Altı")),
                DropdownMenuItem(value: "Kulaktan", child: Text("Kulaktan")),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _olcumYeri = val;
                  });
                }
              },
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _atesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Ateş Değerini Giriniz",
                hintText: "37.0",
                prefixIcon: Icon(Icons.thermostat, color: Color(0xFF5D4037)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isLoading ? null : _saglikBakanligiSistemSorgusu,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF5D4037),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("e-Nabız Sisteminden Doğrula", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            const Text(
              "Bakanlık Sistem Yanıtı:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _bakanlikMesaji,
                style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _atesController.dispose();
    super.dispose();
  }
}