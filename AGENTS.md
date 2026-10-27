# TrackGuard DHR — AI-Assisted Production Development Guide

## 1. Project Context

TrackGuard DHR is an offline-first Flutter application for permanent-way staff inspecting the Darjeeling Himalayan Railway alignment.

Original hackathon repository:

- `ShahbazCoder1/trackguard-dhr`
- Technology: Next.js, React, TypeScript, IndexedDB, Serwist, LiteRT-LM, Gemma 4 E2B
- Purpose: prototype the field inspection workflow

Production repository:

- `ShahbazCoder1/TrackGuard-DHR-App`
- Technology: Flutter/Dart
- Purpose: production mobile application

The application solves this problem:

> An offline track-inspection tool for permanent-way staff walking the alignment: photo + GPS + severity for a slip, rockfall, blocked drain or damaged retaining wall, with an on-device model suggesting a first classification and a plain-language note. Reports queue and sync at the next station that has connectivity, and roll up into a simple section-wise dashboard.

## 2. Required Production Features

The application must support:

- Offline-first report creation.
- Photo capture and local media storage.
- GPS capture with accuracy.
- DHR section and kilometre-marker estimation.
- Manual location correction when GPS is unavailable.
- Human review of all AI suggestions.
- Offline Gemma 4 E2B inference through the Cactus library.
- Online Gemini inference through a secure backend.
- Local report queue.
- Reliable synchronization with Supabase.
- Google authentication.
- Role-based access for gangmen and admins/authorized personnel.
- Section-wise supervisor dashboard.
- Report status actions and audit history.
- English, Hindi, Bengali, and Nepali localization.

## 3. Core Workflow

```text
Google Sign In
    ↓
Resolve user profile and role
    ↓
Gangman Home
    ↓
Capture Photo
    ↓
Capture GPS / Select Manual Location
    ↓
Offline Gemma or Online Gemini Analysis
    ↓
Gangman Reviews and Confirms Result
    ↓
Save Report Locally
    ↓
Pending Sync Queue
    ↓
Sync When Connectivity Returns
    ↓
Supabase Database and Storage
    ↓
Authorized Admin Dashboard
    ↓
Acknowledge / Require Inspection / Resolve
```

AI is advisory only. The gangman confirms the final hazard type, severity, and note.

The application must never independently decide to stop train traffic, close a track, or declare a structure unsafe.

## 4. Engineering Principles

1. Offline reporting must work without network connectivity.
2. AI suggestions must remain separate from human-confirmed values.
3. Reports must be saved locally before synchronization.
4. Device-generated UUIDs must be used for reports.
5. Synchronization must be idempotent and safe to retry.
6. Failed reports must never be silently deleted.
7. Supabase Row Level Security must enforce authorization.
8. Widgets must not directly call Supabase.
9. Gemini API keys and Supabase service-role keys must never be placed in Flutter client code.
10. Fallback coordinates must never be presented as real GPS coordinates.
11. All user-facing strings must be localized in four languages.
12. Every production feature needs loading, empty, error, and offline states.
13. Large images must be stored as files, not passed through route arguments.
14. Every status change must be auditable.
15. Every AI result must record its provider and model.

## 5. Recommended Flutter Structure

```text
lib/
  app/
    app.dart
    router.dart
    theme.dart

  core/
    constants/
    connectivity/
    errors/
    localization/
    permissions/
    storage/
    utils/

  features/
    auth/
      data/
      domain/
      presentation/

    home/
      presentation/

    report_capture/
      data/
      domain/
      presentation/

    report_review/
      presentation/

    report_queue/
      data/
      presentation/

    report_detail/
      presentation/

    admin_dashboard/
      data/
      presentation/

    ai/
      data/
      domain/

    sync/
      data/
      domain/
      presentation/

  shared/
    models/
    widgets/
```

Use one state-management solution consistently. Riverpod is recommended, but Bloc is acceptable if already selected by the team.

Recommended packages, subject to compatibility verification:

