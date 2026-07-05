enum BotPersonality {
  none(label: 'Ohne Persönlichkeit', aggression: 0.0, complexity: 0.0),

  random(label: 'Zufällig', aggression: 0.0, complexity: 0.0),

  hunter(label: 'Hunter', aggression: 1.0, complexity: -1.0),

  guardian(label: 'Guardian', aggression: -1.0, complexity: -1.0),

  savage(label: 'Savage', aggression: 1.0, complexity: 1.0),

  observer(label: 'Observer', aggression: -1.0, complexity: 1.0),

  mediator(label: 'Mediator', aggression: 0.0, complexity: 0.0);

  const BotPersonality({
    required this.label,
    required this.aggression,
    required this.complexity,
  });

  final String label;

  /// -1.0 = defensiv
  ///  0.0 = neutral/adaptiv
  ///  1.0 = aggressiv
  final double aggression;

  /// -1.0 = vereinfachend
  ///  0.0 = neutral/adaptiv
  ///  1.0 = verkomplizierend
  final double complexity;

  bool get isNone => this == BotPersonality.none;

  bool get isRandom => this == BotPersonality.random;

  bool get isConcretePersonality => !isNone && !isRandom;

  static List<BotPersonality> get concretePersonalities {
    return const [
      BotPersonality.hunter,
      BotPersonality.guardian,
      BotPersonality.savage,
      BotPersonality.observer,
      BotPersonality.mediator,
    ];
  }
}
