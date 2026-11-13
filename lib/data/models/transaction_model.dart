import 'dart:convert';

class SaleItemSnapshot {
  final String productId;
  final String name;
  final int qty;
  final int unitPriceIdr;
  final int lineTotalIdr;

  SaleItemSnapshot({
    required this.productId,
    required this.name,
    required this.qty,
    required this.unitPriceIdr,
    required this.lineTotalIdr,
  });

  factory SaleItemSnapshot.fromJson(Map<String, dynamic> json) {
    return SaleItemSnapshot(
      productId: json['productId'] as String,
      name: json['name'] as String? ?? '',
      qty: (json['qty'] as num).toInt(),
      unitPriceIdr: (json['unitPriceIdr'] as num).toInt(),
      lineTotalIdr: (json['lineTotalIdr'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'unitPriceIdr': unitPriceIdr,
        'lineTotalIdr': lineTotalIdr,
      };
}

class TransactionModel {
  final String id;
  final String idempotencyKey;
  final String? serverId;
  final String noNota;
  final String? shiftId;
  final String orderType; // 'dine_in' | 'takeaway' | 'delivery'
  final String paymentMethod; // 'cash' | 'qris' | 'debit' | 'bank_transfer'
  final String? customerName;
  final int subtotalIdr;
  final int discountIdr;
  final int taxIdr;
  final int totalIdr;
  final int amountReceivedIdr;
  final int changeIdr;
  final String status;
  final List<SaleItemSnapshot> items;
  final DateTime soldAt;
  final String syncStatus; // 'pending' | 'synced' | 'failed'
  final String? syncError;

  TransactionModel({
    required this.id,
    required this.idempotencyKey,
    this.serverId,
    required this.noNota,
    this.shiftId,
    required this.orderType,
    required this.paymentMethod,
    this.customerName,
    required this.subtotalIdr,
    required this.discountIdr,
    required this.taxIdr,
    required this.totalIdr,
    this.amountReceivedIdr = 0,
    this.changeIdr = 0,
    this.status = 'paid',
    required this.items,
    required this.soldAt,
    this.syncStatus = 'pending',
    this.syncError,
  });

  bool get isOfflinePending => syncStatus == 'pending';

  factory TransactionModel.fromServerJson(
    Map<String, dynamic> json, {
    required String idempotencyKey,
    String? localId,
    String? shiftId,
    int amountReceivedIdr = 0,
    int changeIdr = 0,
  }) {
    final serverId = json['id'] as String;
    final rawItems = (json['items'] as List? ?? []);
    return TransactionModel(
      id: localId ?? serverId,
      idempotencyKey: idempotencyKey,
      serverId: serverId,
      noNota: json['noNota'] as String? ?? '',
      shiftId: shiftId,
      orderType: json['orderType'] as String? ?? 'dine_in',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      customerName: json['customerName'] as String?,
      subtotalIdr: (json['subtotalIdr'] as num?)?.toInt() ?? 0,
      discountIdr: (json['discountIdr'] as num?)?.toInt() ?? 0,
      taxIdr: (json['taxIdr'] as num?)?.toInt() ?? 0,
      totalIdr: (json['totalIdr'] as num?)?.toInt() ?? 0,
      amountReceivedIdr: amountReceivedIdr,
      changeIdr: changeIdr,
      status: json['status'] as String? ?? 'paid',
      items: rawItems
          .map((e) => SaleItemSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      soldAt: json['soldAt'] != null
          ? DateTime.parse(json['soldAt'] as String)
          : DateTime.now(),
      syncStatus: 'synced',
    );
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final decoded = jsonDecode(map['items_json'] as String) as List;
    return TransactionModel(
      id: map['id'] as String,
      idempotencyKey: map['idempotency_key'] as String,
      serverId: map['server_id'] as String?,
      noNota: map['no_nota'] as String,
      shiftId: map['shift_id'] as String?,
      orderType: map['order_type'] as String,
      paymentMethod: map['payment_method'] as String,
      customerName: map['customer_name'] as String?,
      subtotalIdr: (map['subtotal_idr'] as num).toInt(),
      discountIdr: (map['discount_idr'] as num? ?? 0).toInt(),
      taxIdr: (map['tax_idr'] as num? ?? 0).toInt(),
      totalIdr: (map['total_idr'] as num).toInt(),
      amountReceivedIdr: (map['amount_received_idr'] as num? ?? 0).toInt(),
      changeIdr: (map['change_idr'] as num? ?? 0).toInt(),
      status: map['status'] as String? ?? 'paid',
      items: decoded
          .map((e) => SaleItemSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
      soldAt: DateTime.parse(map['sold_at'] as String),
      syncStatus: map['sync_status'] as String? ?? 'pending',
      syncError: map['sync_error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idempotency_key': idempotencyKey,
      'server_id': serverId,
      'no_nota': noNota,
      'shift_id': shiftId,
      'order_type': orderType,
      'payment_method': paymentMethod,
      'customer_name': customerName,
      'subtotal_idr': subtotalIdr,
      'discount_idr': discountIdr,
      'tax_idr': taxIdr,
      'total_idr': totalIdr,
      'amount_received_idr': amountReceivedIdr,
      'change_idr': changeIdr,
      'status': status,
      'items_json': jsonEncode(items.map((e) => e.toJson()).toList()),
      'sold_at': soldAt.toIso8601String(),
      'sync_status': syncStatus,
      'sync_error': syncError,
    };
  }

  Map<String, dynamic> toPosSalePayload() {
    return {
      'orderType': orderType,
      'paymentMethod': paymentMethod,
      'discountIdr': discountIdr,
      'taxIdr': taxIdr,
      if (customerName != null && customerName!.isNotEmpty)
        'customerName': customerName,
      'items': items
          .map((i) => {
                'productId': i.productId,
                'qty': i.qty,
                'unitPriceIdr': i.unitPriceIdr,
              })
          .toList(),
    };
  }
}
