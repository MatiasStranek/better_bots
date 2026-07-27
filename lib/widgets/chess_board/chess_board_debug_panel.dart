import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/better_bots_database.dart';
import '../../models/engine_analysis_line.dart';
import '../../models/player_side.dart';
import '../../ui/mobile/widgets/mobile_chess_analysis_lines_bar.dart';
import '../chess_result_stats_panel.dart';

class ChessBoardDebugPanel extends StatelessWidget {
  const ChessBoardDebugPanel({
    required this.playerSide,
    required this.fen,
    required this.pgn,
    required this.engineOutput,
    required this.isAnalysisMode,
    required this.isAnalysisThinking,
    required this.analysisLines,
    required this.showAnalysisRepeatControls,
    required this.completedAnalysisRunCount,
    required this.analysisTargetDepth,
    required this.isAnalysisRepeatActive,
    required this.analysisRepeatCurrentDepth,
    required this.analysisRepeatRemaining,
    required this.analysisRepeatRequestCount,
    required this.canStartAnalysisRepeat,
    required this.onStartAnalysisRepeat,
    required this.onCancelAnalysisRepeat,
    required this.onSetAnalysisRepeatCount,
    required this.onIncrementAnalysisRepeatCount,
    required this.onDecrementAnalysisRepeatCount,
    required this.onAnalysisRepeatCountEditingComplete,
    required this.trainingCounter,
    required this.analysisUsedDuringCurrentGame,
    required this.trainedOnly,
    super.key,
  });

  final PlayerSide playerSide;
  final String fen;
  final String pgn;
  final String engineOutput;
  final bool isAnalysisMode;
  final bool isAnalysisThinking;
  final List<EngineAnalysisLine> analysisLines;
  final bool showAnalysisRepeatControls;
  final int completedAnalysisRunCount;
  final int analysisTargetDepth;
  final bool isAnalysisRepeatActive;
  final int analysisRepeatCurrentDepth;
  final int analysisRepeatRemaining;
  final int analysisRepeatRequestCount;
  final bool canStartAnalysisRepeat;
  final VoidCallback onStartAnalysisRepeat;
  final VoidCallback onCancelAnalysisRepeat;
  final ValueChanged<int> onSetAnalysisRepeatCount;
  final VoidCallback onIncrementAnalysisRepeatCount;
  final VoidCallback onDecrementAnalysisRepeatCount;
  final VoidCallback onAnalysisRepeatCountEditingComplete;
  final TrainingCounterSnapshot trainingCounter;
  final bool analysisUsedDuringCurrentGame;
  final bool trainedOnly;

  @override
  Widget build(BuildContext context) {
    final playerSideText = playerSide == PlayerSide.white ? 'Weiß' : 'Schwarz';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Du spielst: $playerSideText',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        ChessResultStatsTextView(
          counter: trainingCounter,
          analysisUsedDuringCurrentGame: analysisUsedDuringCurrentGame,
          trainedOnly: trainedOnly,
        ),
        const SizedBox(height: 12),
        if (isAnalysisMode)
          _AnalysisLinesView(
            isAnalysisThinking: isAnalysisThinking,
            analysisLines: analysisLines,
            showAnalysisRepeatControls: showAnalysisRepeatControls,
            completedAnalysisRunCount: completedAnalysisRunCount,
            analysisTargetDepth: analysisTargetDepth,
            isAnalysisRepeatActive: isAnalysisRepeatActive,
            analysisRepeatCurrentDepth: analysisRepeatCurrentDepth,
            analysisRepeatRemaining: analysisRepeatRemaining,
            analysisRepeatRequestCount: analysisRepeatRequestCount,
            canStartAnalysisRepeat: canStartAnalysisRepeat,
            onStartAnalysisRepeat: onStartAnalysisRepeat,
            onCancelAnalysisRepeat: onCancelAnalysisRepeat,
            onSetAnalysisRepeatCount: onSetAnalysisRepeatCount,
            onIncrementAnalysisRepeatCount: onIncrementAnalysisRepeatCount,
            onDecrementAnalysisRepeatCount: onDecrementAnalysisRepeatCount,
            onAnalysisRepeatCountEditingComplete:
                onAnalysisRepeatCountEditingComplete,
          )
        else ...[
          Text(
            'Letzte Engine-Ausgabe:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          SelectableText(engineOutput),
        ],
        const SizedBox(height: 16),
        _LabeledSelectableBlock(
          label: 'FEN:',
          value: fen,
        ),
        const SizedBox(height: 12),
        _LabeledSelectableBlock(
          label: 'PGN:',
          value: pgn,
        ),
      ],
    );
  }
}

