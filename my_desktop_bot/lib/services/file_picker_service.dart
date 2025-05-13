import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// שירות לבחירת קבצים ותמונות
class FilePickerService {
  /// בחירת תמונה מהמכשיר
  Future<FileResult?> pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final bytes = await file.readAsBytes();

        return FileResult(
          path: result.files.first.path!,
          name: result.files.first.name,
          bytes: bytes,
          type: FileResultType.image,
        );
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// בחירת קובץ מהמכשיר
  Future<FileResult?> pickFile({List<String>? allowedExtensions}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final bytes = await file.readAsBytes();

        FileResultType type;
        final extension = result.files.first.extension?.toLowerCase() ?? '';

        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension)) {
          type = FileResultType.image;
        } else if (['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(extension)) {
          type = FileResultType.audio;
        } else if (['mp4', 'avi', 'mov', 'mkv', 'webm'].contains(extension)) {
          type = FileResultType.video;
        } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(extension)) {
          type = FileResultType.document;
        } else {
          type = FileResultType.other;
        }

        return FileResult(
          path: result.files.first.path!,
          name: result.files.first.name,
          bytes: bytes,
          type: type,
        );
      }
      return null;
    } catch (e) {
      print('Error picking file: $e');
      return null;
    }
  }

  /// שמירת תמונה או קובץ באופן זמני
  Future<String> saveTempFile(Uint8List bytes, String extension) async {
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'temp_file_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }
}

/// סוג הקובץ שנבחר
enum FileResultType { image, audio, video, document, other }

/// מידע על הקובץ שנבחר
class FileResult {
  final String path;
  final String name;
  final Uint8List bytes;
  final FileResultType type;

  FileResult({
    required this.path,
    required this.name,
    required this.bytes,
    required this.type,
  });
}
