class BotProfile {
  const BotProfile({
    required this.id,
    required this.displayName,
    required this.rating,
    this.defaultTemperature = 1.0,
    this.defaultTopP = 0.95,
  });

  final String id;
  final String displayName;
  final int rating;
  final double defaultTemperature;
  final double defaultTopP;

  String get infoLabel => 'Bot: $displayName';

  static const List<BotProfile> maia3Profiles = <BotProfile>[
    BotProfile(id: 'maia3_600', displayName: 'Maia 600', rating: 600),
    BotProfile(id: 'maia3_800', displayName: 'Maia 800', rating: 800),
    BotProfile(id: 'maia3_1000', displayName: 'Maia 1000', rating: 1000),
    BotProfile(id: 'maia3_1100', displayName: 'Maia 1100', rating: 1100),
    BotProfile(id: 'maia3_1200', displayName: 'Maia 1200', rating: 1200),
    BotProfile(id: 'maia3_1300', displayName: 'Maia 1300', rating: 1300),
    BotProfile(id: 'maia3_1400', displayName: 'Maia 1400', rating: 1400),
    BotProfile(id: 'maia3_1500', displayName: 'Maia 1500', rating: 1500),
    BotProfile(id: 'maia3_1600', displayName: 'Maia 1600', rating: 1600),
    BotProfile(id: 'maia3_1700', displayName: 'Maia 1700', rating: 1700),
    BotProfile(id: 'maia3_1800', displayName: 'Maia 1800', rating: 1800),
    BotProfile(id: 'maia3_1900', displayName: 'Maia 1900', rating: 1900),
    BotProfile(id: 'maia3_2000', displayName: 'Maia 2000', rating: 2000),
    BotProfile(id: 'maia3_2200', displayName: 'Maia 2200', rating: 2200),
    BotProfile(id: 'maia3_2400', displayName: 'Maia 2400', rating: 2400),
    BotProfile(id: 'maia3_2600', displayName: 'Maia 2600', rating: 2600),
  ];

  static const List<BotProfile> values = <BotProfile>[
    ...maia3Profiles,
  ];

  static BotProfile? byId(String id) {
    for (final profile in values) {
      if (profile.id == id) {
        return profile;
      }
    }

    return null;
  }
}
