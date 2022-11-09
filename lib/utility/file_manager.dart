import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

class FileManager {
  static const String _fn = 'list_';
  static const String _index = 'info';
  static const String _ext = '.json';

  static Future<String> get _localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<File> _getLocalFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  // Write to file
  static Future<File> writeIndicies(List<int> indicies) async {
    final file = await _getLocalFile(_index);
    return file.writeAsString(indicies.toString());
  }

  static Future<File> writeFile(Map<String, dynamic> json, int id) async {
    final file = await _getLocalFile('$_fn$id$_ext');
    return file.writeAsString(jsonEncode(json));
  }

  // Read from file
  static Future<String?> readIndicies() async {
    try {
      final file = await _getLocalFile(_index);
      return await file.readAsString();
    } catch (e) { return null; }
  }

  static Future<String?> readFile(int id) async {
    try {
      final file = await _getLocalFile('$_fn$id$_ext');
      return await file.readAsString();
    } catch (e) { return null; }
  }

  // Delete file
  static Future<int?> deleteFile(int id) async {
    try {
      final file = await _getLocalFile('$_fn$id$_ext');
      await file.delete();
      return 0;
    } catch (e) { return -1; }
  }
}