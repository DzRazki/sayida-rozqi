import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import '../services/books_service.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import 'user_auth_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}
class _BooksScreenState extends State<BooksScreen> {
  List<Map<String, dynamic>> books = [];
  bool loading = true, busy = false;
  String? error;
  @override
  void initState() { super.initState(); load(); }
  void message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await BooksService.fetch();
      if (mounted) setState(() => books = data);
    } catch (_) { if (mounted) setState(() => error = 'تعذر تحميل الكتب. حاولي مجددًا.'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  Future<void> openBook(Map<String, dynamic> book, bool download) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (SupabaseService.client.auth.currentUser == null) {
        message('سجّلي الدخول لقراءة الكتاب أو تحميله');
        await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const UserAuthScreen()));
      }
      if (!mounted || SupabaseService.client.auth.currentUser == null) return;
      final bytes = await BooksService.pdf(book['pdf_path'] as String);
      if (!mounted || SupabaseService.client.auth.currentUser == null) return;
      if (download) {
        final destination = await FilePicker.platform.saveFile(
          dialogTitle: 'حفظ الكتاب', fileName: 'book-${book['id']}.pdf',
          type: FileType.custom, allowedExtensions: ['pdf'], bytes: bytes);
        if (destination == null) return;
        message('تم حفظ الكتاب');
        try { await BooksService.recordSuccess(book['id'] as String, download: true); }
        catch (_) { message('حُفظ الكتاب، لكن تعذر تحديث الإحصاء'); }
      } else {
        await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BookReaderScreen(
          bookId: book['id'] as String, title: book['title'] as String, bytes: bytes)));
      }
      if (mounted) setState(() {});
    } catch (_) { message('تعذر فتح الكتاب أو حفظه. تحققي من الاتصال وحاولي مجددًا.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Widget cover(Map<String, dynamic> book) {
    final url = book['cover_url'] as String? ?? '';
    const fallback = Center(child: Icon(Icons.menu_book, size: 64, color: AppColors.gold));
    return AspectRatio(aspectRatio: .72, child: ClipRRect(borderRadius: BorderRadius.circular(12),
      child: url.isEmpty ? fallback : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: const Text('كتب السيدة رزقي'), actions: [
      if (SupabaseService.isAdmin()) IconButton(tooltip: 'إدارة الكتب', icon: const Icon(Icons.edit_note), onPressed: () async {
        await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const BookManagementScreen()));
        if (mounted) load();
      }),
      IconButton(onPressed: busy ? null : load, icon: const Icon(Icons.refresh)),
    ]),
    body: RefreshIndicator(onRefresh: load, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(12), children: [
      Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)),
        child: const Column(children: [Icon(Icons.auto_stories, size: 48, color: AppColors.brown), SizedBox(height: 12),
          Text('كتب السيدة رزقي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
          Text('وصفات تقليدية جزائرية بين يديكِ'), SizedBox(height: 8), Text('سجّلي الدخول للقراءة والتحميل') ])),
      const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Text('أحدث الكتب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      if (busy) const LinearProgressIndicator(),
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      if (error != null) Center(child: Text(error!)),
      if (!loading && error == null && books.isEmpty) const Padding(padding: EdgeInsets.all(28), child: Text('ستظهر الكتب هنا بعد إضافتها ونشرها من الإدارة.', textAlign: TextAlign.center)),
      LayoutBuilder(builder: (context, constraints) {
        final count = constraints.maxWidth >= 480 ? 3 : 2;
        final width = (constraints.maxWidth - (count - 1) * 10) / count;
        return Wrap(spacing: 10, runSpacing: 12, children: books.map((book) => SizedBox(width: width, child: Card(
          margin: EdgeInsets.zero, color: Colors.white, child: Padding(padding: const EdgeInsets.all(10), child: Column(children: [
            cover(book), const SizedBox(height: 10),
            Text(book['title'] as String, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6), Text(book['description'] as String? ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton(onPressed: busy ? null : () => openBook(book, false), child: const Text('قراءة الكتاب')),
            TextButton.icon(onPressed: busy ? null : () => openBook(book, true), icon: const Icon(Icons.download, size: 18), label: const Text('تحميل PDF')),
            FutureBuilder<Map<String, int>>(future: BooksService.stats(book['id'] as String), builder: (context, snapshot) {
              if (!snapshot.hasData) return const Text('الإحصاءات: —', style: TextStyle(fontSize: 11));
              return Text('مشاهدات: ${snapshot.data!['views']} · تحميلات: ${snapshot.data!['downloads']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11));
            }),
          ])),
        ))).toList());
      }),
      const SizedBox(height: 24), const Text('المزيد من الكتب قريبًا...', textAlign: TextAlign.center),
    ])),
  );
}

class BookReaderScreen extends StatefulWidget {
  final String bookId, title;
  final Uint8List bytes;
  const BookReaderScreen({super.key, required this.bookId, required this.title, required this.bytes});
  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}
