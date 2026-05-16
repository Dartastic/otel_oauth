// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_oauth/otel_oauth.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_oauth-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('token endpoint records CLIENT span', () async {
    await tracedOauth<String>(
      endpoint: 'token',
      issuer: 'https://idp.example.com',
      grantType: 'authorization_code',
      clientId: 'client-1',
      scope: 'openid profile email',
      invoke: () async => 'tok',
    );
    final a = attrsOf(spans.findSpanByName('oauth token')!);
    expect(a['oauth.endpoint'], 'token');
    expect(a['oauth.issuer'], 'https://idp.example.com');
    expect(a['oauth.grant_type'], 'authorization_code');
    expect(a['oauth.client.id'], 'client-1');
    expect(a['oauth.scope'], 'openid profile email');
  });

  test('suppression skips spans', () async {
    await runWithoutOauthInstrumentationAsync(() async {
      await tracedOauth<String>(
        endpoint: 'token',
        issuer: 'https://x',
        invoke: () async => 'tok',
      );
    });
    expect(spans.findSpansStartingWith('oauth '), isEmpty);
  });
}
