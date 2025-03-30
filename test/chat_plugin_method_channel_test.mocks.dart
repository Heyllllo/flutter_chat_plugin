// Mock code generation annotation for http Client
import 'dart:async' as _i3;
import 'dart:convert' as _i4;

import 'package:http/http.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

// This is a mock class using Mockito. You may need to run
// 'flutter pub run build_runner build' to regenerate this if you modify it

class MockClient extends _i1.Mock implements _i2.Client {
  MockClient() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<_i2.Response> get(Uri? url, {Map<String, String>? headers}) =>
      (super.noSuchMethod(
        Invocation.method(
          #get,
          [url],
          {#headers: headers},
        ),
        returnValue: _i3.Future<_i2.Response>.value(_FakeResponse()),
      ) as _i3.Future<_i2.Response>);

  @override
  _i3.Future<_i2.Response> post(Uri? url,
          {Map<String, String>? headers,
          Object? body,
          _i4.Encoding? encoding}) =>
      (super.noSuchMethod(
        Invocation.method(
          #post,
          [url],
          {
            #headers: headers,
            #body: body,
            #encoding: encoding,
          },
        ),
        returnValue: _i3.Future<_i2.Response>.value(_FakeResponse()),
      ) as _i3.Future<_i2.Response>);
}

class _FakeResponse extends _i1.Fake implements _i2.Response {
  @override
  int get statusCode => 200;

  @override
  String get body => '{"status": 200}';
}
