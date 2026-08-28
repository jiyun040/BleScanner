import 'dart:io';

class ServerConfig {
  const ServerConfig({
    required this.dbHost,
    required this.dbPort,
    required this.dbUser,
    required this.dbPassword,
    required this.dbName,
    required this.dbSecure,
    required this.bindAddress,
    required this.port,
    required this.apiToken,
  });

  factory ServerConfig.fromEnvironment([Map<String, String>? values]) {
    final environment = values ?? Platform.environment;
    final dbUser = environment['PDAM_DB_USER']?.trim().isNotEmpty == true
        ? environment['PDAM_DB_USER']!.trim()
        : 'root';
    final dbPassword = environment['PDAM_DB_PASSWORD'] ?? '';

    if (dbPassword.isEmpty) {
      throw const FormatException('PDAM_DB_PASSWORD 환경변수가 필요합니다.');
    }

    return ServerConfig(
      dbHost: environment['PDAM_DB_HOST']?.trim().isNotEmpty == true
          ? environment['PDAM_DB_HOST']!.trim()
          : '139.150.75.233', // PDAM test
      // 운영 서버로 전환 시 139.150.75.234로 변경
      dbPort: _parsePort(environment['PDAM_DB_PORT'], 3306, 'PDAM_DB_PORT'),
      dbUser: dbUser,
      dbPassword: dbPassword,
      dbName: environment['PDAM_DB_NAME']?.trim().isNotEmpty == true
          ? environment['PDAM_DB_NAME']!.trim()
          : 'wooritech',
      dbSecure: _parseBool(environment['PDAM_DB_SECURE'], fallback: false),
      bindAddress: environment['PDAM_API_BIND']?.trim().isNotEmpty == true
          ? environment['PDAM_API_BIND']!.trim()
          : '0.0.0.0',
      port: _parsePort(environment['PDAM_API_PORT'], 8081, 'PDAM_API_PORT'),
      apiToken: environment['PDAM_API_TOKEN']?.trim() ?? '',
    );
  }

  final String dbHost;
  final int dbPort;
  final String dbUser;
  final String dbPassword;
  final String dbName;
  final bool dbSecure;
  final String bindAddress;
  final int port;
  final String apiToken;

  static int _parsePort(String? source, int fallback, String name) {
    if (source == null || source.trim().isEmpty) return fallback;
    final value = int.tryParse(source);
    if (value == null || value < 1 || value > 65535) {
      throw FormatException('$name 값이 올바른 포트가 아닙니다.');
    }
    return value;
  }

  static bool _parseBool(String? source, {required bool fallback}) {
    if (source == null || source.trim().isEmpty) return fallback;
    return switch (source.trim().toLowerCase()) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ => fallback,
    };
  }
}
