class ImportCalculator {
  static const double cigarDutyPerKg = 440.93;
  static const double vatRate = 0.20;

  static const double defaultWeightFactor = 0.064;

  static double estimateWeightFromSize({
    required int ringGauge,
    required int lengthMm,
  }) {
    final lengthInches = lengthMm / 25.4;
    final estimated = lengthInches * ringGauge * defaultWeightFactor;
    return double.parse(estimated.toStringAsFixed(1));
  }

  static double duty(double weightGrams) {
    return (weightGrams / 1000) * cigarDutyPerKg;
  }

  static double vat(double euPrice, double dutyAmount) {
    return (euPrice + dutyAmount) * vatRate;
  }

  static double landed(double euPrice, double weightGrams) {
    final dutyAmount = duty(weightGrams);
    final vatAmount = vat(euPrice, dutyAmount);
    return euPrice + dutyAmount + vatAmount;
  }

  static double boxWeight(double weightPerCigarGrams, int boxQuantity) {
    return weightPerCigarGrams * boxQuantity;
  }

  static double boxDuty(double weightPerCigarGrams, int boxQuantity) {
    return duty(boxWeight(weightPerCigarGrams, boxQuantity));
  }

  static double boxVat(
    double euBoxPrice,
    double weightPerCigarGrams,
    int boxQuantity,
  ) {
    final dutyAmount = boxDuty(weightPerCigarGrams, boxQuantity);
    return vat(euBoxPrice, dutyAmount);
  }

  static double boxLanded(
    double euBoxPrice,
    double weightPerCigarGrams,
    int boxQuantity,
  ) {
    final dutyAmount = boxDuty(weightPerCigarGrams, boxQuantity);
    final vatAmount = vat(euBoxPrice, dutyAmount);
    return euBoxPrice + dutyAmount + vatAmount;
  }

  static double landedPerCigarFromBox(
    double euBoxPrice,
    double weightPerCigarGrams,
    int boxQuantity,
  ) {
    if (boxQuantity <= 0) return 0;
    return boxLanded(euBoxPrice, weightPerCigarGrams, boxQuantity) /
        boxQuantity;
  }
}
