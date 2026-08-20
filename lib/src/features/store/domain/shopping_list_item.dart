class ShoppingListItem {
  const ShoppingListItem({
    required this.id,
    required this.name,
    this.done = false,
  });

  final String id;
  final String name;
  final bool done;

  ShoppingListItem copyWith({bool? done}) => ShoppingListItem(id: id, name: name, done: done ?? this.done);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'done': done};

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) => ShoppingListItem(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        done: map['done'] as bool? ?? false,
      );
}