- `supabase_flutter`
- `go_router`
- `drift`
- `sqlite3_flutter_libs`
- `path_provider`
- `connectivity_plus`
- `geolocator`
- `camera`
- `image_picker`
- `flutter_secure_storage`
- `intl`
- `flutter_localizations`
- Cactus Flutter/native integration for Gemma inference

## 6. Domain Models

### Profile

```text
Profile
  id: UUID
  fullName: String?
  email: String
  role: gangman | admin
  assignedSection: String?
  preferredLanguage: en | hi | bn | ne
  isActive: bool
  createdAt: DateTime
  updatedAt: DateTime
```

Google authentication identifies the person. The profile determines role and authorization.

Do not automatically grant admin access solely because of an email domain unless an explicit organizational policy exists.

### HazardReport

```text
HazardReport
  id: UUID
  createdBy: UUID
  createdAt: DateTime
  updatedAt: DateTime

  latitude: double?
  longitude: double?
  gpsAccuracyMeters: double?
  locationSource: gps | manual | fallback
  locationCapturedAt: DateTime?
  distanceToAlignmentKm: double?
  kmMarker: double?
  sectionId: String
  nearestStationName: String?

  confirmedHazardType: HazardType
  confirmedSeverity: Severity
  userNote: String

  aiSuggestedHazardType: HazardType?
  aiSuggestedSeverity: Severity?
  aiNote: String?
  aiProvider: offlineGemma | onlineGemini | heuristic | manual
  aiModel: String?
  aiLanguage: AppLanguage?
  aiConfidence: double?

  inspectionStatus: InspectionStatus
  syncStatus: SyncStatus
  syncVersion: int
  syncTimestamp: DateTime?
  retryCount: int
  lastSyncError: String?

  originalPhotoPath: String?
  thumbnailPhotoPath: String?
  deviceInfo: String?
```

### Enums

```text
HazardType:
  slip
  rockfall
  blockedDrain
  damagedWall
  trackDefect
  vegetation
  other

Severity:
  low
  medium
  high
  critical

InspectionStatus:
  open
  acknowledged
  inspectionRequired
  resolved

SyncStatus:
  draft
  pending
  syncing
  synced
  failed
  conflict

AppLanguage:
  en
  hi
  bn
  ne

LocationSource:
  gps
  manual
  fallback

AiProvider:
  offlineGemma
  onlineGemini
  heuristic
  manual
```

## 7. Supabase Schema

### `profiles`

```sql
id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
full_name TEXT,
email TEXT NOT NULL,
role TEXT NOT NULL CHECK (role IN ('gangman', 'admin')),
assigned_section TEXT,
preferred_language TEXT NOT NULL DEFAULT 'en',
is_active BOOLEAN NOT NULL DEFAULT TRUE,
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

### `reports`

```sql
id UUID PRIMARY KEY,
created_by UUID NOT NULL REFERENCES profiles(id),
created_at TIMESTAMPTZ NOT NULL,
updated_at TIMESTAMPTZ NOT NULL,

latitude DOUBLE PRECISION,
longitude DOUBLE PRECISION,
gps_accuracy_meters DOUBLE PRECISION,
location_source TEXT NOT NULL,
location_captured_at TIMESTAMPTZ,
distance_to_alignment_km DOUBLE PRECISION,
km_marker NUMERIC,
section_id TEXT NOT NULL,
nearest_station_name TEXT,

confirmed_hazard_type TEXT NOT NULL,
confirmed_severity TEXT NOT NULL,
user_note TEXT NOT NULL DEFAULT '',

ai_suggested_hazard_type TEXT,
ai_suggested_severity TEXT,
ai_note TEXT,
ai_provider TEXT,
ai_model TEXT,
ai_language TEXT,
ai_confidence DOUBLE PRECISION,

inspection_status TEXT NOT NULL DEFAULT 'open',
sync_version INTEGER NOT NULL DEFAULT 1
```

### `report_media`

```sql
id UUID PRIMARY KEY,
report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
original_path TEXT,
thumbnail_path TEXT,
mime_type TEXT,
file_size INTEGER,
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

### `report_status_history`

