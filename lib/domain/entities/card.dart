import 'package:equatable/equatable.dart';

/// Pure domain entity representing a Clash Royale card.
/// No serialization logic — that belongs in the data layer.
class CrCard extends Equatable {
  final int id;
  final String name;
  final int? level;
  final int? maxLevel;
  final String iconUrl;

  const CrCard({
    required this.id,
    required this.name,
    this.level,
    this.maxLevel,
    required this.iconUrl,
  });

  @override
  List<Object?> get props => [id, name, level, maxLevel, iconUrl];
}
