class ShiftModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final double openingCash;
  final String status;
  final DateTime startedAt;

  ShiftModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.openingCash,
    required this.status,
    required this.startedAt
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String, 
      employeeId: json['employeeId'] as String, 
      employeeName: json['employeeName']?['name'] as String? ?? '', 
      openingCash: (json['openingCash'] as num).toDouble(), 
      status: json['status'] as String? ?? 'OPEN', 
      startedAt: DateTime.parse(json['startedAt'] as String)
    );
  }
}

class ShiftSummaryModel {
  final int transactionCount;
  final double grossSales;
  final double openingCash;
  final double cashSales;
  final double expectedCash;
  final double countedCash;
  final double difference;

  ShiftSummaryModel({
    required this.transactionCount,
    required this.grossSales,
    required this.openingCash,
    required this.cashSales,
    required this.expectedCash,
    required this.countedCash,
    required this.difference
  });

  factory ShiftSummaryModel.fromJson(Map<String, dynamic> json) {
    return ShiftSummaryModel(
      transactionCount: json['transactionCount'] as int? ?? 0, 
      grossSales: (json['grossSales'] as num? ?? 0).toDouble(), 
      openingCash: (json['openingCash'] as num? ?? 0).toDouble(), 
      cashSales: (json['cashSales'] as num? ?? 0).toDouble(), 
      expectedCash: (json['expectedCash'] as num? ?? 0).toDouble(), 
      countedCash: (json['countedCash'] as num? ?? 0).toDouble(), 
      difference: (json['difference'] as num? ?? 0).toDouble()
    );
  }
}
