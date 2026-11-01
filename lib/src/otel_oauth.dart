// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_oauth_suppression.dart';

const _tracerName = 'dartastic_otel_libs_oauth';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps an OAuth 2.0 / OIDC endpoint call (token, refresh, userinfo,
/// jwks, revoke) in a CLIENT span. Never records the token itself.
Future<T> tracedOauth<T>({
  required String endpoint,
  required String issuer,
  required Future<T> Function() invoke,
  String? grantType,
  String? clientId,
  String? scope,
}) async {
  if (oauthInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'oauth.endpoint': endpoint,
    'oauth.issuer': issuer,
  };
  if (grantType != null) m['oauth.grant_type'] = grantType;
  if (clientId != null) m['oauth.client.id'] = clientId;
  if (scope != null) m['oauth.scope'] = scope;

  final span = _tracer().startSpan(
    'oauth $endpoint',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
