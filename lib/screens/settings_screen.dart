import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../data/preferences.dart';
import '../data/prayer_calculator.dart';
import '../state/app_state.dart';
import '../state/prayer_state.dart';
import '../state/settings_state.dart';
import '../theme/palette.dart';
import '../theme/rafiq_theme.dart';
import '../widgets/components.dart';
import '../widgets/rafiq_icons.dart';
import '../widgets/top_bar.dart';

const String rafiqAppVersion = '1.0.0';

enum _SettingsSection { main, prayer, sound, privacy, about, language }

String themeName(String theme) {
  switch (theme) {
    case 'midnight':
      return 'الليلي';
    case 'dawn':
      return 'الفجر';
    default:
      return 'الزمردي';
  }
}

PrayerState? prayerStateOf(BuildContext context) {
  final element = context
      .getElementForInheritedWidgetOfExactType<PrayerScope>();
  final scope = element?.widget as PrayerScope?;
  return scope?.notifier;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeId,
    required this.onThemeChanged,
  });

  final String themeId;
  final ValueChanged<String> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsSection _section = _SettingsSection.main;
  late final SettingsState _state;

  bool get _supportsExactAlarm =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    _state = SettingsState(AppScope.read(context));
    _state.addListener(_handleStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state.refreshExactAlarmPermission();
    });
  }

  @override
  void dispose() {
    _state.removeListener(_handleStateChanged);
    _state.dispose();
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  void _openSection(_SettingsSection section) {
    setState(() {
      _section = section;
    });
    if (section == _SettingsSection.prayer) {
      _state.refreshExactAlarmPermission();
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    await _state.setNotificationsEnabled(enabled);
  }

  Future<void> _openMethodSheet() async {
    final prayer = prayerStateOf(context);
    final selected = await showPrayerMethodSheet(
      context,
      current: prayer?.method ?? CalculationMethod.egyptian,
    );
    if (selected == null || !mounted) return;
    await _state.setCalculationMethod(selected);
    prayer?.update(method: selected);
  }

  Future<void> _openCitySheet() async {
    final prayer = prayerStateOf(context);
    final selected = await showPrayerCitySheet(
      context,
      currentLabel: prayer?.locationLabel ?? '',
    );
    if (selected == null || !mounted) return;
    if (selected.id == '__detect__') {
      await _detectLocation();
      return;
    }
    await _state.setCity(selected);
    prayer?.update(
      latitude: selected.latitude,
      longitude: selected.longitude,
      locationLabel: selected.name,
    );
  }

  Future<void> _detectLocation() async {
    final detected = await _state.detectLocation();
    if (!mounted) return;
    if (detected == null) return;
    final prayer = prayerStateOf(context);
    prayer?.update(
      latitude: detected.latitude,
      longitude: detected.longitude,
      locationLabel: 'موقعك الحالي',
    );
  }

  void _selectTheme(String theme) {
    widget.onThemeChanged(theme);
    unawaited(_state.setTheme(theme));
  }

  Future<void> _openNameDialog() async {
    final appState = AppScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _NameDialog(
        current: appState.preferences.displayName,
        onSave: (name) => _state.setDisplayName(name),
      ),
    );
  }

  Future<void> _openThemeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _ThemeDialog(current: widget.themeId, onSelect: _selectTheme),
    );
  }

  Future<void> _openFocusDialog() async {
    final appState = AppScope.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _FocusDurationDialog(
        current: appState.preferences.focusDurationMinutes,
        onSelect: (minutes) => _state.setFocusDuration(minutes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  child: _buildSection(appState),
                ),
              ),
            ],
          ),
          if (_state.message != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: RafiqTransientMessage(
                message: _state.message!,
                onConsumed: _state.consumeMessage,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    switch (_section) {
      case _SettingsSection.main:
        return const RafiqTopBar(title: 'الإعدادات', subtitle: 'رفيقك كما تحب');
      case _SettingsSection.prayer:
        return RafiqTopBar(
          title: 'الصلاة والمواقيت',
          onBack: () => _openSection(_SettingsSection.main),
        );
      case _SettingsSection.sound:
        return RafiqTopBar(
          title: 'الأصوات والاهتزاز',
          onBack: () => _openSection(_SettingsSection.main),
        );
      case _SettingsSection.privacy:
        return RafiqTopBar(
          title: 'الخصوصية والبيانات',
          onBack: () => _openSection(_SettingsSection.main),
        );
      case _SettingsSection.language:
        return RafiqTopBar(
          title: 'لغة الواجهة',
          onBack: () => _openSection(_SettingsSection.main),
        );
      case _SettingsSection.about:
        return RafiqTopBar(
          title: 'حول رفيق',
          onBack: () => _openSection(_SettingsSection.main),
        );
    }
  }

  Widget _buildSection(AppState appState) {
    final palette = RafiqThemeScope.of(context);
    final preferences = appState.preferences;
    switch (_section) {
      case _SettingsSection.main:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileCard(
              name: preferences.displayName,
              onEdit: () => unawaited(_openNameDialog()),
            ),
            const SizedBox(height: 16),
            RafiqSettingsGroup(
              children: [
                RafiqSettingsRow(
                  icon: RafiqIcons.palette,
                  title: 'المظهر',
                  value: themeName(widget.themeId),
                  onTap: () => unawaited(_openThemeDialog()),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.mosque,
                  title: 'الصلاة والمواقيت',
                  value: CalculationMethod.fromId(
                    preferences.calculationMethod,
                  ).arabicName,
                  onTap: () => _openSection(_SettingsSection.prayer),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.volume,
                  title: 'الأصوات والاهتزاز',
                  value: preferences.soundsEnabled ? 'مفعّلة' : 'متوقفة',
                  onTap: () => _openSection(_SettingsSection.sound),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.focus,
                  title: 'جلسة التركيز',
                  value: '${preferences.focusDurationMinutes} دقيقة',
                  onTap: () => unawaited(_openFocusDialog()),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.globe,
                  title: 'لغة الواجهة',
                  value: 'العربية',
                  onTap: () => _openSection(_SettingsSection.language),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RafiqSettingsGroup(
              children: [
                RafiqSettingsRow(
                  icon: RafiqIcons.shield,
                  title: 'الخصوصية والبيانات',
                  onTap: () => _openSection(_SettingsSection.privacy),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.info,
                  title: 'حول رفيق',
                  value: 'الإصدار $rafiqAppVersion',
                  onTap: () => _openSection(_SettingsSection.about),
                ),
              ],
            ),
            const SizedBox(height: 12),
            RafiqSettingsGroup(
              children: [
                RafiqSettingsRow(
                  icon: RafiqIcons.home,
                  title: 'تعيين رفيق كشاشة رئيسية',
                  onTap: () => _state.openHomeSettings(),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.settings,
                  title: 'إعدادات التطبيق في النظام',
                  onTap: () => _state.openAppSettings(),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'رفيق • شريكك في رحلتك نحو الأفضل',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: palette.textDim),
            ),
          ],
        );
      case _SettingsSection.prayer:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ToggleRow(
              icon: RafiqIcons.bell,
              title: 'تنبيهات الصلاة',
              subtitle: preferences.prayerNotifications
                  ? 'سيصلك تنبيه عند دخول وقت كل صلاة'
                  : 'تنبيهات الصلاة متوقفة حاليًا',
              checked: preferences.prayerNotifications,
              onToggle: _toggleNotifications,
            ),
            const SizedBox(height: 10),
            RafiqSecondaryButton(
              text: 'إرسال تنبيه تجريبي',
              icon: RafiqIcons.bell,
              onTap: () => _state.showTestPrayerNotification(),
            ),
            if (_supportsExactAlarm) ...[
              const SizedBox(height: 10),
              RafiqSettingsGroup(
                children: [
                  RafiqSettingsRow(
                    icon: RafiqIcons.clock,
                    title: 'إذن المنبّهات الدقيقة',
                    value: _state.canScheduleExact ? 'مسموح' : 'غير مسموح',
                    onTap: () => _state.openExactAlarmSettings(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'طريقة الحساب',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 8),
            RafiqSettingsGroup(
              children: [
                RafiqSettingsRow(
                  icon: RafiqIcons.settings,
                  title: 'طريقة الحساب',
                  value: CalculationMethod.fromId(
                    preferences.calculationMethod,
                  ).arabicName,
                  onTap: _openMethodSheet,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'مدينة الحساب اليدوية',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'المدينة الحالية: ${preferences.locationLabel}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textDim),
            ),
            const SizedBox(height: 8),
            RafiqSettingsGroup(
              children: [
                RafiqSettingsRow(
                  icon: RafiqIcons.location,
                  title: 'المدينة الحالية',
                  value: preferences.locationLabel,
                  onTap: _openCitySheet,
                ),
              ],
            ),
          ],
        );
      case _SettingsSection.sound:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ToggleRow(
              icon: RafiqIcons.volume,
              title: 'أصوات الواجهة',
              subtitle: 'نغمات هادئة عند التفاعل والإشعارات',
              checked: preferences.soundsEnabled,
              onToggle: (value) => _state.setSoundsEnabled(value),
            ),
            const SizedBox(height: 10),
            _ToggleRow(
              icon: RafiqIcons.sparkle,
              title: 'الاهتزاز اللمسي',
              subtitle: 'ردود لمسية خفيفة عند الأزرار والبطاقات',
              checked: preferences.hapticsEnabled,
              onToggle: (value) => _state.setHapticsEnabled(value),
            ),
          ],
        );
      case _SettingsSection.privacy:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'رفيق لا يجمع بيانات شخصية ولا يرسلها إلى خوادم خاصة. تعمل المواقيت والأذكار والمصحف داخل جهازك، ولا يُستخدم الإنترنت إلا لتشغيل التلاوة عند طلبها.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: 16),
            RafiqCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'البيانات المحفوظة محليًا',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: palette.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• اسمك المفضل وإعدادات المظهر واللغة\n'
                    '• مدينة وطريقة حساب المواقيت\n'
                    '• مهامك اليومية وعلامات المصحف\n'
                    '• موضع تلاوتك وآخر سورة قرأتها',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            RafiqSecondaryButton(
              text: 'إعادة ضبط البيانات الشخصية',
              icon: RafiqIcons.refresh,
              contentColor: palette.danger,
              onTap: () => _state.resetPersonalData(),
            ),
            const SizedBox(height: 10),
            Text(
              'سيؤدي هذا إلى حذف المهام والعلامات وإعداداتك الشخصية، مع الاحتفاظ بإعدادات النظام.',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: palette.textDim),
            ),
          ],
        );
      case _SettingsSection.language:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RafiqCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'العربية',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: palette.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'صُمم رفيق واجهةً عربية أصيلة، والمحتوى القرآني والأذكار بالعربية الفصحى. إن أردت لغة أخرى فستُضاف في تحديث قادم.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RafiqSecondaryButton(
              text: 'فتح إعدادات لغة النظام',
              icon: RafiqIcons.globe,
              onTap: () => _state.openLanguageSettings(),
            ),
          ],
        );
      case _SettingsSection.about:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RafiqCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رفيق — شريكك في رحلتك نحو الأفضل',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: palette.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تطبيق إسلامي عربي يجمع المصحف والأذكار والمواقيت والتركيز والمهام، بتصميم هادئ يحترم خصوصيتك.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RafiqCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'المصادر',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: palette.gold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• النص القرآني والترجمة: Quran.com API (النص العثماني + Saheeh International)\n'
                    '• الأذكار: حصن المسلم ومصادر الصباح والمساء الموثقة\n'
                    '• المواقيت: حسابات فلكية وفق طرق الهيئات المعتمدة\n'
                    '• التلاوة: مشاري العفاسي عبر everyayah.com',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            RafiqSettingsGroup(
              children: [
                RafiqSettingsRow(
                  icon: RafiqIcons.home,
                  title: 'تعيين رفيق كشاشة رئيسية',
                  onTap: () => _state.openHomeSettings(),
                ),
                RafiqSettingsRow(
                  icon: RafiqIcons.settings,
                  title: 'إعدادات التطبيق في النظام',
                  onTap: () => _state.openAppSettings(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'الإصدار $rafiqAppVersion',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: palette.textDim),
            ),
          ],
        );
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.onEdit});

  final String name;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return RafiqCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceHigh,
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: RafiqIcon(
                RafiqIcons.person,
                size: 26,
                color: palette.gold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: palette.textPrimary),
                ),
                Text(
                  'اضغط لتغيير الاسم المفضل',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: palette.textDim),
                ),
              ],
            ),
          ),
          RoundIconButton(icon: RafiqIcons.edit, size: 36, onTap: onEdit),
        ],
      ),
    );
  }
}

