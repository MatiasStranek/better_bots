import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/chess_engine.dart';
import '../engine/stockfish_windows_engine.dart';

class StockfishTestPage extends StatefulWidget {
  const StockfishTestPage({super.key});

  @override
  State<StockfishTestPage> createState() => _StockfishTestPageState();
}

class _StockfishTestPageState extends State<StockfishTestPage> {
  final ChessEngine _engine = StockfishWindowsEngine();

  StreamSubscription<String>? _engineSubscription;

  String _status = 'Noch nicht gestartet';
  String _lastOutput = '-';
  String _bestMove = '-';

  int _skillLevel = 0;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();

    _engineSubscription = _engine.output.listen((line) {
      if (!mounted) return;

      setState(() {
        _lastOutput = line;
      });
    });
  }

  Future<void> _startStockfish() async {
    setState(() {
      _isBusy = true;
      _status = 'Starte Stockfish...';
      _lastOutput = '-';
      _bestMove = '-';
    });

    try {
      await _engine.start();

      setState(() {
        _status = 'Stockfish ist bereit';
      });
    } catch (e) {
      setState(() {
        _status = 'Fehler beim Starten';
        _lastOutput = e.toString();
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _calculateMove() async {
    setState(() {
      _isBusy = true;
      _status = 'Berechne Bot-Zug...';
      _bestMove = '-';
    });

    try {
      final move = await _engine.getBestMoveFromStartPosition(
        skillLevel: _skillLevel,
        moveTimeMs: 800,
      );

      setState(() {
        _bestMove = move;
        _status = 'Bot-Zug berechnet';
      });
    } catch (e) {
      setState(() {
        _status = 'Fehler beim Berechnen';
        _lastOutput = e.toString();
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _stopStockfish() async {
    setState(() {
      _isBusy = true;
      _status = 'Stoppe Stockfish...';
    });

    try {
      await _engine.stop();

      setState(() {
        _status = 'Gestoppt';
        _bestMove = '-';
        _lastOutput = '-';
      });
    } catch (e) {
      setState(() {
        _status = 'Fehler beim Stoppen';
        _lastOutput = e.toString();
      });
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  @override
  void dispose() {
    _engineSubscription?.cancel();
    _engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = List.generate(21, (index) => index);

    return Scaffold(
      appBar: AppBar(title: const Text('Better Bots')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_status'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isBusy ? null : _startStockfish,
              child: const Text('Stockfish starten'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isBusy ? null : _stopStockfish,
              child: const Text('Stockfish stoppen'),
            ),

            const SizedBox(height: 24),

            const Text('Skill Level'),
            DropdownButton<int>(
              value: _skillLevel,
              items: levels.map((level) {
                return DropdownMenuItem<int>(
                  value: level,
                  child: Text('Level $level'),
                );
              }).toList(),
              onChanged: _isBusy
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _skillLevel = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isBusy ? null : _calculateMove,
              child: const Text('Bot-Zug aus Startposition berechnen'),
            ),

            const SizedBox(height: 24),

            Text('Bot-Zug:', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(
              _bestMove,
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 24),

            const Text('Letzte Engine-Ausgabe:'),
            const SizedBox(height: 8),
            SelectableText(_lastOutput),
          ],
        ),
      ),
    );
  }
}