class _LabeledSelectableBlock extends StatelessWidget {
  const _LabeledSelectableBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}

class _AnalysisLinesView extends StatelessWidget {
  const _AnalysisLinesView({
    required this.isAnalysisThinking,
    required this.analysisLines,
    required this.showAnalysisRepeatControls,
    required this.completedAnalysisRunCount,
    required this.analysisTargetDepth,
    required this.isAnalysisRepeatActive,
    required this.analysisRepeatCurrentDepth,
    required this.analysisRepeatRemaining,
    required this.analysisRepeatRequestCount,
    required this.canStartAnalysisRepeat,
    required this.onStartAnalysisRepeat,
    required this.onCancelAnalysisRepeat,
    required this.onSetAnalysisRepeatCount,
    required this.onIncrementAnalysisRepeatCount,
    required this.onDecrementAnalysisRepeatCount,
    required this.onAnalysisRepeatCountEditingComplete,
  });

  final bool isAnalysisThinking;
  final List<EngineAnalysisLine> analysisLines;
  final bool showAnalysisRepeatControls;
  final int completedAnalysisRunCount;
  final int analysisTargetDepth;
  final bool isAnalysisRepeatActive;
  final int analysisRepeatCurrentDepth;
  final int analysisRepeatRemaining;
  final int analysisRepeatRequestCount;
  final bool canStartAnalysisRepeat;
  final VoidCallback onStartAnalysisRepeat;
  final VoidCallback onCancelAnalysisRepeat;
  final ValueChanged<int> onSetAnalysisRepeatCount;
  final VoidCallback onIncrementAnalysisRepeatCount;
  final VoidCallback onDecrementAnalysisRepeatCount;
  final VoidCallback onAnalysisRepeatCountEditingComplete;