class RafiqSettingsGroup extends StatelessWidget {
  const RafiqSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: palette.surface.withValues(alpha: 0.6),
        border: Border.all(color: palette.borderSoft),
      ),
      child: Column(children: children),
    );
  }
}

class RafiqSettingsRow extends StatelessWidget {
  const RafiqSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });

  final RafiqIconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            RafiqIcon(icon, size: 19, color: palette.goldMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: palette.textDim),
              ),
              const SizedBox(width: 6),
            ],
            RafiqIcon(RafiqIcons.chevronLeft, size: 16, color: palette.textDim),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.checked,
    required this.onToggle,
  });

  final RafiqIconData icon;
  final String title;
  final String subtitle;
  final bool checked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onToggle(!checked),
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: palette.surface.withValues(alpha: 0.6),
            border: Border.all(color: palette.borderSoft),
          ),
          child: Row(
            children: [
              RafiqIcon(icon, size: 19, color: palette.goldMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: palette.textDim),
                    ),
                  ],
                ),
              ),
              _RafiqSwitch(checked: checked),
            ],
          ),
        ),
      ),
    );
  }
}

class _RafiqSwitch extends StatelessWidget {
  const _RafiqSwitch({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked
            ? palette.gold.withValues(alpha: 0.35)
            : palette.surfaceHigh,
        border: Border.all(color: checked ? palette.gold : palette.borderSoft),
      ),
      child: Align(
        alignment: checked
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? palette.goldBright : palette.textDim,
          ),
        ),
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.current, required this.onSave});

  final String current;
  final ValueChanged<String> onSave;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.current,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onSave(value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return RafiqDialog(
      title: 'الاسم المفضل',
      onDismiss: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: palette.surface.withValues(alpha: 0.7),
              border: Border.all(color: palette.borderSoft),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              cursorColor: palette.gold,
              cursorWidth: 1.6,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'الاسم المفضل',
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.textDim),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 16),
          RafiqPrimaryButton(
            text: 'حفظ',
            icon: RafiqIcons.check,
            enabled: _controller.text.trim().isNotEmpty,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

class _ThemeDialog extends StatelessWidget {
  const _ThemeDialog({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const themes = <String, String>{
      'emerald': 'الزمردي',
      'midnight': 'الليلي',
      'dawn': 'الفجر',
    };
    return RafiqDialog(
      title: 'مظهر رفيق',
      onDismiss: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in themes.entries)
            _ThemeOption(
              id: entry.key,
              name: entry.value,
              selected: entry.key == current,
              onTap: () {
                onSelect(entry.key);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.id,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final themePalette = paletteFor(id);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? palette.surfaceHigh.withValues(alpha: 0.9)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themePalette.backgroundSecondary,
                  border: Border.all(color: themePalette.gold, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? palette.gold : palette.textPrimary,
                  ),
                ),
              ),
              if (selected)
                RafiqIcon(RafiqIcons.check, size: 17, color: palette.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusDurationDialog extends StatelessWidget {
  const _FocusDurationDialog({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    const options = <int>[15, 25, 45, 60, 90];
    return RafiqDialog(
      title: 'مدة جلسة التركيز',
      onDismiss: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final minutes in options)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onSelect(minutes);
                  Navigator.of(context).pop();
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$minutes دقيقة',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: minutes == current
                                    ? palette.gold
                                    : palette.textPrimary,
                              ),
                        ),
                      ),
                      if (minutes == current)
                        RafiqIcon(
                          RafiqIcons.check,
                          size: 17,
                          color: palette.gold,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RafiqDialog extends StatelessWidget {
  const RafiqDialog({
    super.key,
    required this.title,
    required this.onDismiss,
    required this.child,
  });

  final String title;
  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
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
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: palette.gold),
                  ),
                ),
                RoundIconButton(
                  icon: RafiqIcons.close,
                  size: 34,
                  onTap: onDismiss,
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class RafiqBottomSheet extends StatelessWidget {
  const RafiqBottomSheet({
    super.key,
    required this.onDismiss,
    required this.child,
  });

  final VoidCallback onDismiss;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 42,
                  height: 3,
                  decoration: BoxDecoration(
                    color: palette.gold.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class RafiqPrimaryButton extends StatelessWidget {
  const RafiqPrimaryButton({
    super.key,
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
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(17),
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
            mainAxisSize: MainAxisSize.max,
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 19, color: palette.backgroundDeep),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: palette.backgroundDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RafiqSecondaryButton extends StatelessWidget {
  const RafiqSecondaryButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.contentColor,
  });

  final String text;
  final VoidCallback onTap;
  final RafiqIconData? icon;
  final Color? contentColor;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    final color = contentColor ?? palette.gold;
    return Material(
      color: palette.surfaceHigh.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RafiqTransientMessage extends StatefulWidget {
  const RafiqTransientMessage({
    super.key,
    required this.message,
    required this.onConsumed,
  });

  final String message;
  final VoidCallback onConsumed;

  @override
  State<RafiqTransientMessage> createState() => _RafiqTransientMessageState();
}

class _RafiqTransientMessageState extends State<RafiqTransientMessage> {
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant RafiqTransientMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _schedule();
    }
  }

  void _schedule() {
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      widget.onConsumed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: palette.surfaceHigh.withValues(alpha: 0.97),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        widget.message,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: palette.textPrimary),
      ),
    );
  }
}

Future<CalculationMethod?> showPrayerMethodSheet(
  BuildContext context, {
  required CalculationMethod current,
}) {
  return showModalBottomSheet<CalculationMethod>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = RafiqThemeScope.of(context);
      return RafiqBottomSheet(
        onDismiss: () => Navigator.of(sheetContext).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'طريقة حساب المواقيت',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: palette.gold),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final method in CalculationMethod.values)
                      _SheetOption(
                        label: method.arabicName,
                        selected: method.id == current.id,
                        bodyMedium: true,
                        onTap: () => Navigator.of(sheetContext).pop(method),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<ManualCity?> showPrayerCitySheet(
  BuildContext context, {
  required String currentLabel,
}) {
  return showModalBottomSheet<ManualCity>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = RafiqThemeScope.of(context);
      return RafiqBottomSheet(
        onDismiss: () => Navigator.of(sheetContext).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مدينة الحساب',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: palette.gold),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر مدينة يدوية عند عدم رغبتك في استخدام GPS.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textDim),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SheetOption(
                      label: 'تحديد موقعي تلقائيًا',
                      icon: RafiqIcons.location,
                      selected: false,
                      showCheck: false,
                      onTap: () =>
                          Navigator.of(sheetContext).pop(_detectCitySentinel),
                    ),
                    for (final city in manualCities)
                      _SheetOption(
                        label: city.name,
                        trailing: manualCityCountry(city.id),
                        selected: city.name == currentLabel,
                        showCheck: false,
                        onTap: () => Navigator.of(sheetContext).pop(city),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

const ManualCity _detectCitySentinel = ManualCity(
  id: '__detect__',
  name: 'تحديد موقعي تلقائيًا',
  latitude: 0,
  longitude: 0,
  timeZoneId: '',
);

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailing,
    this.bodyMedium = false,
    this.showCheck = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final RafiqIconData? icon;
  final String? trailing;
  final bool bodyMedium;
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final palette = RafiqThemeScope.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: bodyMedium ? 12 : 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected
                ? palette.surfaceHigh.withValues(alpha: 0.9)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                RafiqIcon(icon!, size: 15, color: palette.goldMuted),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style:
                      (bodyMedium
                              ? Theme.of(context).textTheme.bodyMedium
                              : Theme.of(context).textTheme.titleSmall)
                          ?.copyWith(
                            color: selected
                                ? palette.gold
                                : palette.textPrimary,
                          ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: palette.textDim),
                ),
              if (selected && showCheck) ...[
                const SizedBox(width: 8),
                RafiqIcon(RafiqIcons.check, size: 18, color: palette.gold),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
