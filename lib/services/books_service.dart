import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class BooksService {
  static SupabaseClient get _client => SupabaseService.client;
  static const bucket = 'book-pdfs';

  static Future<List<Map<String, dynamic>>> fetch({bool admin = false}) async {
    if (admin) _requireAdmin();
    var query = _client.from('books').select();
    if (!admin) query = query.eq('published', true);
    final rows = await query.order('sort_order').order('created_at', ascending: false);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static void _requireUser() {
    if (_client.auth.currentUser == null) {
      throw StateError('سجّلي الدخول لقراءة الكتاب أو تحميله');
    }
  }

  static void _requireAdmin() {
    _requireUser();
    if (!SupabaseService.isAdmin()) throw StateError('هذه العملية للإدارة فقط');
  }

  static Future<Uint8List> pdf(String path) async {
    _requireUser();
    final bytes = await _client.storage.from(bucket).download(path);
    _checkPdf(bytes);
    return bytes;
  }

  static void _checkPdf(Uint8List bytes) {
    if (bytes.length < 5 || String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const FormatException('الملف ليس PDF صالحًا');
    }
    if (bytes.length > 104857600) throw StateError('حجم الكتاب أكبر من 100 ميغابايت');
  }

  // Call only after the reader loads the PDF or the destination file is saved.
  static Future<void> recordSuccess(String bookId, {required bool download}) async {
    _requireUser();
    await _client.rpc('record_book_event', params: {
      'p_book_id': bookId, 'p_event_type': download ? 'download' : 'view',
    });
  }

  static Future<Map<String, int>> stats(String bookId) async {
    final result = await _client.rpc('get_book_stats', params: {'p_book_id': bookId});
    final rows = result as List;
    if (rows.isEmpty) return {'views': 0, 'downloads': 0};
    final row = Map<String, dynamic>.from(rows.first as Map);
    return {
      'views': (row['views'] as num?)?.toInt() ?? 0,
      'downloads': (row['downloads'] as num?)?.toInt() ?? 0,
    };
  }

  static Future<Map<String, int>> adminStats(String bookId) async {
    _requireAdmin();
    var views = 0;
    var downloads = 0;
    var offset = 0;
    while (true) {
      final rows = await _client.from('book_events').select('event_type')
          .eq('book_id', bookId).order('created_at').order('id').range(offset, offset + 199);
      for (final row in rows) {
        if (row['event_type'] == 'view') views++;
        if (row['event_type'] == 'download') downloads++;
      }
      if (rows.length < 200) break;
      offset += rows.length;
    }
    return {'views': views, 'downloads': downloads};
  }

  static Future<String> uploadPdf(Uint8List bytes) async {
    _requireAdmin();
    _checkPdf(bytes);
    final path = '${_client.auth.currentUser!.id}/${DateTime.now().microsecondsSinceEpoch}.pdf';
    await _client.storage.from(bucket).uploadBinary(path, bytes,
      fileOptions: const FileOptions(contentType: 'application/pdf', upsert: false));
    return path;
  }

  static Future<void> save({String? id, required String title,
    required String description, required String coverUrl, required String pdfPath,
    required bool published, required bool featured, required int sortOrder}) async {
    _requireAdmin();
    if (title.trim().isEmpty || pdfPath.trim().isEmpty) {
      throw ArgumentError('أدخلي عنوان الكتاب وارفعي ملف PDF');
    }
    final cover = Uri.tryParse(coverUrl.trim());
    if (coverUrl.trim().isNotEmpty &&
        (cover == null || cover.scheme != 'https' || cover.host.isEmpty)) {
      throw ArgumentError('رابط الغلاف يجب أن يبدأ بـ https');
    }
    final values = {
      'title': title.trim(), 'description': description.trim(),
      'cover_url': coverUrl.trim(), 'pdf_path': pdfPath.trim(),
      'published': published, 'featured': featured, 'sort_order': sortOrder,
    };
    if (id == null) {
      await _client.from('books').insert(values);
    } else {
      await _client.from('books').update(values).eq('id', id);
    }
  }

  static Future<void> delete(String id) async {
    _requireAdmin();
    await _client.from('books').delete().eq('id', id);
  }

  static Future<void> removePdf(String path) async {
    _requireAdmin();
    await _client.storage.from(bucket).remove([path]);
  }
}
