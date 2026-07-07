enum Fritz19Personality {
  random(label: 'Zufällig'),
  allrounder(label: 'Allrounder'),
  attacker(label: 'Attacker'),
  swindler(label: 'Swindler'),
  positional(label: 'Positional'),
  timid(label: 'Timid'),
  endgameCrack(label: 'Endgame Crack'),
  abstractStyle(label: 'Abstract');

  const Fritz19Personality({required this.label});

  final String label;

  bool get isRandom {
    return this == Fritz19Personality.random;
  }

  bool get isAbstract {
    return this == Fritz19Personality.abstractStyle;
  }

  bool get isConcretePersonality {
    return !isRandom;
  }

  static List<Fritz19Personality> get concretePersonalities {
    return const [
      Fritz19Personality.allrounder,
      Fritz19Personality.attacker,
      Fritz19Personality.swindler,
      Fritz19Personality.positional,
      Fritz19Personality.timid,
      Fritz19Personality.endgameCrack,
      Fritz19Personality.abstractStyle,
    ];
  }
}
