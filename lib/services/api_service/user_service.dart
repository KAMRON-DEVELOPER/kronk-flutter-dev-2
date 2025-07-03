import 'package:dio/dio.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/interceptors.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:tuple/tuple.dart';

BaseOptions getUsersBaseOptions() {
  return BaseOptions(baseUrl: '${constants.apiEndpoint}/users', contentType: 'application/json', validateStatus: (int? status) => true);
}

class UserService {
  final Dio _dio;
  final Storage _storage;

  UserService() : _dio = Dio(getUsersBaseOptions()), _storage = Storage();

  Future<Response> fetchRegister({required Map<String, String> data}) async {
    try {
      Response response = await _dio.post('/auth/register', data: data);
      myLogger.i('🚀 response.data in fetchRegister: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchRegister: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchVerify({required String code}) async {
    try {
      Tuple2<String?, bool> verifyTokenStatus = await _storage.getVerifyTokenAsync();
      final bool isExpiredVerifyToken = verifyTokenStatus.item2;
      final String? verifyToken = verifyTokenStatus.item1;

      if (verifyToken == null) {
        throw Exception('Verify token not found.');
      } else if (isExpiredVerifyToken) {
        throw Exception('Your verify token is expired.');
      }

      _dio.interceptors.add(VerifyTokenInterceptor(verifyToken: verifyToken));
      Response response = await _dio.post('/auth/verify', data: {'code': code});
      myLogger.i('🚀 response.data in fetchVerify: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchVerify: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchLogin({required Map<String, dynamic> data}) async {
    try {
      Response response = await _dio.post('/auth/login', data: data);
      myLogger.i('🚀 response.data in fetchLogin: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchLogin: ${error.toString()}');
      rethrow;
    }
  }

  Future<void> fetchLogout() async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/auth/logout');
      myLogger.d('response.statusCode: ${response.statusCode}');
      myLogger.d('response.data: ${response.data}, data.runtimeType: ${response.data.runtimeType}');
    } catch (e) {
      myLogger.f('Something happened in fetchLogout...');
    }
  }

  Future<Response> fetchRequestForgotPassword({required String email}) async {
    try {
      Response response = await _dio.post('/auth/request-forgot-password', data: {'email': email});
      myLogger.i('🚀 response.data in fetchRequestForgotPassword: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchRequestForgotPassword: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchForgotPassword({required Map<String, String> data}) async {
    try {
      Tuple2<String?, bool> token = await _storage.forgotPasswordTokenAsync();
      final bool isExpiredResetPasswordToken = token.item2;
      final String? forgotPasswordToken = token.item1;

      if (forgotPasswordToken == null) {
        throw Exception('Reset password token is not found.');
      } else if (isExpiredResetPasswordToken) {
        throw Exception('Your reset password token is expired.');
      }

      _dio.interceptors.add(ForgotPasswordTokenInterceptor(forgotPasswordToken: forgotPasswordToken));
      Response response = await _dio.post('/auth/forgot-password', data: data);
      myLogger.i('🚀 response.data in fetchResetPassword: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchResetPassword: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchGoogleAuth({required String? firebaseUserIdToken}) async {
    try {
      _dio.interceptors.add(FirebaseIdTokenInterceptor(firebaseIdToken: firebaseUserIdToken));
      Response response = await _dio.post('/auth/social/google');
      myLogger.i('🚀 response.data in fetchSocialAuth: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🥶 Error in fetchSocialAuth: ${error.toString()}');
      rethrow;
    }
  }

  Future<UserModel> fetchGetProfile() async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      final response = await _dio.get('/profile');
      myLogger.d('1. response.data in fetchProfile: ${response.data} ### statusCode: ${response.statusCode}');
      return UserModel.fromJson(response.data);
    } catch (error) {
      myLogger.w('catch in fetchUserProfile: ${error.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchUpdateProfile({required UserModel? updateData}) async {
    try {
      Response response = await _dio.put('/profile/update', data: updateData);
      myLogger.i('🚀 response.data in fetchUpdateProfile: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (e) {
      myLogger.w('error in fetchUserProfile: ${e.toString()}');
      rethrow;
    }
  }

  Future<Response> fetchUpdateProfileMedia({required FormData formData, String? removeTarget}) async {
    try {
      Response response = await _dio.put('/profile/update/media', data: formData, queryParameters: {'remove_target': removeTarget});
      myLogger.i('🚀 response.data in fetchUpdateProfile: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (e) {
      myLogger.w('error in fetchUserProfile: ${e.toString()}');
      rethrow;
    }
  }

  Future<int?> fetchDeleteProfile() async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.delete('/profile/delete');
      myLogger.i('🚀 response.data in fetchDeleteProfile: ${response.data}  statusCode: ${response.statusCode}');

      return response.statusCode;
    } catch (e) {
      myLogger.w('error in fetchUserProfile: ${e.toString()}');
      rethrow;
    }
  }

  Future<Response?> fetchAccessTokens({required String refreshToken}) async {
    try {
      Response response = await _dio.post('/auth/access', options: Options(headers: {'Authorization': 'Bearer $refreshToken'}));
      myLogger.i('🚀 response.data in fetchAccessTokens: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchAccessTokens: ${error.toString()}');
      return null;
    }
  }

  Future<Response?> fetchRefreshTokens({required String refreshToken}) async {
    try {
      Response response = await _dio.post('/auth/refresh', options: Options(headers: {'Authorization': 'Bearer $refreshToken'}));
      myLogger.i('🚀 response.data in fetchRefreshTokens: ${response.data}  statusCode: ${response.statusCode}');
      return response;
    } catch (error) {
      myLogger.w('🌋 catch in fetchRefreshTokens: ${error.toString()}');
      return null;
    }
  }

  Future<Tuple2<List<UserModel>, int>> fetchUserSearch({required String query, int start = 0, int end = 9}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.get('/search', queryParameters: {'query': query, 'offset': start, 'limit': (end + 1) - start});
      myLogger.i('🚀 response.data in fetchUserSearch: ${response.data}  statusCode: ${response.statusCode}');
      final data = response.data;
      if (data['users'] is List) {
        // if ((data['users'] as List).isEmpty) return const Tuple2([], 0);
        return Tuple2((data['users'] as List).map<UserModel>((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList(), data['end'] ?? 0);
      } else {
        return const Tuple2([], 0);
      }
    } catch (error) {
      myLogger.e('Error in fetchUserSearch: $error');
      rethrow;
    }
  }

  Future<void> fetchFollow({required String followingId}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/follow', queryParameters: {'following_id': followingId});
      myLogger.i('🚀 response.data in fetchFollow: ${response.data}  statusCode: ${response.statusCode}');
    } catch (error) {
      myLogger.e('Error in fetchFollow: $error');
    }
  }

  Future<void> fetchUnfollow({required String followingId}) async {
    try {
      _dio.interceptors.add(AccessTokenInterceptor());
      Response response = await _dio.post('/unfollow', queryParameters: {'following_id': followingId});
      myLogger.i('🚀 response.data in fetchUnfollow: ${response.data}  statusCode: ${response.statusCode}');
    } catch (error) {
      myLogger.e('Error in fetchUnfollow: $error');
    }
  }
}
