import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../theme.dart';
import 'recipe_card.dart';

class PagedRecipes extends StatefulWidget {
  final List<Recipe> recipes;
  const PagedRecipes({super.key, required this.recipes});
  @override
  State<PagedRecipes> createState() => _PagedRecipesState();
}
class _PagedRecipesState extends State<PagedRecipes> {
  int page = 1;
  final anchor = GlobalKey();
  @override
  void didUpdateWidget(covariant PagedRecipes oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pages = (widget.recipes.length / 10).ceil();
    if (page > pages) page = pages < 1 ? 1 : pages;
  }
  void go(int target, int pages) {
    if (target < 1 || target > pages || target == page) return;
    setState(() => page = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = anchor.currentContext;
      if (mounted && context != null) {
        Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 300), alignment: 0.05);
      }
    });
  }
  Widget button(String text, String label, VoidCallback? onTap, {bool selected = false}) => Semantics(
    button: true, selected: selected, label: label,
    child: SizedBox(width: 42, height: 42, child: Material(
      color: selected ? AppColors.gold : AppColors.darkBrown,
      borderRadius: BorderRadius.circular(7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Center(child: Text(text, style: TextStyle(
        color: selected ? AppColors.darkBrown : Colors.white,
        fontWeight: FontWeight.bold, fontSize: 15,
      )))),
    )),
  );
  @override
  Widget build(BuildContext context) {
    final pages = (widget.recipes.length / 10).ceil();
    final visible = widget.recipes.skip((page - 1) * 10).take(10).toList();
    final numbers = <int>{1, pages};
    for (int number = page - 1; number <= page + 1; number++) {
      if (number >= 1 && number <= pages) numbers.add(number);
    }
    if (page <= 3) {
      for (int number = 1; number <= 4 && number <= pages; number++) { numbers.add(number); }
    }
    if (page >= pages - 2) {
      for (int number = pages - 3; number <= pages; number++) { if (number > 0) numbers.add(number); }
    }
    final sorted = numbers.where((number) => number > 0).toList()..sort();
    final controls = <Widget>[];
    if (page > 1) controls.add(button('‹', 'الصفحة السابقة', () => go(page - 1, pages)));
    for (int index = 0; index < sorted.length; index++) {
      final number = sorted[index];
      if (index > 0 && number - sorted[index - 1] > 1) controls.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('…')));
      controls.add(button('$number', 'الصفحة $number', () => go(number, pages), selected: number == page));
    }
    if (page < pages) controls.add(button('›', 'الصفحة التالية', () => go(page + 1, pages)));
    return Column(key: anchor, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
        return Wrap(spacing: 14, runSpacing: 14, children: visible.map((recipe) => SizedBox(
          width: width, child: RecipeCard(key: ValueKey(recipe.id), recipe: recipe),
        )).toList());
      }),
      if (pages > 1) ...[
        const SizedBox(height: 12),
        Directionality(textDirection: TextDirection.ltr, child: Wrap(
          alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6, runSpacing: 6, children: controls,
        )),
        const SizedBox(height: 8),
        Text('الصفحة $page من $pages', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.darkBrown, fontSize: 12)),
      ],
    ]);
  }
}
