import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';

class UploadResult {
  final bool success;
  final String? url;
  final String? fileName;
  final String? originalName;
  final String? errorMessage;

  UploadResult({
    required this.success,
    this.url,
    this.fileName,
    this.originalName,
    this.errorMessage,
  });
}

class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final ApiClient _apiClient = ApiClient();

  /// رفع ملف حقيقي فردي (صورة شخصية، هوية، رخصة، استمارة، شهادة آيبان PDF، صورة سيارة)
  Future<UploadResult> uploadFile(PlatformFile file) async {
    try {
      final fileName = file.name;
      final bytes = file.bytes;
      final path = file.path;

      MultipartFile multipartFile;

      if (bytes != null && bytes.isNotEmpty) {
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else if (!kIsWeb && path != null && path.isNotEmpty) {
        multipartFile = await MultipartFile.fromFile(path, filename: fileName);
      } else {
        return UploadResult(
          success: false,
          errorMessage: 'تعذر قراءة بيانات الملف المختار',
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.uploadSingle,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = response.data;
        final data = resData is Map ? resData['data'] : null;
        final fileUrl = data != null ? data['url']?.toString() : null;
        final savedFileName = data != null ? data['fileName']?.toString() : null;

        if (fileUrl != null && fileUrl.isNotEmpty) {
          return UploadResult(
            success: true,
            url: fileUrl,
            fileName: savedFileName,
            originalName: fileName,
          );
        }
      }

      return UploadResult(
        success: false,
        errorMessage: 'فشل استلام رابط الملف من الخادم',
      );
    } catch (e) {
      debugPrint('UploadService error: $e');
      String msg = 'حدث خطأ أثناء رفع الملف إلى الخادم';
      if (e is DioException) {
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          msg = e.response!.data['message'].toString();
        } else if (e.error != null) {
          msg = e.error.toString();
        }
      }
      return UploadResult(
        success: false,
        errorMessage: msg,
      );
    }
  }

  /// تحويل أي رابط مسار نسبي (مثل /uploads/xxx.jpg) إلى رابط كامل صالح للعرض
  static String formatUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '${ApiEndpoints.baseDomain}$trimmed';
    }
    return '${ApiEndpoints.baseDomain}/$trimmed';
  }
}