class _BookReaderScreenState extends State<BookReaderScreen> {
  late final PdfControllerPinch controller;
  bool recorded = false;
  @override
  void initState() { super.initState(); controller = PdfControllerPinch(document: PdfDocument.openData(widget.bytes)); }
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  Future<void> record() async {
    if (recorded) return;
    recorded = true;
    try { await BooksService.recordSuccess(widget.bookId, download: false); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فُتح الكتاب، لكن تعذر تحديث إحصاء المشاهدة'))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.title)),
    body: PdfViewPinch(controller: controller, onDocumentLoaded: (_) { record(); },
      onDocumentError: (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر عرض ملف PDF'))); }));
}

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});
  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}
class _BookManagementScreenState extends State<BookManagementScreen> {
  List<Map<String, dynamic>> books = [];
  bool loading = true;
  String? error;
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    if (!SupabaseService.isAdmin()) return;
    setState(() { loading = true; error = null; });
    try { final rows = await BooksService.fetch(admin: true); if (mounted) setState(() => books = rows); }
    catch (_) { if (mounted) setState(() => error = 'تعذر تحميل كتب الإدارة'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  Future<void> edit([Map<String, dynamic>? book]) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BookEditorScreen(book: book)));
    if (mounted) load();
  }
  Future<void> remove(Map<String, dynamic> book) async {
    final approved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('حذف الكتاب؟'), content: Text('حذف «${book['title']}» وإحصاءاته من الفهرس؟ سيبقى ملف PDF في التخزين للمراجعة.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))]));
    if (approved != true) return;
    try { await BooksService.delete(book['id'] as String); if (mounted) load(); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حذف الكتاب'))); }
  }
  @override
  Widget build(BuildContext context) {
    if (!SupabaseService.isAdmin()) return Scaffold(appBar: AppBar(title: const Text('إدارة الكتب')), body: const Center(child: Text('هذه الصفحة للإدارة فقط')));
    return Scaffold(appBar: AppBar(title: const Text('إدارة الكتب'), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.add), label: const Text('كتاب جديد')),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
        if (error != null) Text(error!),
        if (error == null && books.isEmpty) const Text('لا توجد كتب بعد. أضيفي أول كتاب.'),
        ...books.map((book) => Card(child: ListTile(
          title: Text(book['title'] as String),
          subtitle: FutureBuilder<Map<String, int>>(future: BooksService.adminStats(book['id'] as String), builder: (context, snapshot) => Text(
            '${book['published'] == true ? 'منشور' : 'مسودة'} · مشاهدات: ${snapshot.data?['views'] ?? '—'} · تحميلات: ${snapshot.data?['downloads'] ?? '—'}')),
          onTap: () => edit(book), trailing: IconButton(tooltip: 'حذف الكتاب', onPressed: () => remove(book), icon: const Icon(Icons.delete_outline)),
        ))),
      ]));
  }
}

class BookEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? book;
  const BookEditorScreen({super.key, this.book});
  @override
  State<BookEditorScreen> createState() => _BookEditorScreenState();
}
class _BookEditorScreenState extends State<BookEditorScreen> {
  final title = TextEditingController(), description = TextEditingController(), cover = TextEditingController(), order = TextEditingController();
  String path = '';
  bool published = false, featured = false, busy = false;
  @override
  void initState() {
    super.initState(); final b = widget.book; title.text = b?['title'] as String? ?? '';
    description.text = b?['description'] as String? ?? ''; cover.text = b?['cover_url'] as String? ?? '';
    order.text = '${b?['sort_order'] ?? 0}'; path = b?['pdf_path'] as String? ?? '';
    published = b?['published'] == true; featured = b?['featured'] == true;
  }
  @override
  void dispose() { title.dispose(); description.dispose(); cover.dispose(); order.dispose(); super.dispose(); }
  void message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> upload() async {
    if (busy) return; setState(() => busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result == null) return;
      final bytes = result.files.single.bytes; if (bytes == null) throw StateError('No file data');
      final uploaded = await BooksService.uploadPdf(bytes);
      if (mounted) setState(() => path = uploaded);
      message('رُفع ملف PDF. احفظي الكتاب لربطه به.');
    } catch (_) { message('تعذر رفع الملف. اختاري PDF صالحًا لا يتجاوز 100 ميغابايت.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> save() async {
    if (busy) return;
    final sort = int.tryParse(order.text);
    if (title.text.trim().isEmpty || path.isEmpty || sort == null) { message('أدخلي العنوان وترتيبًا صحيحًا وارفعي PDF'); return; }
    setState(() => busy = true);
    try {
      await BooksService.save(id: widget.book?['id'] as String?, title: title.text, description: description.text,
        coverUrl: cover.text, pdfPath: path, published: published, featured: featured, sortOrder: sort);
      if (mounted) Navigator.pop(context);
    } catch (_) { message('تعذر الحفظ. راجعي رابط الغلاف وصلاحيات الإدارة والاتصال.'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('تحرير الكتاب')), body: ListView(padding: const EdgeInsets.all(18), children: [
    TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان الكتاب')),
    TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'الوصف')),
    TextField(controller: cover, decoration: const InputDecoration(labelText: 'رابط صورة الغلاف https')),
    TextField(controller: order, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ترتيب العرض — الأصغر أولًا')),
    const SizedBox(height: 16), Text(path.isEmpty ? 'لم يُرفع PDF بعد' : 'ملف PDF مرفوع'),
    OutlinedButton.icon(onPressed: busy ? null : upload, icon: const Icon(Icons.upload_file), label: const Text('اختيار ورفع PDF')),
    SwitchListTile(value: published, onChanged: busy ? null : (v) => setState(() => published = v), title: const Text('نشر الكتاب')),
    SwitchListTile(value: featured, onChanged: busy ? null : (v) => setState(() => featured = v), title: const Text('كتاب مميّز')),
    if (busy) const LinearProgressIndicator(),
    FilledButton(onPressed: busy ? null : save, child: const Text('حفظ الكتاب')),
    const Text('الملفات المرفوعة غير المحفوظة والنسخ المستبدلة تبقى في التخزين ولا تُحذف تلقائيًا.', style: TextStyle(fontSize: 12)),
  ]));
}
