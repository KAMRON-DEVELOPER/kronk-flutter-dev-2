class Constants {
  final bool devMode = true;
  final String _apiDevEndpoint = 'http://192.168.31.228:8000/api/v1';
  final String _apiProdEndpoint = 'https://api.kronk.uz/api/v1';

  final String _bucketDevEndpoint = 'http://192.168.31.228:9000/dev-bucket';
  final String _bucketProdEndpoint = 'http://94.136.191.25:9000/dev-bucket';

  final String _websocketDevEndpoint = 'ws://192.168.31.228:8000/api/v1';
  final String _websocketProdEndpoint = 'wss://api.kronk.uz/api/v1';

  final String clientId = '196822526321-s71akjq1nv6d14rlo7f2gnpf30oidg2v.apps.googleusercontent.com';
  final String serverClientId = '196822526321-b98dqp6vpvup7dhiltjpjgbs4g0ohj5p.apps.googleusercontent.com';

  String get apiEndpoint => devMode ? _apiDevEndpoint : _apiProdEndpoint;

  String get bucketEndpoint => devMode ? _bucketDevEndpoint : _bucketProdEndpoint;

  String get websocketEndpoint => devMode ? _websocketDevEndpoint : _websocketProdEndpoint;
}

final Constants constants = Constants();
