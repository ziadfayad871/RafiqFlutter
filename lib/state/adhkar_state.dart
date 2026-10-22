import 'package:flutter/foundation.dart';

import '../data/repositories.dart';

class AdhkarState extends ChangeNotifier {
  AdhkarState({AdhkarRepository? repository})
    : _repository = repository ?? AdhkarRepository();

  final AdhkarRepository _repository;

  bool isLoading = true;
  String? error;
  AdhkarData? data;
  String? selectedCategoryId;
  Map<String, int> progress = <String, int>{};

  List<AdhkarCategory> get categories =>
      data?.categories ?? const <AdhkarCategory>[];

  AdhkarCategory? get selectedCategory {
    final categoryId = selectedCategoryId;
    if (categoryId == null) return null;
    for (final category in categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  int countFor(AdhkarItem item) => progress[item.id] ?? 0;

  int completedIn(AdhkarCategory category) =>
      category.items.where((item) => countFor(item) >= item.count).length;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final loaded = await _repository.load();
      data = loaded;
      isLoading = false;
    } catch (_) {
      isLoading = false;
      error = 'تعذّر تحميل الأذكار من ملفات التطبيق';
    }
    notifyListeners();
  }

  void retry() {
    load();
  }

  void openCategory(String categoryId) {
    selectedCategoryId = categoryId;
    notifyListeners();
  }

  void closeCategory() {
    selectedCategoryId = null;
    notifyListeners();
  }

  void openCategoryByTitle(String title) {
    for (final category in categories) {
      if (category.title == title) {
        openCategory(category.id);
        return;
      }
    }
  }

  void increment(AdhkarItem item) {
    final current = countFor(item);
    progress = <String, int>{
      ...progress,
      item.id: current >= item.count ? 0 : current + 1,
    };
    notifyListeners();
  }

  void resetItem(AdhkarItem item) {
    if (!progress.containsKey(item.id)) return;
    final updated = Map<String, int>.from(progress)..remove(item.id);
    progress = updated;
    notifyListeners();
  }

  void resetCategory(AdhkarCategory category) {
    final updated = Map<String, int>.from(progress);
    for (final item in category.items) {
      updated.remove(item.id);
    }
    progress = updated;
    notifyListeners();
  }
}
