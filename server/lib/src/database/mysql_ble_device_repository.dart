import 'package:mysql_client/exception.dart';
import 'package:mysql_client/mysql_client.dart';

import '../models/ble_device_record.dart';
import 'ble_device_repository.dart';

class MySqlBleDeviceRepository implements BleDeviceRepository {
  const MySqlBleDeviceRepository(this._pool);

  static const tableName = 'TB_BLE_DEVICE_MAP';

  final MySQLConnectionPool _pool;

  @override
  Future<void> checkConnection() async {
    try {
      await _pool.execute('SELECT 1');
    } on Object catch (error) {
      throw BleDatabaseException('PDAM_SERVER2 DB 연결 실패: $error');
    }
  }

  @override
  Future<BleDevicePage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    try {
      final countResult = await _pool.execute('''
        SELECT COUNT(*) AS totalCount
        FROM $tableName
      ''');
      final totalCount = int.parse(
        countResult.rows.first.assoc()['totalCount'] ?? '0',
      );
      final offset = (page - 1) * pageSize;
      final result = await _pool.execute(
        '''
        SELECT
          CAST(blueNo AS CHAR) AS blueNo,
          macAddress,
          DATE_FORMAT(createDate, '%Y-%m-%d %H:%i:%s') AS createDate
        FROM $tableName
        ORDER BY CAST(blueNo AS UNSIGNED) ASC
        LIMIT :pageSize OFFSET :offset
      ''',
        {'pageSize': pageSize, 'offset': offset},
      );

      return BleDevicePage(
        devices: result.rows
            .map((row) {
          final values = row.assoc();
          return BleDeviceRecord(
            blueNo: values['blueNo'] ?? '',
            macAddress: values['macAddress'] ?? '',
            createDate: values['createDate'] ?? '',
          );
        })
            .toList(growable: false),
        totalCount: totalCount,
      );
    } on MySQLException catch (error) {
      throw BleDatabaseException(error.message);
    }
  }

  @override
  Future<BleDeviceRecord> insert({
    required String blueNo,
    required String macAddress,
  }) async {
    try {
      // 1. 전달받은 blueNo가 비어있거나 올바르지 않은 경우, DB에서 가장 큰 숫자를 가져와 +1 채번
      String nextBlueNo = blueNo;

      if (nextBlueNo.trim().isEmpty) {
        final maxResult = await _pool.execute('''
          SELECT IFNULL(MAX(CAST(blueNo AS UNSIGNED)), 0) + 1 AS nextNo
          FROM $tableName
        ''');
        nextBlueNo = maxResult.rows.first.assoc()['nextNo'] ?? '1';
      }

      // 2. 새로운 blueNo와 macAddress로 INSERT
      await _pool.execute(
        '''
          INSERT INTO $tableName (blueNo, macAddress, createDate)
          VALUES (:blueNo, :macAddress, NOW())
        ''',
        {'blueNo': nextBlueNo, 'macAddress': macAddress},
      );

      // 3. 저장된 결과 조회
      final result = await _pool.execute(
        '''
          SELECT
            CAST(blueNo AS CHAR) AS blueNo,
            macAddress,
            DATE_FORMAT(createDate, '%Y-%m-%d %H:%i:%s') AS createDate
          FROM $tableName
          WHERE blueNo = :blueNo AND macAddress = :macAddress
          LIMIT 1
        ''',
        {'blueNo': nextBlueNo, 'macAddress': macAddress},
      );

      if (result.rows.isEmpty) {
        throw const BleDatabaseException('등록 결과를 다시 조회하지 못했습니다.');
      }
      final values = result.rows.first.assoc();
      return BleDeviceRecord(
        blueNo: values['blueNo'] ?? nextBlueNo,
        macAddress: values['macAddress'] ?? macAddress,
        createDate: values['createDate'] ?? '',
      );
    } on MySQLServerException catch (error) {
      if (error.message.toLowerCase().contains('duplicate entry')) {
        throw const DuplicateBleDeviceException();
      }
      throw BleDatabaseException(error.message);
    } on MySQLException catch (error) {
      throw BleDatabaseException(error.message);
    }
  }
}