```sql
id UUID PRIMARY KEY,
report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
changed_by UUID NOT NULL REFERENCES profiles(id),
from_status TEXT,
to_status TEXT NOT NULL,
comment TEXT,
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

### Sections

Seed or configure:

```text
kurseong-ghum:
  name: Kurseong → Ghum
  startKm: 31.0
  endKm: 74.0

ghum-darjeeling:
  name: Ghum → Darjeeling
  startKm: 74.0
  endKm: 88.0
```

## 8. Authorization Requirements

### Gangman

Gangmen may:

- Sign in with Google.
- Read their own profile.
- Create reports.
- Read their own reports.
- View status updates for their reports.
- Update drafts before submission.
- Use offline mode.

Gangmen must not change supervisor status unless explicitly authorized.

### Admin/Authorized User

Admins may:

- View reports within their assigned scope.
- View report media and metadata.
- Acknowledge reports.
- Request inspection.
- Resolve reports.
- Add supervisor comments.
- View status history.
- Manage users if granted user-management permission.

Authorization must be enforced by Supabase RLS/backend policies, not only by the UI.

## 9. Role-Based Navigation

Recommended routes:

```text
/auth/sign-in
/auth/pending
/auth/profile

/gangman/home
/gangman/report/capture
/gangman/report/review
/gangman/reports
/gangman/reports/:id

/admin/dashboard
/admin/reports/:id
/admin/users

/settings
```

Routing rules:

1. Unauthenticated users go to sign-in.
2. Authenticated users without an active profile go to pending access.
3. Gangmen go to the gangman home screen.
4. Admins go to the admin dashboard.
5. Inactive users are blocked.
6. Protected routes verify the current user profile and role.
7. Route guards do not replace Supabase RLS.

## 10. Work Distribution

The project has two developers:

- Shahbaz: field reporting and AI.
- Debashish: backend, persistence, synchronization, and administration.

Each person owns the full vertical slice of their screens, including UI, state management, repositories, loading/error states, localization, and tests.

### Shared Foundation

Both developers must agree on:

- Flutter architecture.
- State-management solution.
- Domain models.
- Serialization.
- Router and route guards.
- Theme and shared widgets.
- Supabase environments.
- Local database strategy.
- Error conventions.
- Four-language localization.
- Git branch conventions.
- Development, staging, and production configuration.

### Shahbaz — Field Reporting and AI

#### Authentication UI and onboarding

Own:

- Google sign-in screen.
- Auth loading screen.
- Role-resolution screen.
- Pending-access screen.
- Gangman onboarding/profile.
- Preferred-language selection.
- Logout.
- Role-aware redirect integration.

#### Gangman home

Own:

- TrackGuard branding.
- Connectivity status.
- Pending queue count.
- New report button.
- My reports shortcut.
- AI provider/model readiness.
- Assigned section.
- Profile and logout entry.

#### Capture report screen

Port the behavior of the original camera and GPS flow.

Implement:

- Rear camera preview.
- Front/rear camera switching.
- Photo capture.
- Retake and confirm.
- Gallery fallback.
- Image compression.
- Thumbnail creation.
- Camera permission education.
- GPS permission handling.
- GPS accuracy display.
- DHR waypoint picker.
- Station picker.
- Automatic section detection.
- Km-marker estimation.
- Manual km-marker correction.
- Explicit location source.
- Durable draft handling.

#### Review and confirmation screen

Implement:

- Photo preview.
- AI analysis progress.
- Offline Gemma result.
- Online Gemini result.
- Manual fallback.
- Editable hazard type.
- Editable severity.
- Editable note.
- Editable km marker.
- AI disclaimer.
- Provider/model metadata.
- Translation action.
- Confirm and save locally.

The saved report must preserve:

```text
AI suggestion
Human-confirmed hazard
Human-confirmed severity
Human note
AI provider
AI model
AI language
```

#### AI provider layer

Create an abstraction such as:

```dart
abstract class AiAnalysisProvider {
  Future<AiAnalysisResult> analyze({
    required File image,
    required GeoLocation location,
    required AppLanguage language,
  });
}
```

Implement:

- Cactus/Gemma offline provider.
- Gemini provider client through a secured backend function.
- Heuristic/manual fallback.
- Strict JSON parsing.
- Hazard/severity sanitization.
- Language-aware notes.
- Provider and model audit metadata.
- Model readiness and initialization state.

Provider selection:

```text
If online mode is selected and connectivity exists:
    call secured Gemini backend

