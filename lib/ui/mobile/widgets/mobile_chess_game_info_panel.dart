import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/bot_opening_move.dart';
import '../../../models/bot_profile.dart';
import '../../../models/bot_personality.dart';
import '../../../models/bot_personality_source.dart';
import '../../../models/engine_strength_mode.dart';
import '../../../models/fritz19_personality.dart';

class MobileChessGameInfoPanel extends StatelessWidget {
  const MobileChessGameInfoPanel({
    super.key,
    required this.skillLevel,
    required this.uciElo,
    required this.cpLossElo,
    required this.cpLossUciSwitchFullMoveNumber,
    required this.strengthMode,
    required this.botOpeningMove,
    required this.effectiveBotOpeningMove,
    required this.botPersonalitySource,
    required this.effectiveBotPersonalitySource,
    required this.botPersonality,
    required this.effectiveBotPersonality,
    required this.fritz19Personality,
    required this.effectiveFritz19Personality,
    required this.personaCandidateCount,
    required this.activeBotProfile,
    required this.isSoloMode,
    required this.isAnalysisMode,
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
    this.playFromHereFen,
  });

  final int skillLevel;
  final int uciElo;
  final int cpLossElo;
  final int cpLossUciSwitchFullMoveNumber;
  final EngineStrengthMode strengthMode;
  final BotOpeningMove botOpeningMove;
  final BotOpeningMove effectiveBotOpeningMove;
  final BotPersonalitySource botPersonalitySource;
  final BotPersonalitySource effectiveBotPersonalitySource;
  final BotPersonality botPersonality;
  final BotPersonality effectiveBotPersonality;
  final Fritz19Personality fritz19Personality;
  final Fritz19Personality effectiveFritz19Personality;
  final int personaCandidateCount;
  final BotProfile? activeBotProfile;
  final bool isSoloMode;
  final bool isAnalysisMode;
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
  final String? playFromHereFen;

  String get _strengthText {
    switch (strengthMode) {
      case EngineStrengthMode.level:
        return 'Level $skillLevel';
      case EngineStrengthMode.uciElo:
        return 'UCI $uciElo';
      case EngineStrengthMode.cpLossElo:
        return 'CP $cpLossElo';
    }
  }

  String get _openingText {
    if (botOpeningMove == BotOpeningMove.random) {
      return 'Zufällig: ${effectiveBotOpeningMove.label}';
    }

    return botOpeningMove.label;
  }

  String get _personalityText {
    if (botPersonalitySource == BotPersonalitySource.random) {
      if (effectiveBotPersonalitySource == BotPersonalitySource.fritz19) {
        return 'Alles Zufällig: Fritz19 '
            '${effectiveFritz19Personality.label}';
      }

      return 'Alles Zufällig: ${effectiveBotPersonality.label}';
    }

    if (botPersonalitySource == BotPersonalitySource.fritz19) {
      if (fritz19Personality == Fritz19Personality.random) {
        return 'Fritz19 Zufällig: ${effectiveFritz19Personality.label}';
      }

      return 'Fritz19: ${fritz19Personality.label}';
    }

    if (botPersonality == BotPersonality.random &&
        effectiveBotPersonality.isConcretePersonality) {
      return 'Zufällig: ${effectiveBotPersonality.label}';
    }

    return botPersonality.label;
  }

  @override
  Widget build(BuildContext context) {
    if (isAnalysisMode) {
      return _MobileAnalysisRepeatPanel(
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
      );
    }

    final activeBotProfile = this.activeBotProfile;
    final rows = activeBotProfile == null
        ? <_GameInfoRowData>[
            _GameInfoRowData(label: 'Spielstärke', value: _strengthText),
            _GameInfoRowData(label: 'Eröffnung', value: _openingText),
            _GameInfoRowData(label: 'Persönlichkeit', value: _personalityText),
            _GameInfoRowData(label: 'Kandidaten', value: '$personaCandidateCount'),
            _GameInfoRowData(
              label: 'UCI_ELO Switch',
              value: 'Zug $cpLossUciSwitchFullMoveNumber',
            ),
          ]
        : <_GameInfoRowData>[
            _GameInfoRowData(
              label: 'Bot',
              value: activeBotProfile.displayName,
            ),
            if (effectiveBotOpeningMove.isRealOpening)
              _GameInfoRowData(
                label: 'Eröffnung',
                value: effectiveBotOpeningMove.label,
              ),
          ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withAlpha(205),
          border: Border.all(color: Colors.white.withAlpha(24), width: 1),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (playFromHereFen != null &&
                  playFromHereFen!.trim().isNotEmpty) ...[
                Text(
                  'FEN-ID: ${playFromHereFen!.trim()}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFFFA726),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
              ],
              if (isSoloMode)
                const _SoloModeInfo()
              else
                for (final row in rows) _GameInfoRow(data: row),
            ],
          ),
        ),
      ),
    );
  }
}


