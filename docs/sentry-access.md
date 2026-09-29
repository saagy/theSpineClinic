# Sentry access and release diagnostics

Organization: `sagy`. Project: `flutter` (`4512016812605520`).
[Issues](https://sagy.sentry.io/issues/?project=4512016812605520).

The user authorized persistent API access for investigating this app and uploading
its release artifacts. On this Windows account, the token is in Credential Manager
under `SpineClinic:Sentry:sagy`. Its Sentry name is `spine-clinic-codex`; scopes are
`event:read`, `org:read`, `project:read`, and `project:releases`. It cannot resolve
issues or administer the organization. Revoke it from Sentry's personal auth-token
settings if this machine/account should lose access.

The local helper is `C:/Users/Elite-Store/.codex/tools/sentry_api.py`. It reads the
credential in memory, fixes the API origin to Sentry, and never prints the token.
It persists across tasks on this PC; another machine needs its own connection.
Never put a Sentry auth token in `.env`, Flutter defines, browser assets or Git.
The public DSN is a different credential and remains in the application.

## Read issues

```powershell
python C:/Users/Elite-Store/.codex/tools/sentry_api.py 'projects/sagy/flutter/issues/?statsPeriod=14d&query=&limit=100'
python C:/Users/Elite-Store/.codex/tools/sentry_api.py 'organizations/sagy/issues/ISSUE_ID/events/latest/'
```

Use the organization-scoped event endpoint; the old bare `issues/ID/...` endpoint
returns 404 here. For automated analysis, import the helper's `request(path)`
function and emit only needed summaries. Keep raw events under ignored `build/`;
they can contain sensitive context. Issue lifetime counts and first/last dates
are not necessarily restricted to a UI date filter.

## Publish web releases with private source maps

Use a unique release for each build (a Git SHA is suitable) and the identical
release value during compilation and upload. The September 29 release is
`spine-clinic@2026.09.29.1`.

```powershell
flutter build web --release --no-pub --source-maps --dart-define-from-file=.env --dart-define=SENTRY_RELEASE=RELEASE --dart-define=SENTRY_ENVIRONMENT=production
python C:/Users/Elite-Store/.codex/tools/sentry_api.py prepare-web-source-map build/web/main.dart.js.map
python C:/Users/Elite-Store/.codex/tools/sentry_api.py cli sourcemaps upload build/web/main.dart.js build/web/main.dart.js.map --release RELEASE --url-prefix '~/' --validate --strict --wait-for 60
```

The wrapper invokes pinned Sentry CLI 3.8.0 with the token in its child environment.
The preparation step embeds repository `lib/` sources in the private map; it
does not change JavaScript. Without embedded sources, Firebase's SPA fallback
can make Sentry display HTML instead of Dart context. SDK/package source-context
warnings may remain; their mappings can still supply filenames and line numbers.
This uses release/URL matching for the existing Flutter SDK 8.14.2. Do not switch
to debug-ID-only symbolication without a compatible SDK. See Sentry's
[Flutter source-map guidance](https://docs.sentry.io/platforms/dart/guides/flutter/debug-symbols/dart-plugin/).
Upload the exact build before `firebase deploy --only hosting --project spine-clinic-app`.
`firebase.json` excludes maps from public hosting. Do not rebuild between upload
and deployment. CI compiles with maps and a CI environment but does not deploy or
upload them; CI has no production Sentry credential.

Debug runs default to `development`; release builds default to `production`.
Custom repository errors retain their originating stack and safe operation/status
tags, while raw database messages remain sanitized. Already-normalized failures
are not reported a second time. Invalid filename-only document links are handled
locally, rather than sent to storage. Genuine storage/network failures remain visible.

Start triage with production issues from the current release. Older events often
lack release IDs and source maps; a new upload cannot reliably recover their code
locations. Do not bulk-dismiss older errors or treat all development errors as
harmless. No recurring monitor was created as part of this connection.

A synthetic event in environment `diagnostics` verified the September 29 release's
filename, function, line and actual Dart source context end to end. It is labeled
`source-map-verification` and is not a user crash.