Else if offline Gemma is installed and ready:
    use Cactus/Gemma

Else:
    use manual classification and deterministic fallback
```

#### Gangman report detail

Display:

- Photo.
- Confirmed hazard.
- Severity.
- Gangman note.
- AI suggestion audit card.
- GPS metadata.
- Section.
- Km marker.
- Sync state.
- Current inspection status.

Do not show admin-only status controls to gangmen unless specifically authorized.

### Debashish — Backend, Persistence, Sync, and Administration

#### Supabase foundation

Own:

- Supabase initialization.
- Google authentication configuration.
- Database migrations.
- Storage buckets.
- RLS policies.
- Profile repository.
- Report repository.
- Status-history repository.
- Section seed data.
- Authorized-user setup.
- Environment configuration.

#### Local persistence and media

Use Drift/SQLite or an equivalent durable database.

Own:

- Report CRUD.
- Draft persistence.
- Local media file paths.
- Thumbnail paths.
- Sync-state indexes.
- Retry metadata.
- Schema migrations.
- Cache invalidation.
- Safe media cleanup policy.

Do not store large images in route state.

#### Synchronization engine

Own:

- Manual sync.
- Automatic sync after connectivity returns.
- Pending and failed queues.
- Progress callbacks.
- Exponential backoff.
- Idempotent report upsert.
- Original and thumbnail uploads.
- Remote status pull.
- Conflict handling.
- Last-error recording.
- Duplicate prevention.

Recommended storage paths:

```text
reports/{user_id}/{report_id}/original.jpg
reports/{user_id}/{report_id}/thumbnail.jpg
```

Recommended sync flow:

```text
Local pending report
  → Mark syncing
  → Upsert report using device UUID
  → Upload media
  → Create media row
  → Mark local report synced
  → Pull authoritative remote status
```

If any step fails:

- Preserve the local report.
- Mark it failed.
- Increment retry count.
- Save the error.
- Retry later.

#### My reports queue

Own:

- Local report list.
- Pending/synced/failed indicators.
- Sync button.
- Retry failed items.
- Error details.
- Offline-safe state.
- Report detail navigation.
- Remote refresh when online.

#### Admin dashboard

Own:

- Admin-only route protection.
- Total report metric.
- Open report metric.
- Acknowledged report metric.
- Inspection-required metric.
- Resolved report metric.
- Section grouping.
- Hazard-type filtering.
- Severity filtering.
- Status filtering.
- Date-range filtering.
- Search.
- Refresh.
- Loading, empty, offline-cache, and error states.
- Supabase-backed report loading.

#### Admin report detail and workflow

Own:

- Report photo.
- Report metadata.
- Uploader profile.
- Confirmed classification.
- AI classification.
- AI provider/model metadata.
- Current status.
- Acknowledge action.
- Require inspection action.
- Resolve action.
- Supervisor comments.
- Status history.
- Server-side authorization.
- Local-cache update after mutation.

#### User and section administration

If included in the first release:

- List users.
- Approve pending users.
- Assign gangman/admin roles.
- Assign sections.
- Deactivate users.
- View last sign-in.

If not included, seed authorized users through secure administration tools and track this as a follow-up feature.

## 11. AI Requirements

### Offline Gemma

The offline provider must:

- Detect model installation.
- Detect model readiness.
- Initialize only once where possible.
- Show loading progress.
- Release resources correctly.
- Work with no network.
- Return structured results.
- Include model metadata.
- Fall back safely if the device cannot run the model.

### Online Gemini

Gemini must:

- Be called through a Supabase Edge Function or equivalent secure backend.
- Validate the authenticated user server-side.
- Enforce rate limits.
- Validate image size and MIME type.
- Return strict structured JSON.
- Log failures safely.
- Include language and location context.
- Never expose the API key to Flutter.

### AI safety rules

The model must:

- Use only supported hazard types.
- Use only supported severity values.
- Produce an observational note.
- Avoid operational orders.
- Preserve human confirmation.
- Keep original AI output for auditing.
- Treat track defects as high-risk suggestions requiring human verification.

## 12. Localization

Use ARB files:

```text
lib/l10n/
  app_en.arb
  app_hi.arb
  app_bn.arb
  app_ne.arb
