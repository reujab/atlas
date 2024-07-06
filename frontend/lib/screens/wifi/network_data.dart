class NetworkData {
  NetworkData({
    required this.mac,
    required this.name,
    required this.secure,
    required this.strength,
  });

  String mac;
  String name;
  bool secure;
  int strength;
}
