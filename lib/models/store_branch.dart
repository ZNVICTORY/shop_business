/// 门店元数据（多门店切换）。
class StoreBranch {
  const StoreBranch({
    required this.id,
    required this.name,
    required this.city,
  });

  final String id;
  final String name;
  final String city;

  String get subtitle => city;
}
