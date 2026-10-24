import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/supabase_service.dart';
import '../../theme.dart';
import '../categories_screen.dart' show categoryPhotos;

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipe;
  const RecipeEditorScreen({super.key, this.recipe});
  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}
class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, description, image, youtube, time, servings, ingredients, steps;
  late final List<String> categories;
  String? selectedCategory;
  bool featured = false, published = false, saving = false;
  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    categories = categoryPhotos.keys.toList();
    final existing = recipe?.category.trim();
    if (existing != null && existing.isNotEmpty) {
      if (!categories.contains(existing)) categories.add(existing);
      selectedCategory = existing;
    }
    name = TextEditingController(text: recipe?.name ?? '');
    description = TextEditingController(text: recipe?.description ?? '');
    image = TextEditingController(text: recipe?.imageUrl ?? '');
    youtube = TextEditingController(text: recipe?.youtubeUrl ?? '');
    time = TextEditingController(text: (recipe?.time ?? 30).toString());
    servings = TextEditingController(text: (recipe?.servings ?? 4).toString());
    ingredients = TextEditingController(text: (recipe?.ingredients ?? []).join('\n'));
    steps = TextEditingController(text: (recipe?.steps ?? []).join('\n'));
    featured = recipe?.featured ?? false;
    published = recipe?.published ?? false;
  }
  @override
  void dispose() {
    for (final controller in [name, description, image, youtube, time, servings, ingredients, steps]) { controller.dispose(); }
    super.dispose();
  }
  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await SupabaseService.saveRecipe({
        'name': name.text.trim(), 'category': selectedCategory!,
        'description': description.text.trim(), 'emoji': '🍽️',
        'image_url': image.text.trim(), 'youtube_url': youtube.text.trim(),
        'time': int.tryParse(time.text) ?? 30, 'servings': int.tryParse(servings.text) ?? 4,
        'ingredients': ingredients.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'steps': steps.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'featured': featured, 'published': published,
      }, id: widget.recipe?.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر حفظ الوصفة. تحققي من الاتصال وحاولي مجددًا.')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  Widget field(TextEditingController controller, String hint, {int lines = 1, bool number = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(controller: controller, maxLines: lines, keyboardType: number ? TextInputType.number : null, decoration: InputDecoration(hintText: hint)),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(title: Text(widget.recipe == null ? 'وصفة جديدة' : 'تعديل الوصفة')),
    body: Form(key: form, child: ListView(padding: const EdgeInsets.all(18), children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 8))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('بيانات الوصفة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.darkBrown)),
          const SizedBox(height: 16),
          TextFormField(controller: name, decoration: const InputDecoration(hintText: 'اسم الوصفة'), validator: (value) => value == null || value.trim().isEmpty ? 'أدخلي الاسم' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'التصنيف / الفئة', hintText: 'اختاري التصنيف'),
            items: categories.map((name) => DropdownMenuItem<String>(value: name, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: saving ? null : (value) => setState(() => selectedCategory = value),
            validator: (value) => value == null || value.isEmpty ? 'اختاري تصنيف الوصفة' : null,
          ),
          const SizedBox(height: 12),
          field(description, 'وصف مختصر', lines: 3),
          field(image, 'رابط صورة الطبق'),
          field(youtube, 'رابط يوتيوب'),
          Row(children: [Expanded(child: field(time, 'المدة', number: true)), const SizedBox(width: 12), Expanded(child: field(servings, 'عدد الأشخاص', number: true))]),
          field(ingredients, 'المكونات، كل مكوّن في سطر', lines: 5),
          field(steps, 'الخطوات، كل خطوة في سطر', lines: 6),
          SwitchListTile(value: featured, onChanged: (value) => setState(() => featured = value), title: const Text('وصفة مميزة')),
          SwitchListTile(value: published, onChanged: (value) => setState(() => published = value), title: const Text('نشر الوصفة')),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: saving ? null : save,
            style: FilledButton.styleFrom(backgroundColor: AppColors.darkBrown, foregroundColor: AppColors.gold, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            icon: const Icon(Icons.save), label: Text(saving ? 'جارٍ الحفظ...' : 'حفظ الوصفة'),
          )),
        ]),
      ),
    ])),
  );
}
