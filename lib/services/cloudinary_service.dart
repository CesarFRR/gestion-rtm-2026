import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  // Tus credenciales
  static const String cloudName = "dnljvvheg";
  static const String uploadPreset = "preset_gestion_rtm";

  static final Dio _dio = Dio();

  static Future<String?> uploadImage(
    XFile imageFile,
    String placa,
    String posicion,
  ) async {
    final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

    final String customPublicId =
        "${placa}_${posicion}_${DateTime.now().millisecondsSinceEpoch}";

    try {
      final formData = FormData.fromMap({
        'upload_preset': uploadPreset,
        'public_id': customPublicId,
        'file': await MultipartFile.fromBytes(
          await imageFile.readAsBytes(),
          filename: imageFile.name,
        ),
      });

      final response = await _dio.post(url, data: formData);

      if (response.statusCode == 200) {
        return response.data['secure_url'];
      }
      return null;
    } catch (e) {
      print("Error subiendo a Cloudinary: $e");
      return null;
    }
  }
  /// Método para eliminar una imagen de Cloudinary usando un Proxy (Google Apps Script)
  static Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1) return;

      List<String> idSegments = pathSegments.sublist(uploadIndex + 2);
      String publicIdWithExtension = idSegments.join('/');
      String publicId = publicIdWithExtension.split('.').first;

      const String scriptUrl =
          "https://script.google.com/macros/s/AKfycbzyjNZzJSZWZMnclOUrQjhxxpFnR3o0lihyuwF4J42mO66QOv566jMU2Epj3nxG-qO6/exec";

      print("DEBUG: Solicitando eliminación al Backend: $publicId");
      
      final response = await _dio.post(
        scriptUrl,
        data: {"publicId": publicId},
        options: Options(
          contentType: Headers.jsonContentType,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print("Respuesta del servidor: ${response.data}");
    } catch (e) {
      if (e is DioException) {
        print("Error de Dio: ${e.message}");
        print("Causa: ${e.error}");
      } else {
        print("Error desconocido: $e");
      }
    }
  }
}
