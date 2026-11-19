import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_config.dart';

class DocumentAlert {
  const DocumentAlert({
    required this.id,
    required this.transactionId,
    required this.updatedAt,
    required this.kind,
  });
  final String id;
  final String transactionId;
  final DateTime updatedAt;
  final String kind;
  factory DocumentAlert.fromJson(Map<String, dynamic> data) {
    final id = data['id'] as String;
    final transaction = data['transactionId'] as String;
    final kind = data['kind'] as String;
    if (id.isEmpty ||
        !RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(transaction) ||
        !['pending', 'correction', 'reviewed'].contains(kind)) {
      throw const FormatException('Invalid update');
    }
    return DocumentAlert(
      id: id,
      transactionId: transaction,
      updatedAt: DateTime.parse(data['updatedAt'] as String),
      kind: kind,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'updatedAt': updatedAt.toIso8601String(),
    'kind': kind,
  };
}

class DocumentAlertsController extends ChangeNotifier {
  DocumentAlertsController({
    required String account,
    required String? Function() token,
    http.Client? client,
  }) : _key = 'document_alerts_${base64Url.encode(utf8.encode(account))}',
       _token = token,
       _client = client ?? http.Client();
  final String _key;
  final String? Function() _token;
  final http.Client _client;
  final List<DocumentAlert> _items = [];
  final Set<String> _read = {};
  Timer? _timer;
  bool _disposed = false;
  bool _active = true;
  bool busy = false;
  bool failed = false;
  Future<void> _writes = Future.value();
  List<DocumentAlert> get items => List.unmodifiable(_items);
  int get unreadCount =>
      _items.where((item) => !_read.contains(item.id)).length;
  bool isUnread(DocumentAlert alert) => !_read.contains(alert.id);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (_disposed) return;
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _items.addAll(
          (data['items'] as List)
              .take(100)
              .map(
                (e) =>
                    DocumentAlert.fromJson(Map<String, dynamic>.from(e as Map)),
              ),
        );
        _read.addAll((data['read'] as List).whereType<String>());
        notifyListeners();
      }
    } catch (_) {
      _items.clear();
      _read.clear();
    }
    if (!_disposed) await refresh();
  }

  void setActive(bool active) {
    _active = active;
    _timer?.cancel();
    if (active) unawaited(refresh());
  }

  Future<void> refresh() async {
    if (_disposed || busy || !_active) return;
    final token = _token();
    if (token == null || token.isEmpty) return;
    busy = true;
    notifyListeners();
    try {
      http.Response? response;
      for (final uri in ApiConfig.uris('/mobile/document-updates')) {
        try {
          response = await _client
              .get(uri, headers: {'Authorization': 'Bearer $token'})
              .timeout(const Duration(seconds: 15));
          break;
        } on TimeoutException {
          continue;
        } on http.ClientException {
          continue;
        }
      }
      if (_disposed) return;
      if (response == null || response.statusCode != 200) {
        throw const FormatException('Unavailable');
      }
      final rows = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      final next = rows
          .take(100)
          .map(
            (e) => DocumentAlert.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _items
        ..clear()
        ..addAll(next);
      _read.removeWhere((id) => !_items.any((item) => item.id == id));
      failed = false;
      await _save();
    } catch (_) {
      failed = true;
    } finally {
      busy = false;
      if (!_disposed) {
        notifyListeners();
        _timer?.cancel();
        if (_active) _timer = Timer(const Duration(seconds: 30), refresh);
      }
    }
  }

  Future<void> markRead(DocumentAlert item) async {
    if (_disposed) return;
    _read.add(item.id);
    notifyListeners();
    await _save();
  }

  Future<void> markAllRead() async {
    if (_disposed) return;
    _read.addAll(_items.map((item) => item.id));
    notifyListeners();
    await _save();
  }

  Future<void> _save() {
    final payload = jsonEncode({
      'items': _items.map((e) => e.toJson()).toList(),
      'read': _read.toList(),
    });
    final write = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key, payload)) {
        throw const FormatException('Storage unavailable');
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