  @override
  Widget build(BuildContext context) {
    final titleSuffix = isAnalysisThinking && completedAnalysisRunCount == 0
        ? ' läuft...'
        : '';
    final headerDepth = analysisTargetDepth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          // The repeat controls are 32 px high. Reserve that height from the
          // first analysis frame so the Top-5 bar never jumps downward when
          // x1 and the controls become visible after the first depth-20 run.
          height: 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Top-5 Analyse$titleSuffix',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 18),
              Text(
                'Tiefe $headerDepth',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              if (showAnalysisRepeatControls &&
                  completedAnalysisRunCount > 0) ...[
                const SizedBox(width: 12),
                Text(
                  'x$completedAnalysisRunCount',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                const SizedBox(width: 8),
                if (isAnalysisRepeatActive) ...[
                  _SquareDepthProgress(
                    depth: analysisRepeatCurrentDepth,
                    targetDepth: analysisTargetDepth,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Noch $analysisRepeatRemaining',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  const SizedBox(width: 8),
                  _CancelReanalysisButton(onPressed: onCancelAnalysisRepeat),
                ] else ...[
                  _ReanalysisButton(
                    enabled: canStartAnalysisRepeat,
                    onPressed: onStartAnalysisRepeat,
                  ),
                  const SizedBox(width: 7),
                  _RepeatCountSelector(
                    value: analysisRepeatRequestCount,
                    enabled: canStartAnalysisRepeat,
                    onChanged: onSetAnalysisRepeatCount,
                    onIncrement: onIncrementAnalysisRepeatCount,
                    onDecrement: onDecrementAnalysisRepeatCount,
                    onEditingComplete:
                        onAnalysisRepeatCountEditingComplete,
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (analysisLines.isEmpty)
          SelectableText(
            isAnalysisThinking
                ? 'Engine analysiert bis Tiefe $analysisTargetDepth. Live-Linien erscheinen ab Tiefe 1 und werden nur nach abgeschlossenen Tiefen aktualisiert.'
                : 'Noch keine Analyse-Linien vorhanden.',
          )
        else
          _DesktopAnalysisLinesBar(analysisLines: analysisLines),
      ],
    );
  }


}

class _ReanalysisButton extends StatelessWidget {
  const _ReanalysisButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'NeuAnalyse ab Tiefe 0 starten',
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.replay_rounded, size: 21),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF55C878),
            disabledForegroundColor: Colors.white38,
            side: BorderSide(
              color: enabled
                  ? const Color(0xFF55C878)
                  : Colors.white24,
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelReanalysisButton extends StatelessWidget {
  const _CancelReanalysisButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Automatische NeuAnalyse abbrechen',
      child: SizedBox.square(
        dimension: 30,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.stop_rounded, size: 18),
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFFFF6B6B),
            side: const BorderSide(color: Color(0xFFFF6B6B), width: 1.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatCountSelector extends StatefulWidget {
  const _RepeatCountSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEditingComplete,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onEditingComplete;

  @override
  State<_RepeatCountSelector> createState() => _RepeatCountSelectorState();
}

class _RepeatCountSelectorState extends State<_RepeatCountSelector> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode(debugLabel: 'AnalysisRepeatCountInput')
      ..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _RepeatCountSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_focusNode.hasFocus && widget.value != oldWidget.value) {
      _writeCanonicalValue();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
      return;
    }

    _commitAndFinishEditing();
  }

  void _handleTextChanged(String rawValue) {
    final parsedValue = int.tryParse(rawValue);
    if (parsedValue == null || parsedValue < 1 || parsedValue > 1000) {
      return;
    }

    widget.onChanged(parsedValue);
  }

  void _commitAndFinishEditing() {
    final parsedValue = int.tryParse(_textController.text);
    final normalizedValue =
        (parsedValue ?? widget.value).clamp(1, 1000).toInt();
    widget.onChanged(normalizedValue);
    _textController.text = '$normalizedValue';
    widget.onEditingComplete();
  }

  void _writeCanonicalValue() {
    final canonicalText = '${widget.value}';
    if (_textController.text == canonicalText) {
      return;
    }

    _textController.value = TextEditingValue(
      text: canonicalText,
      selection: TextSelection.collapsed(offset: canonicalText.length),
    );
  }

  int _nextFiveStep(int value) {
    if (value <= 1) {
      return 5;
    }

    final remainder = value % 5;
    if (remainder == 0) {
      return (value + 5).clamp(1, 1000).toInt();
    }

    return (value + (5 - remainder)).clamp(1, 1000).toInt();
  }

  int _previousFiveStep(int value) {
    if (value <= 1) {
      return 1;
    }

    if (value <= 5) {
      return 1;
    }

    final remainder = value % 5;
    if (remainder == 0) {
      return (value - 5).clamp(1, 1000).toInt();
    }

    return (value - remainder).clamp(1, 1000).toInt();
  }

  void _applyExternalValue(int value) {
    final normalizedValue = value.clamp(1, 1000).toInt();
    widget.onChanged(normalizedValue);
    _textController.value = TextEditingValue(
      text: '$normalizedValue',
      selection: TextSelection.collapsed(
        offset: '$normalizedValue'.length,
      ),
    );
    _focusNode.unfocus();
    widget.onEditingComplete();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.enabled ? Colors.white54 : Colors.white24;

    return SizedBox(
      width: 128,
      height: 32,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(80),
          border: Border.all(color: borderColor, width: 1.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    const _AnalysisRepeatRangeFormatter(),
                  ],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 3),
                    counterText: '',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.enabled ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                  onChanged: _handleTextChanged,
                  onSubmitted: (_) {
                    _focusNode.unfocus();
                  },
                  onTapOutside: (_) {
                    _focusNode.unfocus();
                  },
                ),
              ),
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Expanded(
                      child: _CountStepButton(
                        icon: Icons.add,
                        enabled: widget.enabled && widget.value < 1000,
                        onPressed: widget.onIncrement,
                        top: true,
                      ),
                    ),
                    Expanded(
                      child: _CountStepButton(
                        icon: Icons.remove,
                        enabled: widget.enabled && widget.value > 1,
                        onPressed: widget.onDecrement,
                        top: false,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Expanded(
                      child: _CountStepLabelButton(
                        label: '++',
                        enabled: widget.enabled && widget.value < 1000,
                        onPressed: () {
                          _applyExternalValue(_nextFiveStep(widget.value));
                        },
                        top: true,
                        drawLeftDivider: true,
                      ),
                    ),
                    Expanded(
                      child: _CountStepLabelButton(
                        label: '--',
                        enabled: widget.enabled && widget.value > 1,
                        onPressed: () {
                          _applyExternalValue(_previousFiveStep(widget.value));
                        },
                        top: false,
                        drawLeftDivider: true,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 30,
                child: _ResetCountButton(
                  enabled: widget.enabled && widget.value != 1,
                  onPressed: () {
                    _applyExternalValue(1);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisRepeatRangeFormatter extends TextInputFormatter {
  const _AnalysisRepeatRangeFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final parsedValue = int.tryParse(newValue.text);
    if (parsedValue == null || parsedValue < 1 || parsedValue > 1000) {
      return oldValue;
    }

    return newValue;
  }
}

class _CountStepButton extends StatelessWidget {
  const _CountStepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.top,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;
  final bool top;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: Colors.white24, width: 1),
          bottom: top
              ? const BorderSide(color: Colors.white24, width: 1)
              : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Center(
          child: Icon(
            icon,
            size: 12,
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }
}


class _CountStepLabelButton extends StatelessWidget {
  const _CountStepLabelButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.top,
    this.drawLeftDivider = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool top;
  final bool drawLeftDivider;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: drawLeftDivider
              ? const BorderSide(color: Colors.white24, width: 1)
              : BorderSide.none,
          bottom: top
              ? const BorderSide(color: Colors.white24, width: 1)
              : BorderSide.none,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled ? Colors.white : Colors.white30,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: -0.4,
                ),
          ),
        ),
      ),
    );
  }
}

class _ResetCountButton extends StatelessWidget {
  const _ResetCountButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Center(
          child: Icon(
            Icons.restart_alt_rounded,
            size: 18,
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }
}

class _SquareDepthProgress extends StatelessWidget {
  const _SquareDepthProgress({
    required this.depth,
    required this.targetDepth,
  });

