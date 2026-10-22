import 'package:flutter/foundation.dart';

import '../data/tasks_repository.dart';

class TasksState extends ChangeNotifier {
  TasksState({required this.repository});

  final TasksRepository repository;

  List<TaskItem> tasks = <TaskItem>[];
  String? message;

  int get completedCount => tasks.where((task) => task.isCompleted).length;

  void load() {
    tasks = _sorted(repository.load());
    notifyListeners();
  }

  Future<void> add(String title, String? timeLabel) async {
    if (title.trim().isEmpty) return;
    await repository.add(title, timeLabel);
    message = 'أُضيفت المهمة';
    load();
  }

  Future<void> addFromAssistant(String title, String? timeLabel) async {
    if (title.trim().isEmpty) return;
    await repository.add(title, timeLabel);
    load();
  }

  Future<void> toggle(TaskItem task) async {
    await repository.toggle(task);
    load();
  }

  Future<void> edit(TaskItem task, String title, String? timeLabel) async {
    await repository.edit(task, title, timeLabel);
    load();
  }

  Future<void> delete(TaskItem task) async {
    await repository.delete(task);
    message = 'حُذفت المهمة';
    load();
  }

  Future<void> clearAll() async {
    await repository.clearAll();
    load();
  }

  Future<void> seedDefaults() async {
    await repository.seedDefaults();
    load();
  }

  void consumeMessage() {
    if (message == null) return;
    message = null;
    notifyListeners();
  }

  List<TaskItem> _sorted(List<TaskItem> items) {
    final sorted = List<TaskItem>.from(items);
    sorted.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted;
  }
}
