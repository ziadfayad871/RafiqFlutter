import 'dart:async';

import 'package:flutter/material.dart';

import '../data/tasks_repository.dart';
import '../state/app_state.dart';
import '../state/tasks_state.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';
import '../util/arabic_formatters.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final TasksState _state;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    _state = TasksState(repository: TasksRepository(app.preferencesRepository));
    _bootstrap(app);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _bootstrap(AppState app) async {
    if (!app.preferences.tasksSeeded) {
      await _state.seedDefaults();
      await app.setTasksSeeded();
      return;
    }
    _state.load();
  }

  void _click() {
    AppScope.read(context).click();
  }

  void _openNewTask() {
    _click();
    _openEditor(null);
  }

  void _openEditTask(TaskItem task) {
    _click();
    _openEditor(task);
  }

  void _openEditor(TaskItem? task) {
    final palette = RafiqThemeScope.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _TaskEditorDialog(
          palette: palette,
          task: task,
          onDismiss: () => Navigator.of(dialogContext).pop(),
          onSave: (title, time) {
            Navigator.of(dialogContext).pop();
            if (task == null) {
              _state.add(title, time);
            } else {
              _state.edit(task, title, time);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          final tasks = _state.tasks;
          final completed = _state.completedCount;
          return Stack(
            children: [
              Column(
                children: [
                  RafiqTopBar(
                    title: 'مهام اليوم',
                    subtitle: formatGregorianDate(DateTime.now()),
                    onBack: widget.onBack,
                    actions: [
                      RoundIconButton(
                        icon: RafiqIcons.plus,
                        size: 38,
                        onTap: _openNewTask,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          if (tasks.isNotEmpty) ...[
                            Text(
                              'أنجزت $completed من ${tasks.length}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: palette.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            _ProgressBar(value: completed / tasks.length),
                            const SizedBox(height: 14),
                          ],
                          if (tasks.isEmpty)
                            _EmptyState(
                              icon: RafiqIcons.tasks,
                              title: 'لا مهام بعد',
                              body: 'أضف مهامك اليومية ونظّم يومك بهدوء.',
                              action: _RafiqPrimaryButton(
                                text: 'إضافة مهمة',
                                icon: RafiqIcons.plus,
                                onTap: _openNewTask,
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: tasks.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
                                  return _TaskRow(
                                    task: task,
                                    onToggle: () {
                                      _click();
                                      _state.toggle(task);
                                    },
                                    onEdit: () => _openEditTask(task),
                                    onDelete: () {
                                      _click();
                                      _state.delete(task);
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 20,
                bottom: 20,
                child: _FloatingGoldButton(onTap: _openNewTask),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 90,
                child: _TransientMessage(
                  message: _state.message,
                  onConsumed: _state.consumeMessage,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final done = task.isCompleted;
    return RafiqCard(
      contentPadding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Material(
            color: done
                ? palette.gold.withValues(alpha: 0.18)
                : palette.surfaceHigh,
            shape: CircleBorder(
              side: BorderSide(color: done ? palette.gold : palette.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onToggle,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: done
                      ? RafiqIcon(
                          RafiqIcons.check,
                          size: 16,
                          color: palette.goldBright,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: done ? palette.textDim : palette.textPrimary,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (task.timeLabel != null)
                  Text(
                    task.timeLabel!,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: palette.goldMuted),
                  ),
              ],
            ),
          ),
          RoundIconButton(
            icon: RafiqIcons.edit,
            size: 32,
            tint: palette.textDim,
            onTap: onEdit,
          ),
          const SizedBox(width: 4),
          RoundIconButton(
            icon: RafiqIcons.trash,
            size: 32,
            tint: palette.danger,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return SizedBox(
      height: 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: palette.borderSoft.withValues(alpha: 0.5)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [palette.goldMuted, palette.goldBright],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final RafiqIconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface.withValues(alpha: 0.7),
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: RafiqIcon(icon, size: 34, color: palette.gold),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    );
  }
}

class _FloatingGoldButton extends StatelessWidget {
  const _FloatingGoldButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.38, -0.52),
              radius: 1.24,
              colors: [palette.goldBright, palette.gold, palette.goldMuted],
            ),
          ),
          child: Center(
            child: RafiqIcon(
              RafiqIcons.plus,
              size: 24,
              color: palette.backgroundDeep,
            ),
          ),
        ),
      ),
    );
  }
}

class _RafiqPrimaryButton extends StatelessWidget {
  const _RafiqPrimaryButton({
    required this.text,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String text;
  final VoidCallback onTap;
  final RafiqIconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: LinearGradient(
              colors: enabled
                  ? [palette.goldBright, palette.gold, palette.goldMuted]
                  : [palette.surfaceHigh, palette.surfaceHigh],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 19, color: palette.backgroundDeep),
                const SizedBox(width: 9),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette.backgroundDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransientMessage extends StatefulWidget {
  const _TransientMessage({required this.message, required this.onConsumed});

  final String? message;
  final VoidCallback onConsumed;

  @override
  State<_TransientMessage> createState() => _TransientMessageState();
}

class _TransientMessageState extends State<_TransientMessage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _TransientMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _schedule();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.message == null) return;
    _timer = Timer(const Duration(milliseconds: 2600), widget.onConsumed);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    if (message == null) return const SizedBox.shrink();
    final palette = RafiqThemeScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: palette.surfaceHigh.withValues(alpha: 0.97),
          border: Border.all(color: palette.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
        ),
      ),
    );
  }
}

class _TaskEditorDialog extends StatefulWidget {
  const _TaskEditorDialog({
    required this.palette,
    required this.task,
    required this.onDismiss,
    required this.onSave,
  });

  final RafiqPalette palette;
  final TaskItem? task;
  final VoidCallback onDismiss;
  final void Function(String title, String? time) onSave;

  @override
  State<_TaskEditorDialog> createState() => _TaskEditorDialogState();
}

class _TaskEditorDialogState extends State<_TaskEditorDialog> {
  late String _title = widget.task?.title ?? '';
  late String _time = widget.task?.timeLabel ?? '';

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final editing = widget.task != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: const RoundedRectangleBorder(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.surfaceHigh, palette.backgroundSecondary],
          ),
          border: Border.all(color: palette.border),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing ? 'تعديل المهمة' : 'مهمة جديدة',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: palette.gold),
                  ),
                ),
                RoundIconButton(
                  icon: RafiqIcons.close,
                  size: 34,
                  onTap: widget.onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FieldLabel(palette: palette, text: 'عنوان المهمة'),
            _DialogField(
              palette: palette,
              value: _title,
              placeholder: 'مثال: مراجعة الدرس',
              onChanged: (value) => setState(() => _title = value),
            ),
            const SizedBox(height: 12),
            _FieldLabel(palette: palette, text: 'الوقت (اختياري)'),
            _DialogField(
              palette: palette,
              value: _time,
              placeholder: 'مثال: 10:00 أو بعد الفجر',
              onChanged: (value) => setState(() => _time = value),
            ),
            const SizedBox(height: 18),
            _RafiqPrimaryButton(
              text: editing ? 'حفظ التعديل' : 'إضافة',
              icon: RafiqIcons.check,
              enabled: _title.trim().isNotEmpty,
              onTap: () =>
                  widget.onSave(_title, _time.trim().isEmpty ? null : _time),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.palette, required this.text});

  final RafiqPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: palette.textDim),
      ),
    );
  }
}

class _DialogField extends StatefulWidget {
  const _DialogField({
    required this.palette,
    required this.value,
    required this.placeholder,
    required this.onChanged,
  });

  final RafiqPalette palette;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  State<_DialogField> createState() => _DialogFieldState();
}

class _DialogFieldState extends State<_DialogField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: palette.surface.withValues(alpha: 0.7),
        border: Border.all(color: palette.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SizedBox(
        height: 23,
        child: Stack(
          children: [
            if (widget.value.isEmpty)
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    widget.placeholder,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.textDim),
                  ),
                ),
              ),
            Positioned.fill(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                maxLines: 1,
                textAlignVertical: TextAlignVertical.center,
                cursorColor: palette.gold,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
