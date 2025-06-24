import 'package:dio/dio.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/models/feed_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';

BaseOptions getFeedBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/feeds', contentType: 'application/json', validateStatus: (int? status) => true);
}

class FeedService {
  final Dio _dio;

  FeedService() : _dio = Dio(getFeedBaseOptions())..interceptors.add(AccessTokenInterceptor());

  Future<List<FeedModel>> fetchTimeline({required TimelineType timelineType, int start = 0, int end = 10}) async {
    try {
      final path = switch (timelineType) {
        TimelineType.following => '/timeline/following',
        TimelineType.discover => '/timeline/discover',
      };

      final response = await _dio.get(path, queryParameters: {'start': start, 'end': end});

      myLogger.i('🚀 response.data in fetchTimeline: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data;
      myLogger.d("data['feeds'] is List: ${data['feeds'] is List}");
      if (data['feeds'] is List) {
        return (data['feeds'] as List).map<FeedModel>((json) => FeedModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    } catch (error) {
      myLogger.w('🌋 catch in fetchHomeTimeline: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchCreateFeed({required FormData formData}) async {
    try {
      Response response = await _dio.post('/create', data: formData);
      myLogger.i('🚀 response.data in fetchCreateFeed: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchCreateFeed: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchUpdateFeedMedia({required FormData formData, required String feedId}) async {
    try {
      Response response = await _dio.patch(
        '/update/media',
        queryParameters: {'feed_id': feedId},
        data: formData,
        onSendProgress: (int sent, int total) {
          myLogger.w('$sent $total');
        },
      );
      myLogger.i('🚀 response.data in fetchCreateFeedMedia: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode != 200) throw Exception('${response.data['details']}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchCreateFeedMedia: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> fetchUpdateFeed({required String? feedId, required FormData formData}) async {
    try {
      Response response = await _dio.patch('/update', data: formData, queryParameters: {'feed_id': feedId});
      myLogger.i('🚀 response.data in fetchUpdateFeed: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 200) return true;
      throw Exception(response.data['details']);
    } catch (error) {
      myLogger.w('🌋 catch in fetchUpdateFeed: ${error.toString()}');
      rethrow;
    }
  }

  Future<bool> fetchDeleteFeed({required String? feedId}) async {
    try {
      Response response = await _dio.delete('/delete', queryParameters: {'feed_id': feedId});
      myLogger.i('🚀 response.data in fetchDeleteFeed: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 204) return true;
      throw Exception(response.data['details']);
    } catch (error) {
      myLogger.e('Error in fetchDeleteFeed: $error');
      rethrow;
    }
  }

  /// ************************************************* Feed Search ************************************************* ///

  Future<List<FeedSearchResultModel>> fetchFeedSearch({required Map<String, String> queryParameters}) async {
    try {
      Response response = await _dio.get('/search', queryParameters: queryParameters);
      myLogger.i('🚀 response.data in fetchFeedSearch: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data;
      if (data is List) {
        return data.map((json) => FeedSearchResultModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (error) {
      myLogger.e('Error in fetchFeedSearch: $error');
      return [];
    }
  }

  /// ************************************************* Feed Engagement ************************************************* ///

  Future<EngagementModel> fetchSetEngagement({String? feedId, String? commentId, required EngagementType engagementType}) async {
    try {
      final queryParameters = {'engagement_type': engagementType.name, if (feedId != null) 'feed_id': feedId, if (commentId != null) 'comment_id': commentId};
      Response response = await _dio.post('/engagement/set', queryParameters: queryParameters);
      myLogger.i('🚀 response.data in fetchSetEngagementType: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 200) return EngagementModel.fromJson(response.data);
      throw Exception('Something happened while setting engagement');
    } catch (error) {
      myLogger.w('catch in fetchSetEngagementType: ${error.toString()}');
      throw Exception('catch in fetchSetEngagementType: ${error.toString()}');
    }
  }

  Future<EngagementModel> fetchRemoveEngagement({required String? feedId, String? commentId, required EngagementType engagementType}) async {
    try {
      final queryParameters = {'engagement_type': engagementType.name, if (feedId != null) 'feed_id': feedId, if (commentId != null) 'comment_id': commentId};
      Response response = await _dio.post('/engagement/remove', queryParameters: queryParameters);
      myLogger.i('🚀 response.data in fetchRemoveEngagementType: ${response.data}  statusCode: ${response.statusCode}');
      if (response.statusCode == 200) return EngagementModel.fromJson(response.data);
      throw Exception('Something happened while removing engagement');
    } catch (error) {
      myLogger.w('🌋 catch in fetchRemoveEngagementType: ${error.toString()}');
      throw Exception('catch in fetchRemoveEngagementType: ${error.toString()}');
    }
  }
}
