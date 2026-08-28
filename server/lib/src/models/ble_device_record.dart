class BleDeviceRecord {
  const BleDeviceRecord({
    required this.blueNo,
    required this.macAddress,
    required this.createDate,
  });

  final String blueNo;
  final String macAddress;
  final String createDate;

  Map<String, Object> toJson() => {
    'blueNo': blueNo,
    'macAddress': macAddress,
    'createDate': createDate,
  };
}
