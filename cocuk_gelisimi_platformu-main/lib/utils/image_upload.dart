import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImageUploadUtils {
  static const String _cloudName = 'dh67ymzuf';
  static const String _uploadPreset = 'minik_app';

  /// Galeriden resim seçer ve Cloudinary'ye yükler.
  /// Başarılı olursa resmin URL'sini, hata olursa null döner.
  static Future<String?> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      // 1. Galeriden resim seç
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // Boyutu küçültmek için kaliteyi %50'ye çektik
      );

      if (image == null) return null;

      // 2. Cloudinary API URL'si
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      // 3. İstek hazırla (Multipart request)
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      // 4. Gönder ve cevabı al
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonResponse = jsonDecode(responseString);
        
        // 5. Yüklenen resmin güvenli URL'sini (HTTPS) döndür
        return jsonResponse['secure_url'] as String;
      } else {
        throw Exception('Cloudinary Yükleme Hatası (Kod: ${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Resim yüklenirken beklenmedik bir hata oluştu: $e');
    }
  }
}