class _MobileAnalysisRepeatPanel extends StatelessWidget {
  const _MobileAnalysisRepeatPanel({
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
  });

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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111111).withAlpha(205),
          border: Border.all(color: Colors.white.withAlpha(24), width: 1),
        ),
        child: completedAnalysisRunCount <= 0
            ? const SizedBox.expand()
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: isAnalysisRepeatActive
                      ? _MobileRepeatProgressControls(
                          depth: analysisRepeatCurrentDepth,
                          targetDepth: analysisTargetDepth,
                          remaining: analysisRepeatRemaining,
                          onCancel: onCancelAnalysisRepeat,
                        )
                      : _MobileRepeatIdleControls(
                          value: analysisRepeatRequestCount,
                          enabled: canStartAnalysisRepeat,
                          onStart: onStartAnalysisRepeat,
                          onChanged: onSetAnalysisRepeatCount,
                          onIncrement: onIncrementAnalysisRepeatCount,
                          onDecrement: onDecrementAnalysisRepeatCount,
                        ),
                ),
              ),
      ),
    );
  }
}

class _MobileRepeatIdleControls extends StatelessWidget {
  const _MobileRepeatIdleControls({
    required this.value,
    required this.enabled,
    required this.onStart,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int value;
  final bool enabled;
  final VoidCallback onStart;
  final ValueChanged<int> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: Row(
        children: [
          _MobileReanalysisButton(
            enabled: enabled,
            onPressed: onStart,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MobileRepeatCountSelector(
              value: value,
              enabled: enabled,
              onChanged: onChanged,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileReanalysisButton extends StatelessWidget {
  const _MobileReanalysisButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 56,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.replay_rounded, size: 31),
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF55C878),
          disabledForegroundColor: Colors.white30,
          backgroundColor: Colors.black.withAlpha(70),
          side: BorderSide(
            color: enabled ? const Color(0xFF55C878) : Colors.white24,
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _MobileRepeatProgressControls extends StatelessWidget {
  const _MobileRepeatProgressControls({
    required this.depth,
    required this.targetDepth,
    required this.remaining,
    required this.onCancel,
  });

  final int depth;
  final int targetDepth;
  final int remaining;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 290),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MobileSquareDepthProgress(
            depth: depth,
            targetDepth: targetDepth,
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              'Noch $remaining',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox.square(
            dimension: 56,
            child: IconButton(
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.stop_rounded, size: 30),
              style: IconButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A5A),
                backgroundColor: Colors.black.withAlpha(70),
                side: const BorderSide(
                  color: Color(0xFFFF5A5A),
                  width: 1.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRepeatCountSelector extends StatefulWidget {
  const _MobileRepeatCountSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  State<_MobileRepeatCountSelector> createState() =>
      _MobileRepeatCountSelectorState();
}

class _MobileRepeatCountSelectorState
    extends State<_MobileRepeatCountSelector> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode(debugLabel: 'MobileAnalysisRepeatCountInput')
      ..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _MobileRepeatCountSelector oldWidget) {
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

    _commitValue();
  }

  void _handleTextChanged(String rawValue) {
    final parsedValue = int.tryParse(rawValue);
    if (parsedValue == null || parsedValue < 1 || parsedValue > 1000) {
      return;
    }

    widget.onChanged(parsedValue);
  }

  void _commitValue() {
    final parsedValue = int.tryParse(_textController.text);
    final normalizedValue =
        (parsedValue ?? widget.value).clamp(1, 1000).toInt();
    widget.onChanged(normalizedValue);
    _writeValue(normalizedValue);
  }

  void _writeCanonicalValue() {
    _writeValue(widget.value);
  }

  void _writeValue(int value) {
    final text = '$value';
    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  int _nextFiveStep(int value) {
    if (value <= 1) {
      return 5;
    }

    final remainder = value % 5;
    return (remainder == 0 ? value + 5 : value + (5 - remainder))
        .clamp(1, 1000)
        .toInt();
  }

  int _previousFiveStep(int value) {
    if (value <= 5) {
      return 1;
    }

    final remainder = value % 5;
    return (remainder == 0 ? value - 5 : value - remainder)
        .clamp(1, 1000)
        .toInt();
  }

  void _applyValue(int value) {
    final normalizedValue = value.clamp(1, 1000).toInt();
    widget.onChanged(normalizedValue);
    _writeValue(normalizedValue);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.enabled ? Colors.white54 : Colors.white24;

    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(70),
          border: Border.all(color: borderColor, width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
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
                    const _MobileAnalysisRepeatRangeFormatter(),
                  ],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    counterText: '',
                  ),
                  style: TextStyle(
                    color: widget.enabled ? Colors.white : Colors.white38,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  onChanged: _handleTextChanged,
                  onSubmitted: (_) => _focusNode.unfocus(),
                  onTapOutside: (_) => _focusNode.unfocus(),
                ),
              ),
              SizedBox(
                width: 30,
                child: Column(
                  children: [
                    Expanded(
                      child: _MobileCountIconButton(
                        icon: Icons.add,
                        enabled: widget.enabled && widget.value < 1000,
                        onPressed: widget.onIncrement,
                        top: true,
                        drawLeftDivider: true,
                      ),
                    ),
                    Expanded(
                      child: _MobileCountIconButton(
                        icon: Icons.remove,
                        enabled: widget.enabled && widget.value > 1,
                        onPressed: widget.onDecrement,
                        top: false,
                        drawLeftDivider: true,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 34,
                child: Column(
                  children: [
                    Expanded(
                      child: _MobileCountLabelButton(
                        label: '++',
                        enabled: widget.enabled && widget.value < 1000,
                        onPressed: () {
                          _applyValue(_nextFiveStep(widget.value));
                        },
                        top: true,
                      ),
                    ),
                    Expanded(
                      child: _MobileCountLabelButton(
                        label: '--',
                        enabled: widget.enabled && widget.value > 1,
                        onPressed: () {
                          _applyValue(_previousFiveStep(widget.value));
                        },
                        top: false,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 38,
                child: _MobileCountResetButton(
                  enabled: widget.enabled && widget.value != 1,
                  onPressed: () => _applyValue(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileAnalysisRepeatRangeFormatter extends TextInputFormatter {
  const _MobileAnalysisRepeatRangeFormatter();

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

class _MobileCountIconButton extends StatelessWidget {
  const _MobileCountIconButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
    required this.top,
    required this.drawLeftDivider,
  });

  final IconData icon;
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
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }
}

class _MobileCountLabelButton extends StatelessWidget {
  const _MobileCountLabelButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
    required this.top,
  });

  final String label;
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
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white30,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCountResetButton extends StatelessWidget {
  const _MobileCountResetButton({
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
            size: 23,
            color: enabled ? Colors.white : Colors.white30,
          ),
        ),
      ),
    );
  }
}

class _MobileSquareDepthProgress extends StatelessWidget {
  const _MobileSquareDepthProgress({
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

    return SizedBox.square(
      dimension: 56,
      child: CustomPaint(
        painter: _MobileSquareDepthProgressPainter(progress: progress),
        child: Center(
          child: Text(
            '$depth',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileSquareDepthProgressPainter extends CustomPainter {
  const _MobileSquareDepthProgressPainter({required this.progress});

  final double progress;

  static const Color _pendingColor = Color(0xFF536E5C);
  static const Color _completedColor = Color(0xFF2FA45B);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final roundedRect = RRect.fromRectAndRadius(
      rect.deflate(1),
      const Radius.circular(14),
    );

    canvas.save();
    canvas.clipRRect(roundedRect);
    canvas.drawRect(rect, Paint()..color = _pendingColor);

    if (progress > 0) {
      final radius = size.longestSide * 0.78;
      final sweepRect = Rect.fromCircle(center: rect.center, radius: radius);
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
          ..color = Colors.white.withAlpha(215)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();
    canvas.drawRRect(
      roundedRect,
      Paint()
        ..color = Colors.white54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  @override
  bool shouldRepaint(
    covariant _MobileSquareDepthProgressPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

class _SoloModeInfo extends StatelessWidget {
  const _SoloModeInfo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solo-Modus',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFF55C878),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Du ziehst für Weiß und Schwarz.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xFFE6E6E6),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GameInfoRow extends StatelessWidget {
  const _GameInfoRow({required this.data});

  final _GameInfoRowData data;

  static const Color _accentColor = Color(0xFF5C9DFF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '${data.label}: ',
              style: const TextStyle(
                color: _accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: data.value,
              style: TextStyle(
                color: Colors.white.withAlpha(225),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameInfoRowData {
  const _GameInfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}
