import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class StoredStudySession {
  const StoredStudySession({
    required this.id,
    required this.type,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.notes,
  });

  final String id;
  final String type;
  final String status;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String? notes;

  factory StoredStudySession.fromJson(Map<String, dynamic> json) =>
      StoredStudySession(
        id: json['_id'] as String? ?? json['id'] as String,
        type: json['type'] as String? ?? 'focused',
        status: json['status'] as String? ?? 'planned',
        scheduledStart: DateTime.parse(json['scheduledStart'] as String),
        scheduledEnd: DateTime.parse(json['scheduledEnd'] as String),
        notes: json['notes'] as String?,
      );
}

class StudySessionRepositoryException implements Exception {
  const StudySessionRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class StudySessionRepository {
  Future<List<StoredStudySession>> fetchUpcomingSessions(String accessToken);
}

class ApiStudySessionRepository implements StudySessionRepository {
  ApiStudySessionRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<List<StoredStudySession>> fetchUpcomingSessions(
    String accessToken,
  ) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/sessions').replace(
        queryParameters: {
          'from': DateTime.now().toUtc().toIso8601String(),
          'status': 'planned',
        },
      );
      final response = await _client
          .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
          .timeout(const Duration(seconds: 15));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const StudySessionRepositoryException(
          'The server returned an invalid response.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StudySessionRepositoryException(
          decoded['message'] as String? ?? 'Could not load study sessions.',
        );
      }
      final sessions = decoded['sessions'];
      if (sessions is! List) {
        throw const StudySessionRepositoryException(
          'The server returned invalid study sessions.',
        );
      }
      return sessions
          .whereType<Map<String, dynamic>>()
          .map(StoredStudySession.fromJson)
          .toList();
    } on StudySessionRepositoryException {
      rethrow;
    } catch (_) {
      throw const StudySessionRepositoryException(
        'Could not load study sessions. Check your connection and try again.',
      );
    }
  }
}
