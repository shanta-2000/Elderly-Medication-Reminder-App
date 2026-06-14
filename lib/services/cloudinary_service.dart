import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = 'dj1ixitle';
  static const String uploadPreset = 'emrapp_unsigned';

  static Future<String> uploadImage({
    required String imagePath,
  }) async {
    if (imagePath.isEmpty) {
      return '';
    }

    final file = File(imagePath);

    if (!await file.exists()) {
      return '';
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri);

    request.fields['upload_preset'] = uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decodedData = jsonDecode(responseBody) as Map<String, dynamic>;
      return decodedData['secure_url']?.toString() ?? '';
    }

    throw Exception('Cloudinary upload failed: $responseBody');
  }
}