```

Localize:

- Authentication.
- Navigation.
- Home.
- Camera.
- GPS and permissions.
- Review.
- Confirmation.
- Hazard types.
- Severity.
- Inspection statuses.
- Sync states.
- Dashboard.
- Admin actions.
- Errors.
- Empty states.
- Loading states.
- AI disclaimers.

AI-generated notes must store the language code used to produce them.

## 13. Synchronization Rules

Synchronization must be safe if:

- The app is killed during upload.
- The network disappears midway.
- A report upsert succeeds but media upload fails.
- Media upload succeeds but local sync marking fails.
- The same report is retried multiple times.
- A remote admin status update arrives while the gangman is offline.
- Multiple reports are queued.
- A user signs in on multiple devices.

The device report UUID must be used as the idempotency key.

Never create a duplicate report because of a retry.

## 14. Testing Requirements

### Unit tests

Test:

- Domain-model serialization.
- Hazard/severity conversion.
- GPS waypoint selection.
- Section and kilometre estimation.
- AI JSON parsing.
- AI output sanitization.
- Provider selection.
- Sync retry/backoff.
- Idempotent upload behavior.
- Role decisions.
- Localization key coverage.

### Widget tests

Test:

- Google sign-in.
- Role loading.
- Camera permission errors.
- GPS permission errors.
- Capture/review flow.
- Human override of AI values.
- Queue status display.
- Sync button states.
- Admin filters.
- Status-action confirmation.

### Integration tests

Test:

- Offline report creation.
- Local save.
- Queue visibility.
- Reconnection-triggered synchronization.
- Failed upload and retry.
- Duplicate sync prevention.
- Admin access to synced reports.
- Admin status changes.
- Gangman visibility of updated status.
- Role-based route protection.

### Manual device tests

Test:

- Airplane mode.
- Weak station connectivity.
- Camera permission denied.
- GPS unavailable.
- Poor GPS accuracy.
- Low storage.
- App killed during sync.
- App upgrade with local reports.
- Multiple queued reports.
- Large images.
- Hindi rendering.
- Bengali rendering.
- Nepali rendering.
- Sunlight readability.
- Large touch targets.
- Use with gloves where practical.

## 15. Definition of Done

A feature is complete only when:

- The screen is implemented.
- Its controller/notifier exists.
- Repository integration is complete.
- Loading state exists.
- Empty state exists.
- Error state exists.
- Offline state exists.
- All text is localized in four languages.
- Authorization is enforced where applicable.
- Local and remote behavior is defined.
- Tests are included.
- No secrets are committed.
- Accessibility labels exist.
- Touch targets are appropriate.
- Formatting passes.
- Static analysis passes.
- Relevant tests pass.
- The pull request documents changed files, behavior, tests, and limitations.

## 16. Implementation Phases

### Phase 0 — Shared foundation

Both developers:

- Inspect the empty Flutter app.
- Decide state management.
- Define domain models.
- Configure environments.
- Configure Supabase.
- Create local database schema.
- Add router and guards.
- Add theme.
- Create four localization files.
- Agree on Git branch ownership.

### Phase 1 — Offline field MVP

Shahbaz:

- Auth shell.
- Gangman home.
- Camera.
- GPS.
- Review.
- Manual and offline AI interfaces.

Debashish:

- Local database.
- Local media storage.
- Draft persistence.
- Queue.
- Sync-state model.
- Connectivity service.

Milestone:

> A gangman can create and review a report in airplane mode, save it locally, and see it in the queue.

### Phase 2 — Supabase synchronization

Debashish:

- Report upsert.
- Media upload.
- RLS.
- Retry and idempotency.
- Remote fetching.

Shahbaz:

- Sync indicators.
- Provider/model metadata.
- Sync errors in field screens.

Milestone:

> An offline report synchronizes when connectivity returns without duplication.

### Phase 3 — Role-based administration

Debashish:

- Admin dashboard.
- Admin report detail.
- Status workflow.
- Audit history.
- User administration if included.

Shahbaz:

- Role-aware navigation.
- Gangman detail.
- Profile and logout screens.

Milestone:

> An authorized admin can view a synced report and change its status.

### Phase 4 — Production AI

Shahbaz:

- Cactus/Gemma integration.
- Gemini client abstraction.
- Language-aware prompts.
- Output validation.
- Model settings.

Debashish:

- Secure Gemini backend function.
- Authorization.
- Rate limiting.
- Logging and failure handling.

Milestone:

> Online and offline models produce consistent, auditable suggestions.

### Phase 5 — Release hardening

Both developers:

- Complete localization.
- Security review.
- Offline stress testing.
- Sync conflict testing.
- Database migration testing.
- Accessibility review.
- Release signing.
- CI/CD.
- Crash reporting.
- Production runbook.

## 17. Recommended Git Branches

```text
master
  ├── feature/shared-foundation
  ├── feature/shahbaz-field-reporting
  ├── feature/shahbaz-ai
  ├── feature/debashish-supabase-sync
  ├── feature/debashish-admin-dashboard
  └── feature/integration-tests
