import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  final String _bucketName = 'vehicle-photos';

  /// Chụp ảnh từ camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 70, // Compress để tiết kiệm bandwidth
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể chụp ảnh: $e');
    }
  }

  /// Chọn ảnh từ thư viện
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 70, // Compress để tiết kiệm bandwidth
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Không thể chọn ảnh: $e');
    }
  }

  /// Upload ảnh lên Supabase Storage
  /// Returns: URL công khai của ảnh đã upload
  Future<String> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Tạo tên file unique
      final String uploadFileName = fileName ?? 
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';

      // Đường dẫn trong Supabase Storage
      final String path = '$folder/$uploadFileName';

      // Upload file
      await _supabase.storage
          .from(_bucketName)
          .upload(path, imageFile);

      // Lấy public URL
      final String publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw Exception('Không thể upload ảnh: $e');
    }
  }

  /// Upload nhiều ảnh cùng lúc
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    try {
      final List<String> urls = [];

      for (final file in imageFiles) {
        final url = await uploadImage(
          imageFile: file,
          folder: folder,
        );
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Không thể upload nhiều ảnh: $e');
    }
  }

  /// Xóa ảnh từ Supabase Storage
  Future<void> deleteImage(String imagePath) async {
    try {
      await _supabase.storage
          .from(_bucketName)
          .remove([imagePath]);
    } catch (e) {
      throw Exception('Không thể xóa ảnh: $e');
    }
  }
}
