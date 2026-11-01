// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_oauth/otel_oauth.dart';

/// Traces OAuth 2.0 / OIDC endpoint calls with OpenTelemetry.
///
/// `otel_oauth` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each OAuth 2.0 / OIDC endpoint call in
/// [tracedOauth]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'oauth-example');

  // Wraps an OAuth 2.0 / OIDC endpoint call (token, refresh, userinfo, jwks, revoke) in a CLIENT span.
  final oauthId = await tracedOauth<String>(
    endpoint: 'example',
    issuer: 'example',
    grantType: 'standard',
    clientId: 'client_8f3a2c',
    scope: 'example',
    invoke: () async {
      // Make the OAuth 2.0 / OIDC endpoint call here, then report what it returned.
      return 'oauth_8f3a2c';
    },
  );
  OTelLog.info('tracedOauth returned $oauthId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutOauthInstrumentationAsync.
  await runWithoutOauthInstrumentationAsync(
    () => tracedOauth<String>(
      endpoint: 'example',
      issuer: 'example',
      grantType: 'standard',
      clientId: 'client_8f3a2c',
      scope: 'example',
      invoke: () async {
        return 'oauth_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
