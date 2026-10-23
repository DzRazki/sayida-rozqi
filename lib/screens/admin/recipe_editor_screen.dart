import 'package:flutter/material.dart';
import '../../models/recipe.dart';
import '../../services/supabase_service.dart';

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? recipe;
  const RecipeEditorScreen({super.key, this.recipe});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController category;
  late final TextEditingController description;
  late final TextEditingController image;
  late final TextEditingController youtube;
  late final TextEditingController time;
  late final TextEditingController servings;
  late final TextEditingController ingredients;
  late final TextEditingController steps;
  bool featured = false;
  bool published = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    name = TextEditingController(text: recipe?.name ?? '');
    category = TextEditingController(text: recipe?.category ?? 'أطباق تقليدية');
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

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    await SupabaseService.saveRecipe({
      'name': name.text.trim(),
      'category': category.text.trim(),
      'description': description.text.trim(),
      'emoji': '🍽️',
      'image_url': image.text.trim(),
      'youtube_url': youtube.text.trim(),
      'time': int.tryParse(time.text) ?? 30,
      'servings': int.tryParse(servings.text) ?? 4,
      'ingredients': ingredients.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'steps': steps.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'featured': featured,
      'published': published,
    }, id: widget.recipe?.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe == null ? 'وصفة جديدة' : 'تعديل الوصفة')),
      body: Form(
        key: form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: name, decoration: const InputDecoration(hintText: 'اسم الوصفة'), validator: (v) => v!.isEmpty ? 'أدخلي الاسم' : null),
          TextFormField(controller: category, decoration: const InputDecoration(hintText: 'التصنيف'), validator: (v) => v!.isEmpty ? 'أدخلي التصنيف' : null),
          TextFormField(controller: description, maxLines: 3, decoration: const InputDecoration(hintText: 'وصف مختصر')),
          TextFormField(controller: image, decoration: const InputDecoration(hintText: 'رابط صورة الطبق')),
          TextFormField(controller: youtube, decoration: const InputDecoration(hintText: 'رابط يوتيوب')),
          Row(children: [Expanded(child: TextFormField(controller: time, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'المدة'))), const SizedBox(width: 10), Expanded(child: TextFormField(controller: servings, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'عدد الأشخاص')))]),
          TextFormField(controller: ingredients, maxLines: 5, decoration: const InputDecoration(hintText: 'المكونات، كل مكوّن في سطر')),
          TextFormField(controller: steps, maxLines: 6, decoration: const InputDecoration(hintText: 'الخطوات، كل خطوة في سطر')),
          SwitchListTile(value: featured, onChanged: (v) => setState(() => featured = v), title: const Text('وصفة مميزة')),
          SwitchListTile(value: published, onChanged: (v) => setState(() => published = v), title: const Text('نشر الوصفة')),
          const SizedBox(height: 16),
          FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'جارٍ الحفظ...' : 'حفظ الوصفة')),
        ]),
      ),
    );
  }
}
