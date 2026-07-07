enum BotPersonalitySource {
  chessiverse(label: 'Chessiverse'),
  fritz19(label: 'Fritz19'),
  random(label: 'Alles Zufällig');

  const BotPersonalitySource({required this.label});

  /// UI-Name der Persönlichkeitsfamilie.
  ///
  /// Im Code heißt das "Source", gemeint ist hier aber keine separate Bot-Art,
  /// sondern die Familie/der Typ innerhalb der Persönlichkeitsauswahl.
  final String label;

  bool get isRandom {
    return this == BotPersonalitySource.random;
  }
}
