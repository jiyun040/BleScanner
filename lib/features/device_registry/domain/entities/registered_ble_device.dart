class RegisteredBleDevice {
  const RegisteredBleDevice({
    required this.blueNo,
    required this.macAddress,
    required this.createDate,
  });

  final String blueNo;
  final String macAddress;
  final DateTime createDate;

  factory RegisteredBleDevice.fromJson(Map<String, Object?> map) {
    return RegisteredBleDevice(
      blueNo: map['blueNo'].toString(),
      macAddress: map['macAddress'].toString(),
      createDate: DateTime.parse(map['createDate'].toString()),
    );
  }
}
