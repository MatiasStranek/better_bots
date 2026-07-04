class BoardMove {
  const BoardMove({required this.from, required this.to, this.promotion});

  final String from;
  final String to;
  final String? promotion;
}
