import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class TaskDraft {
  const TaskDraft({
    required this.course,
    required this.title,
    required this.priority,
    this.dueDate,
  });

  final String course;
  final String title;
  final String priority;
  final DateTime? dueDate;

  Map<String, dynamic> toJson() => {
    'course': course,
    'title': title,
    'priority': priority.toLowerCase(),
    if (dueDate != null) 'dueDate': dueDate!.toUtc().toIso8601String(),
  };
}

class StoredTask {
  const StoredTask({
    required this.id,
    required this.course,
    required this.title,
    required this.priority,
    required this.status,
    this.dueDate,
  });

  final String id;
  final String course;
  final String title;
  final String priority;
  final String status;
  final DateTime? dueDate;

  factory StoredTask.fromJson(Map<String, dynamic> json) {
    final dueDateValue = json['dueDate'] as String?;
    return StoredTask(
      id: json['_id'] as String? ?? json['id'] as String,
      course: json['course'] as String? ?? 'General',
      title: json['title'] as String,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'todo',
      dueDate: dueDateValue == null ? null : DateTime.tryParse(dueDateValue),
    );
  }
}

class TaskRepositoryException implements Exception {
  const TaskRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class TaskRepository {
  Future<List<StoredTask>> fetchTasks(String accessToken);
  Future<StoredTask> createTask(String accessToken, TaskDraft draft);
  Future<StoredTask> updateStatus(
    String accessToken,
    String taskId,
    String status,
  );
}

class ApiTaskRepository implements TaskRepository {
  ApiTaskRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri([String path = '']) => Uri.parse('$apiBaseUrl/tasks/$path');

  Map<String, String> _headers(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  @override
  Future<List<StoredTask>> fetchTasks(String accessToken) async {
    try {
      final response = await _client
          .get(_uri(), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));
      final body = _readBody(response);
      final tasks = body['tasks'];
      if (tasks is! List) {
        throw const TaskRepositoryException(
          'The server returned invalid tasks.',
        );
      }
      return tasks
          .whereType<Map<String, dynamic>>()
          .map(StoredTask.fromJson)
          .toList();
    } on TaskRepositoryException {
      rethrow;
    } catch (_) {
      throw const TaskRepositoryException(
        'Could not load tasks. Check your connection and try again.',
      );
    }
  }

  @override
  Future<StoredTask> createTask(String accessToken, TaskDraft draft) async {
    try {
      final response = await _client
          .post(
            _uri(),
            headers: _headers(accessToken),
            body: jsonEncode(draft.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      return _taskFromResponse(response);
    } on TaskRepositoryException {
      rethrow;
    } catch (_) {
      throw const TaskRepositoryException(
        'Could not save the task. Check your connection and try again.',
      );
    }
  }

  @override
  Future<StoredTask> updateStatus(
    String accessToken,
    String taskId,
    String status,
  ) async {
    try {
      final response = await _client
          .patch(
            _uri(taskId),
            headers: _headers(accessToken),
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));
      return _taskFromResponse(response);
    } on TaskRepositoryException {
      rethrow;
    } catch (_) {
      throw const TaskRepositoryException(
        'Could not update the task. Check your connection and try again.',
      );
    }
  }

  StoredTask _taskFromResponse(http.Response response) {
    final body = _readBody(response);
    final task = body['task'];
    if (task is! Map<String, dynamic>) {
      throw const TaskRepositoryException(
        'The server returned an invalid task.',
      );
    }
    return StoredTask.fromJson(task);
  }

  Map<String, dynamic> _readBody(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const TaskRepositoryException(
        'The server returned an invalid response.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TaskRepositoryException(
        decoded['message'] as String? ?? 'Task request failed.',
      );
    }
    return decoded;
  }
}
