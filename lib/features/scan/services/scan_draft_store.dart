import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_draft.dart';

class ScanDraftStore {
  ScanDraftStore({String accountKey = 'signed-out'})
    : _namespace = base64Url
          .encode(utf8.encode(accountKey))
          .replaceAll('=', '');

  final String _namespace;
  Future<void> _writes = Future<void>.value();
  String get _draftsKey => 'ey_mobile_scan_drafts_$_namespace';

  Future<List<ScanDraft>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftsKey);
    if (raw == null || raw.isEmpty) {
      return const <ScanDraft>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <ScanDraft>[];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ScanDraft.fromJson)
          .toList();
    } catch (_) {
      return const <ScanDraft>[];
    }
  }

  Future<void> saveDrafts(List<ScanDraft> drafts) {
    final payload = jsonEncode(drafts.map((draft) => draft.toJson()).toList());
    final write = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_draftsKey, payload)) {
        throw const FileSystemException('Draft storage failed');
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  Future<String> persistImportedImage(XFile source) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final scanDir = Directory(
      p.join(documentsDir.path, 'scan_images', _namespace),
    );
    if (!await scanDir.exists()) {
      await scanDir.create(recursive: true);
    }

    final extension = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path);
    final fileName =
        'scan_${DateTime.now().millisecondsSinceEpoch}${extension.toLowerCase()}';
    final target = File(p.join(scanDir.path, fileName));
    final bytes = await source.readAsBytes();
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<void> deleteImage(String path) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final root = p.join(documentsDir.path, 'scan_images', _namespace);
    if (!p.isWithin(root, p.normalize(p.absolute(path)))) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