```

Avoid having both developers edit the same feature files simultaneously.

Shared files should be modified through coordinated pull requests:

```text
lib/core/models/
lib/core/router.dart
lib/core/theme.dart
lib/core/localization/
lib/core/storage/
```

## 18. AI Coding Tool Instructions

When an AI coding tool receives a task in this repository:

1. Read this file completely before making changes.
2. Inspect the existing Flutter project before assuming file paths.
3. Search for existing models, providers, repositories, routes, and localization keys.
4. Do not recreate architecture that already exists.
5. Keep changes scoped to the requested feature.
6. Respect Shahbaz and Debashish ownership boundaries.
7. Do not modify shared contracts without checking impact.
8. Do not call Supabase directly from widgets.
9. Do not place API keys or service-role credentials in Flutter.
10. Do not replace offline behavior with online-only behavior.
11. Do not delete failed or unsynced reports.
12. Preserve human-in-the-loop behavior.
13. Add tests for changed logic.
14. Add localization keys for all four languages.
15. Run formatting and static analysis.
16. Run targeted tests.
17. Report changed files, implementation details, tests, limitations, and follow-ups.

Preferred development sequence:

```text
Understand existing code
  → Identify affected feature and owner
  → Inspect contracts and dependencies
  → Implement the smallest coherent change
  → Add tests and localization
  → Run formatter
  → Run static analysis
  → Run targeted tests
  → Summarize risks and follow-ups
```

For synchronization changes, explicitly evaluate:

- Duplicate uploads.
- App termination during upload.
- Network loss after upsert.
- Media upload failure.
- Local mark-as-synced failure.
- Remote status changes.
- Retry count.
- Error persistence.
- Conflict behavior.

For AI changes, explicitly evaluate:

- Offline availability.
- Model initialization failure.
- Invalid model output.
- Unsupported hazard type.
- Unsupported severity.
- Language mismatch.
- Human override preservation.
- Prompt safety.
- Operational-decision boundaries.

## 19. Final Product Direction

Build TrackGuard DHR as a reliable field-operations application, not only as a demo.

The final application must:

- Work in poor or absent connectivity.
- Preserve reports safely on the device.
- Synchronize without duplicates.
- Support both offline and online AI.
- Keep humans in control of final classification.
- Protect report data through authentication and RLS.
- Give admins a useful section-wise dashboard.
- Maintain auditability of AI suggestions and supervisor actions.
- Work in English, Hindi, Bengali, and Nepali.
- Be maintainable by both developers after the initial release.