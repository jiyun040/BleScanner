import 'dart:async';
import 'dart:io';

import 'package:mysql_client/mysql_client.dart';
import 'package:pdam_ble_api/src/api/ble_device_api.dart';
import 'package:pdam_ble_api/src/config/server_config.dart';
import 'package:pdam_ble_api/src/database/mysql_ble_device_repository.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  late final ServerConfig config;
  try {
    config = ServerConfig.fromEnvironment();
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
    return;
  }

  final pool = MySQLConnectionPool(
    host: config.dbHost,
    port: config.dbPort,
    userName: config.dbUser,
    password: config.dbPassword,
    maxConnections: 10,
    databaseName: config.dbName,
    secure: config.dbSecure,
  );
  final repository = MySqlBleDeviceRepository(pool);
  final api = BleDeviceApi(repository: repository, apiToken: config.apiToken);
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(api.call);

  try {
    await repository.checkConnection();
    final server = await shelf_io.serve(
      handler,
      config.bindAddress,
      config.port,
    );
    stdout.writeln(
      'PDAM BLE API listening on http://${server.address.host}:${server.port}',
    );

    Future<void> shutdown(ProcessSignal signal) async {
      await server.close(force: true);
      await pool.close();
      exit(0);
    }

    ProcessSignal.sigint.watch().listen(shutdown);
    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen(shutdown);
    }
  } on Object catch (error) {
    stderr.writeln(error);
    await pool.close();
    exitCode = 1;
  }
}
