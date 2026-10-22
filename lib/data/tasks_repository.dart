import 'dart:convert';

import 'preferences.dart';

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    this.timeLabel,
    this.isCompleted = false,
    required this.createdAt,
    this.sortOrder = 0,
  });

  final int id;
  final String title;
  final String? timeLabel;
  final bool isCompleted;
  final int createdAt;
  final int sortOrder;

  TaskItem copyWith({
    int? id,
    String? title,
    String? timeLabel,
    bool? isCompleted,
    int? createdAt,
    int? sortOrder,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      timeLabel: timeLabel ?? this.timeLabel,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timeLabel': timeLabel,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
        'sortOrder': sortOrder,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        timeLabel: json['timeLabel'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class TasksRepository {
  TasksRepository(this.preferencesRepository);

  final PreferencesRepository preferencesRepository;

  List<TaskItem> load() {
    final raw = preferencesRepository.tasksJson();
    if (raw.isEmpty) return <TaskItem>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <TaskItem>[];
      return decoded
          .map((entry) => TaskItem.fromJson((entry as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return <TaskItem>[];
    }
  }

  Future<void> save(List<TaskItem> tasks) async {
    await preferencesRepository.setTasksJson(
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }

  Future<void> add(String title, String? timeLabel) async {
    final clean = title.trim();
    if (clean.isEmpty) return;
    final tasks = load();
    final nextId = tasks.isEmpty
        ? 1
        : tasks.map((task) => task.id).reduce((a, b) => a > b ? a : b) + 1;
    tasks.add(
      TaskItem(
        id: nextId,
        title: clean,
        timeLabel: timeLabel?.trim().isEmpty ?? true ? null : timeLabel!.trim(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        sortOrder: tasks.length,
      ),
    );
    await save(tasks);
  }

  Future<void> toggle(TaskItem task) async {
    final tasks = load();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    await save(tasks);
  }

  Future<void> delete(TaskItem task) async {
    final tasks = load()..removeWhere((item) => item.id == task.id);
    await save(tasks);
  }

  Future<void> edit(TaskItem task, String title, String? timeLabel) async {
    final clean = title.trim();
    if (clean.isEmpty) return;
    final tasks = load();
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    tasks[index] = task.copyWith(
      title: clean,
      timeLabel: timeLabel?.trim().isEmpty ?? true ? null : timeLabel!.trim(),
    );
    await save(tasks);
  }

  Future<void> clearAll() async {
    await save(<TaskItem>[]);
  }

  Future<void> seedDefaults() async {
    if (load().isNotEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final defaults = <TaskItem>[
      const TaskItem(
        id: 1,
        title: 'قراءة ٥ صفحات من القرآن',
        timeLabel: 'بعد الفجر',
        createdAt: 0,
        sortOrder: 0,
      ),
      const TaskItem(
        id: 2,
        title: 'مراجعة مادة البرمجة',
        timeLabel: '١٠:٠٠',
        createdAt: 0,
        sortOrder: 1,
      ),
      const TaskItem(
        id: 3,
        title: 'ممارسة الرياضة',
        timeLabel: '١٦:٠٠',
        createdAt: 0,
        sortOrder: 2,
      ),
      const TaskItem(
        id: 4,
        title: 'مراجعة ملاحظات اليوم',
        timeLabel: '٢٠:٠٠',
        createdAt: 0,
        sortOrder: 3,
      ),
      const TaskItem(
        id: 5,
        title: 'النوم مبكرًا',
        timeLabel: '٢٢:٣٠',
        createdAt: 0,
        sortOrder: 4,
      ),
    ];
    await save(defaults
        .map((task) => task.copyWith(createdAt: now))
        .toList());
  }
}
