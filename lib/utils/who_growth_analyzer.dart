import 'dart:math' as math;

import 'who_growth_standards.dart';

class WhoGrowthAnalyzer {
  static GrowthAnalysis analyze({
    required int ageMonths,
    required String gender,
    required double heightCm,
    required double weightKg,
    double? headCm,
  }) {
    final sex = _normalizeGender(gender);
    final requestedAge = ageMonths;
    final age = ageMonths.clamp(0, 60);

    final height = _score(
      value: heightCm,
      table: _table('height', sex),
      ageMonths: age,
      label: 'Boy',
      unit: 'cm',
    );
    final weight = _score(
      value: weightKg,
      table: _table('weight', sex),
      ageMonths: age,
      label: 'Kilo',
      unit: 'kg',
    );
    final head = headCm == null || headCm <= 0
        ? null
        : _score(
            value: headCm,
            table: _table('head', sex),
            ageMonths: age,
            label: 'Baş çevresi',
            unit: 'cm',
          );

    return GrowthAnalysis(
      requestedAgeMonths: requestedAge,
      ageMonths: age,
      gender: sex,
      height: height,
      weight: weight,
      head: head,
    );
  }

  static String _normalizeGender(String gender) {
    final value = gender.toLowerCase().trim();
    if (value == 'kız' ||
        value == 'kiz' ||
        value == 'female' ||
        value == 'f') {
      return 'female';
    }
    return 'male';
  }

  static List<List<num>> _table(String measure, String sex) {
    switch ('$measure.$sex') {
      case 'height.female':
        return WhoGrowthStandards.height_female;
      case 'height.male':
        return WhoGrowthStandards.height_male;
      case 'weight.female':
        return WhoGrowthStandards.weight_female;
      case 'weight.male':
        return WhoGrowthStandards.weight_male;
      case 'head.female':
        return WhoGrowthStandards.head_female;
      case 'head.male':
        return WhoGrowthStandards.head_male;
    }
    return WhoGrowthStandards.height_male;
  }

  static GrowthScore _score({
    required double value,
    required List<List<num>> table,
    required int ageMonths,
    required String label,
    required String unit,
  }) {
    final row = table.firstWhere(
      (entry) => entry[0].toInt() == ageMonths,
      orElse: () => table.last,
    );
    final l = row[1].toDouble();
    final m = row[2].toDouble();
    final s = row[3].toDouble();
    final z = l == 0
        ? math.log(value / m) / s
        : (math.pow(value / m, l) - 1) / (l * s);

    return GrowthScore(
      label: label,
      value: value,
      unit: unit,
      median: m,
      zScore: z.toDouble(),
      percentile: _normalCdf(z.toDouble()) * 100,
      status: _statusForZ(z.toDouble(), label),
    );
  }

  static String _statusForZ(double z, String label) {
    if (z < -3) return '$label çok düşük';
    if (z < -2) return '$label düşük';
    if (z <= 2) return '$label normal aralıkta';
    if (z <= 3) return '$label yüksek';
    return '$label çok yüksek';
  }

  static double _normalCdf(double x) {
    return 0.5 * (1 + _erf(x / math.sqrt2));
  }

  static double _erf(double x) {
    final sign = x < 0 ? -1 : 1;
    final a = x.abs();
    const p = 0.3275911;
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    final t = 1 / (1 + p * a);
    final y =
        1 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-a * a);
    return sign * y;
  }
}

class GrowthAnalysis {
  const GrowthAnalysis({
    required this.requestedAgeMonths,
    required this.ageMonths,
    required this.gender,
    required this.height,
    required this.weight,
    this.head,
  });

  final int requestedAgeMonths;
  final int ageMonths;
  final String gender;
  final GrowthScore height;
  final GrowthScore weight;
  final GrowthScore? head;

  String get summary {
    final parts = [
      height.friendlyText,
      weight.friendlyText,
      ?head?.friendlyText,
    ];
    final ageText = requestedAgeMonths == ageMonths
        ? '$ageMonths. ay'
        : '$requestedAgeMonths. ay, WHO 0-60 ay tablosu sınırı nedeniyle $ageMonths. ay referansı';
    final hasFollowUp = [height, weight, ?head]
        .any((score) => score.needsFollowUp);
    final note = hasFollowUp
        ? ' Ölçümü çocuk doktorunuzla paylaşmanız önerilir.'
        : ' Düzenli takip etmeye devam edebilirsiniz.';
    return 'WHO büyüme standartlarına göre hazırlanmıştır. $ageText için ${parts.join(', ')}.$note';
  }
}

class GrowthScore {
  const GrowthScore({
    required this.label,
    required this.value,
    required this.unit,
    required this.median,
    required this.zScore,
    required this.percentile,
    required this.status,
  });

  final String label;
  final double value;
  final String unit;
  final double median;
  final double zScore;
  final double percentile;
  final String status;

  bool get needsFollowUp => zScore < -2 || zScore > 2;

  String get friendlyText {
    if (zScore < -3) return '$label beklenen aralığın belirgin altında';
    if (zScore < -2) return '$label beklenen aralığın altında';
    if (zScore <= 2) return '$label beklenen aralıkta';
    if (zScore <= 3) return '$label beklenen aralığın üzerinde';
    return '$label beklenen aralığın belirgin üzerinde';
  }

  String get shortText => friendlyText;

}
