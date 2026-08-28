import 'package:pdam_ble_api/src/config/server_config.dart';
import 'package:test/test.dart';

void main() {
  test('기본 DB 연결은 PDAM test를 사용한다', () {
    final config = ServerConfig.fromEnvironment({
      'PDAM_DB_PASSWORD': 'test-password',
    });

    expect(config.dbHost, '139.150.75.233');
    expect(config.dbPort, 3306);
    expect(config.dbUser, 'root');
    expect(config.dbName, 'wooritech');
  });

  test('환경변수로 PDAM operate 전환이 가능하다', () {
    final config = ServerConfig.fromEnvironment({
      'PDAM_DB_HOST': '139.150.75.234',
      'PDAM_DB_PASSWORD': 'test-password',
    });

    expect(config.dbHost, '139.150.75.234');
  });
}
