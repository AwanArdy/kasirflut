class TransactionModel {
  final String id;
  final String invoiceNumber;
  final String status;
  final String paymentMethod;
  final double subtotal;
  final double tax;
  final double discount;
  final double totalAmount;
  final double amountReceived;
  final double changeAmount;
  final String customerName;
  final String tableName;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.totalAmount,
    required this.amountReceived,
    required this.changeAmount,
    required this.customerName,
    required this.tableName,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'CASH',
      subtotal: (json['subtotal'] as num? ?? 0).toDouble(),
      tax: (json['tax'] as num? ?? 0).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
      amountReceived: (json['amountReceived'] as num? ?? 0).toDouble(),
      changeAmount: (json['changeAmount'] as num? ?? 0).toDouble(),
      customerName: json['customerName'] as String? ?? 'Walk-in Customer',
      tableName: json['tableName'] as String? ?? 'Table 01',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
