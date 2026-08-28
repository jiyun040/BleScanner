class BleDevice {
  const BleDevice({
    required this.name,
    required this.address,
    required this.rssi,
  });

  final String name;
  final String address;
  final int rssi;

  bool get hasMacAddress => RegExp(
    r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$',
    caseSensitive: false,
  ).hasMatch(address);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDevice &&
          name == other.name &&
          address == other.address &&
          rssi == other.rssi;

  @override
  int get hashCode => Object.hash(name, address, rssi);
}
