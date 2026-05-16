import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kickr/core/constants/app_constants.dart';
import 'package:kickr/core/constants/storage_constants.dart';

class CvPickResult {
  const CvPickResult({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class AvatarPickResult {
  const AvatarPickResult({
    required this.bytes,
    required this.extension,
  });

  final Uint8List bytes;
  final String extension;
}

class StorageService {
  const StorageService(this._supabase);

  final SupabaseClient _supabase;

  /// Returns null if the user cancelled the picker.
  Future<CvPickResult?> pickCvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception('Could not read file. Please try again.');
    }

    if (bytes.lengthInBytes > AppConstants.cvMaxBytes) {
      throw Exception('File too large. Maximum size is 5 MB.');
    }

    return CvPickResult(bytes: bytes, fileName: file.name);
  }

  /// Uploads bytes to [StorageConstants.cvBucket] at the path from
  /// [StorageConstants.cvPath] and returns the public URL.
  /// Passing upsert: true replaces any file at the same path.
  Future<String> uploadCv({
    required String userId,
    required Uint8List bytes,
  }) async {
    final path = StorageConstants.cvPath(userId);

    await _supabase.storage.from(StorageConstants.cvBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    return _supabase.storage
        .from(StorageConstants.cvBucket)
        .getPublicUrl(path);
  }

  /// Returns null if the user cancelled the picker.
  Future<AvatarPickResult?> pickAvatarFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception('Could not read image. Please try again.');
    }

    if (bytes.lengthInBytes > AppConstants.avatarMaxBytes) {
      throw Exception('Image too large. Maximum size is 2 MB.');
    }

    final ext = (file.extension ?? 'jpg').toLowerCase();
    return AvatarPickResult(bytes: bytes, extension: ext);
  }

  /// Uploads avatar bytes to [StorageConstants.avatarBucket] using a fixed
  /// path (upsert) so each upload replaces the previous file.
  /// Returns the public URL.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = StorageConstants.avatarPath(userId, extension);
    final contentType = _avatarContentType(extension);

    await _supabase.storage.from(StorageConstants.avatarBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _supabase.storage
        .from(StorageConstants.avatarBucket)
        .getPublicUrl(path);
  }

  String _avatarContentType(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
}
