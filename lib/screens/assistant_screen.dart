import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/assistant_repository.dart';
import '../data/repositories.dart';
import '../data/tasks_repository.dart';
import '../platform/bridges.dart';
import '../state/app_state.dart';
import '../state/assistant_state.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.onBack,
    required this.onNavigate,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onNavigate;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  AssistantState? _assistant;
  StreamSubscription<String>? _speechSubscription;
  bool _listening = false;
  int _lastItemCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assistant != null) return;
    final appState = AppScope.of(context);
    final prayerScope =
        context.getElementForInheritedWidgetOfExactType<PrayerScope>()?.widget
            as PrayerScope?;
    final prayerState = prayerScope?.notifier;
    final state = AssistantState(
      repository: AssistantRepository(),
      appState: appState,
      tasksRepository: TasksRepository(appState.preferencesRepository),
      quranRepository: QuranRepository(),
      nextPrayerProvider: () => prayerState?.next,
      onNavigate: widget.onNavigate,
    );
    _assistant = state;
    unawaited(state.load());
    _speechSubscription = SpeechBridge.results.listen(
      _onRecognised,
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _speechSubscription?.cancel();
    _speechSubscription = null;
    _assistant?.dispose();
    _assistant = null;
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRecognised(String text) {
    if (!mounted) return;
    _inputController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  void _send(String rawText, {bool clearInput = false}) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    _assistant?.send(text);
    if (clearInput) _inputController.clear();
    setState(() {});
  }

  Future<void> _toggleListening() async {
    try {
      if (_listening) {
        await SpeechBridge.stopListening();
        if (mounted) setState(() => _listening = false);
        return;
      }
      final started = await SpeechBridge.startListening(locale: 'ar');
      if (mounted) setState(() => _listening = started);
    } catch (_) {
      if (mounted) setState(() => _listening = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final state = _assistant;
    if (state == null) {
      return Container(color: Colors.transparent);
    }
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              return RafiqTopBar(
                title: 'مساعد رفيق',
                subtitle: 'إجابات موثوقة من مصادر محفوظة',
                onBack: widget.onBack,
                actions: _buildActions(state, palette),
              );
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: state,
                builder: (context, _) {
                  final messages = state.messages;
                  if (messages.isEmpty) {
                    return _AssistantHero(
                      suggestions: state.suggestions,
                      onSuggestion: _send,
                    );
                  }
                  final itemCount =
                      messages.length + (state.isThinking ? 1 : 0);
                  if (itemCount != _lastItemCount) {
                    _lastItemCount = itemCount;
                    _scrollToEnd();
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= messages.length) {
                        return const _ThinkingIndicator();
                      }
                      final message = messages[index];
                      final isLast =
                          index == messages.length - 1 && !state.isThinking;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                        child: _MessageBubble(
                          message: message,
                          onSpeak: () {
                            try {
                              SpeechBridge.speak(message.text);
                            } catch (_) {}
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _InputBar(
            controller: _inputController,
            listening: _listening,
            onChanged: () => setState(() {}),
            onSend: () => _send(_inputController.text, clearInput: true),
            onMic: _toggleListening,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(AssistantState state, RafiqPalette palette) {
    final actions = <Widget>[];
    if (state.messages.isEmpty) return actions;
    final lastAssistant = state.messages.lastWhere(
      (message) => !message.fromUser,
      orElse: () => state.messages.last,
    );
    actions.add(
      RoundIconButton(
        icon: RafiqIcons.volume,
        size: 38,
        tint: palette.goldMuted,
        onTap: () {
          try {
            SpeechBridge.speak(lastAssistant.text);
          } catch (_) {}
        },
      ),
    );
    actions.add(
      RoundIconButton(
        icon: RafiqIcons.trash,
        size: 38,
        onTap: state.clearConversation,
      ),
    );
    return actions;
  }
}

class _AssistantHero extends StatelessWidget {
  const _AssistantHero({required this.suggestions, required this.onSuggestion});

  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final rows = <List<String>>[];
    for (var index = 0; index < suggestions.length; index += 2) {
      final end = math.min(index + 2, suggestions.length);
      rows.add(suggestions.sublist(index, end));
    }
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _OrnamentRingPainter(
                          palette.gold.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CustomPaint(painter: _RafiqMarkPainter(palette)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'كيف أساعدك اليوم؟',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'أسألني عن الصلاة أو القرآن أو الأذكار، أو اطلب فتح قسم أو إضافة مهمة.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textDim),
                ),
              ),
              const SizedBox(height: 20),
              for (final row in rows) ...[
                Row(
                  children: [
                    for (var index = 0; index < row.length; index++) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: RafiqCard(
                          contentPadding: const EdgeInsets.all(14),
                          onTap: () => onSuggestion(row[index]),
                          child: Text(
                            row[index],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: palette.goldMuted),
                          ),
                        ),
                      ),
                    ],
                    if (row.length == 1) const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onSpeak});

  final ChatMessage message;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final fromUser = message.fromUser;
    final source = message.source;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: fromUser ? 48 : 0,
        end: fromUser ? 0 : 48,
      ),
      child: Align(
        alignment: fromUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: fromUser
                ? palette.gold.withValues(alpha: 0.16)
                : palette.surfaceHigh.withValues(alpha: 0.9),
            border: Border.all(
              color: fromUser
                  ? palette.gold.withValues(alpha: 0.4)
                  : palette.borderSoft,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
              ),
              if (!fromUser && source != null && source.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'المصدر: $source',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: palette.goldMuted),
                ),
              ],
              if (!fromUser) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSpeak,
                      child: RafiqIcon(
                        RafiqIcons.volume,
                        size: 16,
                        color: palette.textDim,
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSpeak,
                      child: Text(
                        'استماع',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: palette.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator();

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.3, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 48),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FadeTransition(
          opacity: _fade,
          child: Text(
            'رفيق يفكّر...',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: palette.textDim),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.listening,
    required this.onChanged,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool listening;
  final VoidCallback onChanged;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final hasText = controller.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: palette.surface.withValues(alpha: 0.8),
                border: Border.all(color: palette.borderSoft),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: AlignmentDirectional.centerStart,
                      children: [
                        if (!hasText)
                          Text(
                            'اكتب سؤالك لرفيق...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: palette.textDim),
                          ),
                        Material(
                          type: MaterialType.transparency,
                          child: TextField(
                            controller: controller,
                            onChanged: (_) => onChanged(),
                            onSubmitted: (_) => onSend(),
                            maxLines: 1,
                            textAlignVertical: TextAlignVertical.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: palette.textPrimary),
                            cursorColor: palette.gold,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onMic,
                    child: RafiqIcon(
                      RafiqIcons.mic,
                      size: 20,
                      color: listening ? palette.gold : palette.mint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: RafiqIcons.send,
            size: 48,
            filled: hasText,
            onTap: () {
              if (hasText) onSend();
            },
          ),
        ],
      ),
    );
  }
}

class _OrnamentRingPainter extends CustomPainter {
  _OrnamentRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.3),
    );
    for (var index = 0; index < 8; index++) {
      final angle = index * (math.pi / 4);
      final point = Offset(
        center.dx + radius * 0.9 * math.cos(angle),
        center.dy + radius * 0.9 * math.sin(angle),
      );
      canvas.drawCircle(
        point,
        1.6,
        Paint()..color = color.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrnamentRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RafiqMarkPainter extends CustomPainter {
  _RafiqMarkPainter(this.palette);

  final RafiqPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final baseY = h * 0.88;
    final archTop = h * 0.2;
    final strokeWidth = math.max(1.0, w * 0.048);
    final bounds = Rect.fromLTWH(0, 0, w, h);
    final brush = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.goldBright, palette.gold, palette.goldMuted],
    ).createShader(bounds);
    final softBrush = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        palette.goldBright.withValues(alpha: 0.65),
        palette.gold.withValues(alpha: 0.65),
        palette.goldMuted.withValues(alpha: 0.65),
      ],
    ).createShader(bounds);
    final sideBrush = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        palette.goldBright.withValues(alpha: 0.75),
        palette.gold.withValues(alpha: 0.75),
        palette.goldMuted.withValues(alpha: 0.75),
      ],
    ).createShader(bounds);

    Paint strokeWith(Shader shader) => Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outer = Path()
      ..moveTo(cx - w * 0.30, baseY)
      ..lineTo(cx - w * 0.30, h * 0.49)
      ..cubicTo(cx - w * 0.30, h * 0.35, cx - w * 0.22, h * 0.26, cx, archTop)
      ..cubicTo(
        cx + w * 0.22,
        h * 0.26,
        cx + w * 0.30,
        h * 0.35,
        cx + w * 0.30,
        h * 0.49,
      )
      ..lineTo(cx + w * 0.30, baseY);
    canvas.drawPath(outer, strokeWith(brush));

    final inner = Path()
      ..moveTo(cx - w * 0.19, baseY)
      ..lineTo(cx - w * 0.19, h * 0.51)
      ..cubicTo(cx - w * 0.19, h * 0.41, cx - w * 0.13, h * 0.34, cx, h * 0.30)
      ..cubicTo(
        cx + w * 0.13,
        h * 0.34,
        cx + w * 0.19,
        h * 0.41,
        cx + w * 0.19,
        h * 0.51,
      )
      ..lineTo(cx + w * 0.19, baseY);
    canvas.drawPath(inner, strokeWith(softBrush));

    final side = Path()
      ..moveTo(cx - w * 0.38, h * 0.39)
      ..cubicTo(
        cx - w * 0.39,
        h * 0.54,
        cx - w * 0.36,
        h * 0.70,
        cx - w * 0.32,
        h * 0.82,
      )
      ..moveTo(cx + w * 0.38, h * 0.39)
      ..cubicTo(
        cx + w * 0.39,
        h * 0.54,
        cx + w * 0.36,
        h * 0.70,
        cx + w * 0.32,
        h * 0.82,
      );
    canvas.drawPath(side, strokeWith(sideBrush));

    canvas.drawLine(
      Offset(cx - w * 0.35, baseY),
      Offset(cx + w * 0.35, baseY),
      Paint()
        ..shader = brush
        ..strokeWidth = math.max(1.0, w * 0.045)
        ..strokeCap = StrokeCap.round,
    );

    final finial = Path()
      ..moveTo(cx, h * 0.10)
      ..lineTo(cx, h * 0.20)
      ..moveTo(cx - w * 0.055, h * 0.145)
      ..lineTo(cx, h * 0.09)
      ..lineTo(cx + w * 0.055, h * 0.145);
    canvas.drawPath(finial, strokeWith(brush));

    canvas.drawCircle(
      Offset(cx, h * 0.55),
      w * 0.037,
      Paint()
        ..shader =
            RadialGradient(
              colors: [palette.goldBright, palette.gold],
              center: Alignment.center,
            ).createShader(
              Rect.fromCircle(center: Offset(cx, h * 0.55), radius: w * 0.07),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _RafiqMarkPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
