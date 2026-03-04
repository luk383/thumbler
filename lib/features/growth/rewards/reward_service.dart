import 'dart:math';

enum RewardType { rareCard, xpBoost, newCategory }

extension RewardTypeDetails on RewardType {
  String get emoji => switch (this) {
    RewardType.rareCard => '🃏',
    RewardType.xpBoost => '⚡',
    RewardType.newCategory => '🌟',
  };

  String get title => switch (this) {
    RewardType.rareCard => 'Rare Card Unlocked',
    RewardType.xpBoost => 'XP Boost Active',
    RewardType.newCategory => 'New Category Unlocked',
  };

  String get description => switch (this) {
    RewardType.rareCard => 'A special rare lesson will appear in your feed.',
    RewardType.xpBoost => '+20% XP for the rest of today.',
    RewardType.newCategory => 'A new topic category is now available.',
  };
}

class RewardService {
  static final _random = Random();

  static RewardType pickRandom() {
    final values = RewardType.values;
    return values[_random.nextInt(values.length)];
  }
}
