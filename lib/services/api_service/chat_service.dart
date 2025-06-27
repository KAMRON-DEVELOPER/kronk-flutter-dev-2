import 'package:dio/dio.dart';
import 'package:kronk/models/chat_tile_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';

BaseOptions getChatBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/chats', contentType: 'application/json', validateStatus: (int? status) => true);
}

class ChatService {
  final Dio _dio;
  final Storage _storage;

  ChatService() : _dio = Dio(getChatBaseOptions())..interceptors.add(AccessTokenInterceptor()), _storage = Storage();

  Future<List<ChatTileModel>> fetchChatTiles({int start = 0, int end = 10}) async {
    try {
      Response response = await _dio.get('/tiles');
      myLogger.i('🚀 response.data in fetchChatTiles: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data['chat_tiles'];
      if (data is List) {
        return data.map((json) => ChatTileModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (error) {
      myLogger.w('catch in fetchChatTiles: ${error.toString()}');
      rethrow;
    }
  }
}
