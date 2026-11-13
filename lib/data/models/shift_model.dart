class ShiftModel {
  final String id;
  final String? serverId;
  final String outletId;
  final String staffId;
  final String shiftName; // 'morning' | 'evening'
  final int startingCashIdr;
  final int cashSalesIdr;
  final int qrisSalesIdr;
  final int? actualPhysicalCashIdr;
  final int? differenceIdr;
  final String? notes;
  final String status; // 'open' | 'balanced' | 'variance'
  final DateTime openedAt;
  final DateTime? closedAt;
  final String syncStatus; // 'synced' | 'pending_open' | 'pending_close'

  ShiftModel({
    required this.id,
    this.serverId,
    required this.outletId,
    this.staffId = '',
    required this.shiftName,
    required this.startingCashIdr,
    this.cashSalesIdr = 0,
    this.qrisSalesIdr = 0,
    this.actualPhysicalCashIdr,
    this.differenceIdr,
    this.notes,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.syncStatus = 'synced',
  });

  int get expectedCashIdr => startingCashIdr + cashSalesIdr;
  double get openingCash => startingCashIdr.toDouble();
  bool get isOpen => status == 'open';

  ShiftModel copyWith({
    String? id,
    String? serverId,
    String? outletId,
    String? staffId,
    String? shiftName,
    int? startingCashIdr,
    int? cashSalesIdr,
    int? qrisSalesIdr,
    int? actualPhysicalCashIdr,
    int? differenceIdr,
    String? notes,
    String? status,
    DateTime? openedAt,
    DateTime? closedAt,
    String? syncStatus,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      outletId: outletId ?? this.outletId,
      staffId: staffId ?? this.staffId,
      shiftName: shiftName ?? this.shiftName,
      startingCashIdr: startingCashIdr ?? this.startingCashIdr,
      cashSalesIdr: cashSalesIdr ?? this.cashSalesIdr,
      qrisSalesIdr: qrisSalesIdr ?? this.qrisSalesIdr,
      actualPhysicalCashIdr:
          actualPhysicalCashIdr ?? this.actualPhysicalCashIdr,
      differenceIdr: differenceIdr ?? this.differenceIdr,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ShiftModel(
      id: id,
      serverId: id,
      outletId: json['outletId'] as String? ?? '',
      staffId: json['staffId'] as String? ?? '',
      shiftName: json['shiftName'] as String? ?? 'morning',
      startingCashIdr: (json['startingCashIdr'] as num?)?.toInt() ?? 0,
      cashSalesIdr: (json['cashSalesIdr'] as num?)?.toInt() ?? 0,
      qrisSalesIdr: (json['qrisSalesIdr'] as num?)?.toInt() ?? 0,
      actualPhysicalCashIdr:
          (json['actualPhysicalCashIdr'] as num?)?.toInt(),
      differenceIdr: (json['differenceIdr'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'open',
      openedAt: json['openedAt'] != null
          ? DateTime.parse(json['openedAt'] as String)
          : DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      syncStatus: 'synced',
    );
  }

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as String,
      serverId: map['server_id'] as String?,
      outletId: map['outlet_id'] as String? ?? '',
      staffId: map['staff_id'] as String? ?? '',
      shiftName: map['shift_name'] as String? ?? 'morning',
      startingCashIdr: (map['starting_cash_idr'] as num).toInt(),
      cashSalesIdr: (map['cash_sales_idr'] as num? ?? 0).toInt(),
      qrisSalesIdr: (map['qris_sales_idr'] as num? ?? 0).toInt(),
      actualPhysicalCashIdr:
          (map['actual_physical_cash_idr'] as num?)?.toInt(),
      differenceIdr: (map['difference_idr'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      status: map['status'] as String? ?? 'open',
      openedAt: DateTime.parse(map['opened_at'] as String),
      closedAt: map['closed_at'] != null
          ? DateTime.parse(map['closed_at'] as String)
          : null,
      syncStatus: map['sync_status'] as String? ?? 'synced',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'outlet_id': outletId,
      'staff_id': staffId,
      'shift_name': shiftName,
      'starting_cash_idr': startingCashIdr,
      'cash_sales_idr': cashSalesIdr,
      'qris_sales_idr': qrisSalesIdr,
      'actual_physical_cash_idr': actualPhysicalCashIdr,
      'difference_idr': differenceIdr,
      'notes': notes,
      'status': status,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'sync_status': syncStatus,
    };
  }
}