  final int depth;
  final int targetDepth;

  @override
  Widget build(BuildContext context) {
    final progress = targetDepth <= 0
        ? 0.0
        : (depth / targetDepth).clamp(0.0, 1.0).toDouble();

    return Tooltip(
      message: 'NeuAnalyse: Tiefe $depth/$targetDepth',
      child: SizedBox.square(
        dimension: 32,
        child: CustomPaint(
          painter: _SquareDepthProgressPainter(progress: progress),
          child: Center(
            child: Text(
              '$depth',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquareDepthProgressPainter extends CustomPainter {
  const _SquareDepthProgressPainter({required this.progress});

  final double progress;

  static const Color _pendingColor = Color(0xFF536E5C);
  static const Color _completedColor = Color(0xFF2FA45B);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final roundedRect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(7),
    );

    canvas.save();
    canvas.clipRRect(roundedRect);
    canvas.drawRect(rect, Paint()..color = _pendingColor);

    if (progress > 0) {
      final radius = size.longestSide * 0.78;
      final sweepRect = Rect.fromCircle(
        center: rect.center,
        radius: radius,
      );
      canvas.drawArc(
        sweepRect,
        -math.pi / 2,
        math.pi * 2 * progress,
        true,
        Paint()..color = _completedColor,
      );

      final handAngle = -math.pi / 2 + math.pi * 2 * progress;
      final handEnd = Offset(
        rect.center.dx + math.cos(handAngle) * size.width * 0.42,
        rect.center.dy + math.sin(handAngle) * size.height * 0.42,
      );
      canvas.drawLine(
        rect.center,
        handEnd,
        Paint()
          ..color = Colors.white.withAlpha(210)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
    canvas.drawRRect(
      roundedRect,
      Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _SquareDepthProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DesktopAnalysisLinesBar extends StatelessWidget {
  const _DesktopAnalysisLinesBar({required this.analysisLines});

  final List<EngineAnalysisLine> analysisLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      width: double.infinity,
      child: MobileChessAnalysisLinesBar(analysisLines: analysisLines),
    );
  }
}
