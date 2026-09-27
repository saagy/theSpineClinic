import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';

/// Runs the actual PostgREST/Functions SDK against intercepted HTTP only.
class TestSupabaseService implements SupabaseService {
  TestSupabaseService(Future<http.Response> Function(http.Request) handler)
    : client = SupabaseClient(
        'https://example.test',
        'test-key',
        httpClient: MockClient((request) async {
          final response = await handler(request);
          return http.Response.bytes(
            response.bodyBytes,
            response.statusCode,
            headers: response.headers,
            request: request,
          );
        }),
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
  final SupabaseClient client;
  @override
  String get currentUserId => 'test-actor';
  @override
  SupabaseQueryBuilder from(String table) => client.from(table);
  @override
  Future<T> rpc<T>(String fn, {Map<String, dynamic>? params}) async =>
      await client.rpc<T>(fn, params: params);
  @override
  Future<T> guardQuery<T>(Future<T> Function() query) => query();
  @override
  Future<FunctionResponse> invokeFunction(
    String functionName, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    HttpMethod method = HttpMethod.post,
  }) => client.functions.invoke(
    functionName,
    headers: headers,
    body: body,
    method: method,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
