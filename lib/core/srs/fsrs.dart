import 'dart:math';

// ---------------------------------------------------------------------------
// FSRS v4 — Free Spaced Repetition Scheduler
// Reference: https://github.com/open-spaced-repetition/fsrs4anki
//
// Grades: 1=Again, 2=Hard, 3=Good, 4=Easy
// Key insight: stability ≈ interval in days (at 90% desired retention)
// ---------------------------------------------------------------------------

const _decay = -0.5;
// FACTOR = 0.9^(1/DECAY) - 1 = 0.9^(-2) - 1 = 19/81
const _factor = 19.0 / 81.0;
const _requestedRetention = 0.9;

/// Default FSRS v4 weights (17 parameters).
const _w = [
  0.4072,  // w[0]:  S₀ for grade 1 (Again)
  1.1829,  // w[1]:  S₀ for grade 2 (Hard)
  3.1262,  // w[2]:  S₀ for grade 3 (Good)
  15.4722, // w[3]:  S₀ for grade 4 (Easy)
  7.2102,  // w[4]:  initial difficulty base
  0.5316,  // w[5]:  initial difficulty decay
  1.0651,  // w[6]:  difficulty update step
  0.0589,  // w[7]:  mean-reversion weight
  1.54575, // w[8]:  recall stability growth exponent
  0.1192,  // w[9]:  stability decay exponent
  1.01925, // w[10]: retrievability factor
  1.9323,  // w[11]: forgetting stability base
  0.11,    // w[12]: difficulty exponent (forgetting)
  0.29,    // w[13]: stability exponent (forgetting)
  2.27,    // w[14]: retrievability factor (forgetting)
  0.25,    // w[15]: hard penalty
  2.9898,  // w[16]: easy bonus
];

class FsrsResult {
  const FsrsResult({
    required this.stability,
    required this.difficulty,
    required this.intervalDays,
  });
  final double stability;
  final double difficulty;
  final int intervalDays;
}

class Fsrs {
  const Fsrs();

  // ── Public entry point ────────────────────────────────────────────────────

  /// Compute new FSRS state after a review.
  ///
  /// [grade] 1=Again, 2=Hard, 3=Good, 4=Easy
  /// [currentStability] 0.0 for a brand-new card
  /// [currentDifficulty] 0.0 for a brand-new card
  /// [elapsedDays] days since last review (0 for first review)
  FsrsResult review({
    required int grade,
    required double currentStability,
    required double currentDifficulty,
    required int elapsedDays,
  }) {
    assert(grade >= 1 && grade <= 4);

    final double newS;
    final double newD;

    if (currentStability == 0.0) {
      // First review — initialise from grade
      newS = _initStability(grade);
      newD = _initDifficulty(grade);
    } else {
      final r = _retrievability(elapsedDays, currentStability);
      newS = grade == 1
          ? _stabilityAfterForgetting(currentDifficulty, currentStability, r)
          : _stabilityAfterRecall(currentDifficulty, currentStability, r, grade);
      newD = _nextDifficulty(currentDifficulty, grade);
    }

    final interval = _nextInterval(newS);
    return FsrsResult(stability: newS, difficulty: newD, intervalDays: interval);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  double _initStability(int grade) => max(_w[grade - 1], 0.1);

  double _initDifficulty(int grade) =>
      (_w[4] - exp(_w[5] * (grade - 1)) + 1).clamp(1.0, 10.0);

  /// R(t, S) = (1 + FACTOR * t / S) ^ DECAY
  double _retrievability(int elapsedDays, double stability) =>
      pow(1 + _factor * elapsedDays / stability, _decay).toDouble();

  /// Stability growth after a successful recall (grade >= 2).
  double _stabilityAfterRecall(double d, double s, double r, int grade) {
    final hardPenalty = grade == 2 ? _w[15] : 1.0;
    final easyBonus = grade == 4 ? _w[16] : 1.0;
    final newS = s *
        (exp(_w[8]) *
                (11 - d) *
                pow(s, -_w[9]) *
                (exp((1 - r) * _w[10]) - 1) *
                hardPenalty *
                easyBonus +
            1);
    return max(newS, 0.1);
  }

  /// Stability after forgetting (grade == 1, Again).
  double _stabilityAfterForgetting(double d, double s, double r) {
    final newS = _w[11] *
        pow(d, -_w[12]) *
        (pow(s + 1, _w[13]) - 1) *
        exp((1 - r) * _w[14]);
    return max(newS, 0.1);
  }

  /// Difficulty update with mean-reversion toward D₀(Easy=4).
  double _nextDifficulty(double d, int grade) {
    final nextD = d - _w[6] * (grade - 3);
    // Mean reversion: pull toward initial difficulty for Easy
    final meanReverted = _w[7] * _initDifficulty(4) + (1 - _w[7]) * nextD;
    return meanReverted.clamp(1.0, 10.0);
  }

  /// Next review interval in days targeting 90% retention.
  /// For FSRS v4: interval ≈ stability (elegant property of the model).
  int _nextInterval(double stability) {
    final interval =
        stability / _factor * (pow(_requestedRetention, 1 / _decay) - 1);
    return max(interval.round(), 1);
  }
}
