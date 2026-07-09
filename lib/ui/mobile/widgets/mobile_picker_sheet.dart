import 'package:flutter/material.dart';

/// Einheitliche Akzentfarbe für alle Picker-Sheets (gleiche Farbe wie im
/// bisherigen Seitenmenü / den Dialogen).
const Color kPickerAccentColor = Color(0xFF5C9DFF);
const double kMobilePickerSheetHeightFactor = 0.72;
const double _mobilePickerSheetMaxHeightFactor = 0.86;
const double _mobilePickerDismissDragDistance = 64;
const double _mobilePickerDismissVelocity = 420;

/// Modernes, an den Inhalt angepasstes Bottom-Sheet als Ersatz für die alten
/// [AlertDialog]-Popups.
///
/// Vorteile gegenüber der alten Lösung:
/// - Die Höhe ergibt sich aus dem tatsächlichen Inhalt (bis zu einer
///   Maximal-Höhe), es wird kein unnötiger Leerraum mehr reserviert.
/// - Optionen werden in einem [Wrap] dargestellt statt in starren,
///   horizontal scrollbaren Spalten -> deutlich angenehmer auf dem Handy.
/// - Tabs werden manuell verwaltet (kein [TabBarView]), damit jeder Tab
///   seine eigene, passende Höhe bekommen kann.
class MobilePickerSheet extends StatelessWidget {
  const MobilePickerSheet({
    super.key,
    required this.title,
    required this.tabLabels,
    required this.tabContents,
    this.currentTabIndex = 0,
    this.onTabChanged,
    this.showSingleTab = false,
  }) : assert(tabLabels.length == tabContents.length),
       assert(tabLabels.length > 0);

  final String title;
  final List<String> tabLabels;
  final List<Widget> tabContents;
  final int currentTabIndex;
  final ValueChanged<int>? onTabChanged;
  final bool showSingleTab;

  bool get _hasTabs => tabLabels.length > 1 || showSingleTab;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final desiredHeight = screenHeight * kMobilePickerSheetHeightFactor;
    final maxHeight = screenHeight * _mobilePickerSheetMaxHeightFactor;
    final sheetHeight = desiredHeight > maxHeight ? maxHeight : desiredHeight;
    final safeIndex = currentTabIndex.clamp(0, tabContents.length - 1);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF171717),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              _MobilePickerSheetHeader(title: title),
              if (_hasTabs) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _PickerTabBar(
                    labels: tabLabels,
                    currentIndex: safeIndex,
                    onChanged: onTabChanged,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: tabContents[safeIndex],
                    ),
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


class _MobilePickerSheetHeader extends StatefulWidget {
  const _MobilePickerSheetHeader({required this.title});

  final String title;

  @override
  State<_MobilePickerSheetHeader> createState() =>
      _MobilePickerSheetHeaderState();
}

class _MobilePickerSheetHeaderState extends State<_MobilePickerSheetHeader> {
  double _dragDistance = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;

    if (delta <= 0) {
      return;
    }

    _dragDistance += delta;
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldClose =
        _dragDistance >= _mobilePickerDismissDragDistance ||
        velocity >= _mobilePickerDismissVelocity;

    _dragDistance = 0;

    if (!shouldClose) {
      return;
    }

    Navigator.of(context).maybePop();
  }

  void _handleDragCancel() {
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: _handleDragCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTabBar extends StatelessWidget {
  const _PickerTabBar({
    required this.labels,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
              child: _PickerTabButton(
                label: labels[i],
                isSelected: i == currentIndex,
                onTap: onChanged == null ? null : () => onChanged!(i),
              ),
            ),
          ),
      ],
    );
  }
}

class _PickerTabButton extends StatelessWidget {
  const _PickerTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? kPickerAccentColor.withAlpha(40)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? kPickerAccentColor.withAlpha(170)
                  : Colors.white.withAlpha(30),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? kPickerAccentColor : Colors.white70,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ein einzelner Auswahl-Chip. Wird typischerweise in einem
/// [MobilePickerChipGrid] (Wrap) verwendet, kann aber auch einzeln mit
/// `SizedBox(width: double.infinity, child: ...)` als volle Zeile genutzt
/// werden (siehe "Sonstiges"-Tabs).
class MobilePickerChip extends StatelessWidget {
  const MobilePickerChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.dense = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          height: dense ? 36 : 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? kPickerAccentColor.withAlpha(28)
                : Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? kPickerAccentColor.withAlpha(190)
                  : Colors.white.withAlpha(35),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? kPickerAccentColor : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 13.5 : 14.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Legt die übergebenen Chips in einem [Wrap] an, der automatisch so viele
/// Chips pro Zeile packt wie Platz ist – dadurch entsteht kein toter Raum
/// mehr wie bei den alten festen Spaltenbreiten.
class MobilePickerChipGrid extends StatelessWidget {
  const MobilePickerChipGrid({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: spacing, runSpacing: runSpacing, children: children);
  }
}

/// Button zum Zurücksetzen einer Mehrfachauswahl, passend zum neuen
/// dunklen Sheet-Design.
class MobilePickerClearButton extends StatelessWidget {
  const MobilePickerClearButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(
          Icons.clear_all,
          size: 18,
          color: isEnabled ? kPickerAccentColor : Colors.white24,
        ),
        label: Text(
          'Auswahl entfernen',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isEnabled ? kPickerAccentColor : Colors.white24,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isEnabled
              ? kPickerAccentColor.withAlpha(18)
              : Colors.white.withAlpha(8),
          side: BorderSide(
            color: isEnabled ? kPickerAccentColor.withAlpha(150) : Colors.white24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Zeigt ein [MobilePickerSheet] als modales Bottom-Sheet an. Praktischer
/// Wrapper, damit die Aufrufstellen nicht jedes Mal die komplette
/// showModalBottomSheet-Konfiguration wiederholen müssen.
Future<void> showMobilePickerSheet({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(160),
    enableDrag: false,
    builder: builder,
  );
}
