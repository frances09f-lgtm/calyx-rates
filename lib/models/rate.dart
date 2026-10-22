class CountryRates {
  final String countryID;
  final List<Rate> rates;

  const CountryRates({required this.countryID, required this.rates});

  String? get flagPath => rates.isEmpty ? null : rates.first.countryFlag;
}

class Rate {
  final String currencyCode;
  final String currencyName;
  final String rate;
  final String minAmount;
  final String maxAmount;
  final String countryFlag;
  final String countryID;

  const Rate({
    required this.currencyCode,
    required this.currencyName,
    required this.rate,
    required this.minAmount,
    required this.maxAmount,
    required this.countryFlag,
    required this.countryID,
  });

  factory Rate.fromJson(Map<String, dynamic> json) => Rate(
        currencyCode: json['currencyCode'] as String? ?? '',
        currencyName: json['currencyName'] as String? ?? '',
        rate: json['rate'] as String? ?? '',
        minAmount: json['minAmount'] as String? ?? '',
        maxAmount: json['maxAmount'] as String? ?? '',
        countryFlag: json['countryFlag'] as String? ?? '',
        countryID: json['countryID'] as String? ?? '',
      );
}
