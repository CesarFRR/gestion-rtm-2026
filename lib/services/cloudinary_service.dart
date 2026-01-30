import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Tus credenciales
  static const String cloudName = "dnljvvheg";
  static const String uploadPreset =
      "preset_gestion_rtm"; // El que creamos antes

  static Future<String?> uploadImage(
    XFile imageFile,
    String placa,
    String posicion,
  ) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    // Creamos un nombre descriptivo: JKL123_frente_1706654321
    final String customPublicId =
        "${placa}_${posicion}_${DateTime.now().millisecondsSinceEpoch}";

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['public_id'] = customPublicId
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // Esta es la URL que guardaremos en Firestore
      }
      return null;
    } catch (e) {
      print("Error subiendo a Cloudinary: $e");
      return null;
    }
  }
}
