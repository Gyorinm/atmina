class CustomerOrderRecord {
  const CustomerOrderRecord({
    required this.orderCode,
    required this.storeCode,
    required this.storeName,
    required this.total,
    required this.itemsCount,
    required this.createdAt,
  });

  final String orderCode;
  final String storeCode;
  final String storeName;
  final double total;
  final int itemsCount;
  final String createdAt;

  Map<String, dynamic> toMap() => {
        'order_code': orderCode,
        'store_code': storeCode,
        'store_name': storeName,
        'total': total,
        'items_count': itemsCount,
        'created_at': createdAt,
      };

  factory CustomerOrderRecord.fromMap(Map<String, dynamic> map) => CustomerOrderRecord(
        orderCode: map['order_code'] as String,
        storeCode: (map['store_code'] as String?) ?? '',
        storeName: (map['store_name'] as String?) ?? '',
        total: (map['total'] as num).toDouble(),
        itemsCount: (map['items_count'] as num?)?.toInt() ?? 0,
        createdAt: (map['created_at'] as String?) ?? '',
      );
}
