import 'package:dio/dio.dart';
import 'package:kinestex_sdk_flutter/src/api/api_models.dart';
import 'package:kinestex_sdk_flutter/src/core/kinestex_logger.dart';

/// APIService handles all HTTP requests to the KinesteX API
class APIService {
  static const String _baseURL = 'https://admin.kinestex.com/api/v1/';
  final String apiKey;
  final String companyName;
  final Dio _dio;
  final _logger = KinesteXLogger.instance;

  APIService({
    required this.apiKey,
    required this.companyName,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: _baseURL,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'x-api-key': apiKey,
              'x-company-name': companyName,
            },
          ),
        ) {
    // Add logging interceptor in debug mode
    _dio.interceptors.addAll(
      [
        LogInterceptor(request: true, responseBody: true),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            _logger.info('API Request: ${options.method} ${options.uri}');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            _logger.success(
                'API Response: ${response.statusCode} ${response.requestOptions.uri}');
            return handler.next(response);
          },
          onError: (error, handler) {
            _logger.error(
                'API Error: ${error.response?.statusCode ?? 'N/A'} ${error.requestOptions.uri}');
            return handler.next(error);
          },
        ),
      ],
    );
  }

  /// Fetches content data from the API based on the provided parameters
  Future<APIContentResult> fetchContent({
    required ContentType contentType,
    String? id,
    String? title,
    String lang = 'en',
    String? category,
    List<BodyPart>? bodyParts,
    Map<String, dynamic> queryParameters = const {},
    String? lastDocId,
    int? limit,
  }) async {
    try {
      // Determine endpoint
      final endpoint = _getEndpoint(contentType);

      // Build path
      final pathComponent = id != null
          ? '/$id'
          : title != null
              ? '/$title'
              : '';

      final path = '$endpoint$pathComponent';

      // Build query parameters
      // final queryParameters = <String, dynamic>{
      //   'lang': lang,
      // };
      queryParameters['lang'] = lang;

      if (category != null) {
        queryParameters['category'] = category;
      }
      if (lastDocId != null) {
        queryParameters['lastDocId'] = lastDocId;
      }
      if (limit != null) {
        queryParameters['limit'] = limit;
      }
      if (bodyParts != null && bodyParts.isNotEmpty) {
        queryParameters['body_parts'] =
            bodyParts.map((bp) => bp.value).join(',');
      }

      // Make request
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );

      // Check status code
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        return _handleError(response);
      }

      // Parse response
      final data = response.data as Map<String, dynamic>;
      final isList =
          category != null || (bodyParts != null && bodyParts.isNotEmpty);

      return _parseResponse(
        data: data,
        contentType: contentType,
        isList: isList,
      );
    } on DioException catch (e) {
      _logger.error('Network error', e);
      return ErrorResult('Network error: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      _logger.error('Unexpected error', e);
      return ErrorResult('Unexpected error: $e');
    }
  }

  /// Get endpoint string based on content type
  String _getEndpoint(ContentType contentType) {
    switch (contentType) {
      case ContentType.workout:
        return 'workouts';
      case ContentType.plan:
        return 'plans';
      case ContentType.exercise:
        return 'exercises';
    }
  }

  /// Handle error responses
  APIContentResult _handleError(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? 'Unknown error';
      return ErrorResult('Error: $message');
    }
    return ErrorResult('HTTP ${response.statusCode}');
  }

  /// Parse successful response based on content type
  APIContentResult _parseResponse({
    required Map<String, dynamic> data,
    required ContentType contentType,
    required bool isList,
  }) {
    try {
      switch (contentType) {
        case ContentType.workout:
          if (isList) {
            // Process workouts list
            final workoutsList = data['workouts'] as List<dynamic>? ?? [];
            final processedWorkouts = workoutsList.map((workout) {
              final workoutMap = workout as Map<String, dynamic>;
              final sequence = workoutMap['sequence'] as List<dynamic>? ?? [];
              final processedSequence = _processSequence(sequence);
              workoutMap['sequence'] = processedSequence;
              return WorkoutModel.fromJson(workoutMap);
            }).toList();

            final response = WorkoutsResponse(
              workouts: processedWorkouts,
              lastDocId: data['lastDocId'] as String? ?? '',
              rawJSON: data,
            );
            return WorkoutsResult(response);
          } else {
            // Process single workout
            final sequence = data['sequence'] as List<dynamic>? ?? [];
            final processedSequence = _processSequence(sequence);
            data['sequence'] = processedSequence;
            final workout = WorkoutModel.fromJson(data);
            return WorkoutResult(workout);
          }

        case ContentType.plan:
          if (isList) {
            final response = PlansResponse.fromJson(data);
            return PlansResult(response);
          } else {
            final plan = PlanModel.fromJson(data);
            return PlanResult(plan);
          }

        case ContentType.exercise:
          if (isList) {
            final response = ExercisesResponse.fromJson(data);
            return ExercisesResult(response);
          } else {
            final exercise = ExerciseModel.fromJson(data);
            return ExerciseResult(exercise);
          }
      }
    } catch (e) {
      _logger.error('Failed to parse ${contentType.value}', e);
      return RawDataResult(
        data,
        'Failed to parse ${contentType.value}: $e',
      );
    }
  }

  /// Process workout sequence to extract rest durations
  ///
  /// This matches the Swift implementation:
  /// - Rest items are removed from sequence
  /// - Rest duration from "Rest" item is assigned to the next exercise
  /// - Exercises without preceding rest get 0 rest_duration
  List<Map<String, dynamic>> _processSequence(List<dynamic> rawSequence) {
    final processedExercises = <Map<String, dynamic>>[];
    int currentRestDurationForNextExercise = 0;

    for (final item in rawSequence) {
      final itemMap = item as Map<String, dynamic>;

      // Check if this is a "Rest" item
      if (itemMap['id'] == 'Rest') {
        // Extract countdown for the next exercise
        currentRestDurationForNextExercise = itemMap['countdown'] as int? ?? 10;
      } else {
        // This is an exercise item
        final exerciseItem = Map<String, dynamic>.from(itemMap);
        exerciseItem['rest_duration'] = currentRestDurationForNextExercise;
        processedExercises.add(exerciseItem);

        // Reset rest duration after assigning to exercise
        currentRestDurationForNextExercise = 0;
      }
    }

    return processedExercises;
  }
}
