class AdminLocationOption {
  const AdminLocationOption({
    required this.id,
    required this.name,
    required this.data,
  });

  final String id;
  final String name;
  final Map<String, dynamic> data;

  factory AdminLocationOption.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return AdminLocationOption(
      id: id,
      name: (data['name'] ?? '').toString(),
      data: data,
    );
  }
}
