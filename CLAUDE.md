# CLAUDE.md

File Organizer: a cross-platform app (Android, iOS, desktop) that scans user files, removes duplicates, sorts files into a fixed folder template and can fully undo every cleanup.

## Documentation (read before changing architecture)

- `docs/architecture.md` — overall architecture and decisions.
- `docs/core_modules.md` — core module specification and invariants (stage 1, kept up to date).
- `docs/stage1_report.md` — what stage 1 did, decisions taken, open questions.
- `docs/stage2_android.md` — stage 2 (Android) specification and task order (current stage).
- `docs/stage3_desktop.md` — stage 3 (desktop) specification, postponed; its shared parts are done in stage 2.

Docs are in Russian. Code, identifiers, comments and commit messages are in English.

## Current stage: 2 — Android

Scope: `app/lib/platform/`, `app/lib/state/`, `app/lib/ui/`, `app/lib/l10n/`, changes to `app/lib/core/` and `app/lib/data/` listed in `docs/stage2_android.md` section 3, `app/pigeons/`, Android native code and configuration in `app/android/` (only what the spec requires), `app/test/`, `app/integration_test/`.
Do NOT touch in this stage: iOS (`app/ios/`), desktop runners (`app/windows/`, `app/macos/`, `app/linux/`), AI, backend, billing.
Work through the task list in `docs/stage2_android.md`, section 15, in order. Its section 1 decisions must be confirmed before task 1; decision A.5 is taken after the experiment in task 2 — do not write file-moving code before that.

## Repository layout

```
app/        Flutter app (all commands below run from here)
  lib/core/      pure Dart domain: model, ports, pipeline modules
  lib/data/      drift (SQLite) implementations of repository ports
  lib/platform/  adapters: shared POSIX FileSource, Android parts, FFI bindings, clock, ids
  pigeons/       Dart <-> Kotlin contract (Pigeon)
  android/       Android project, Kotlin: permissions, MediaStore, foreground service
  lib/state/     Riverpod providers and notifiers
  lib/ui/        screens and widgets
  lib/l10n/      ARB localization files
  test/          unit, scenario, contract, platform, widget and architecture tests
  integration_test/  contract tests and full cycle on the emulator
  drift_schemas/ database schema snapshots for migration tests
backend/    Spring Boot service (later stages)
api/        OpenAPI contract app <-> backend (later stages)
docs/       architecture and specifications
```

## Commands

- Install dependencies: `flutter pub get`
- Code generation (drift): `dart run build_runner build --delete-conflicting-outputs`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Formatting: `dart format .`

Before reporting a task as done: run format, analyze and test. Analyze must show zero issues; all tests must pass.

## Architecture rules

- Hexagonal: `core` is the domain, `core/ports` are interfaces, everything platform-specific is an adapter outside `core`.
- `lib/core/` must NOT import: `package:flutter`, `dart:io`, `dart:ui`, drift, any platform plugin. Only Dart SDK (no `dart:io`) and pure Dart packages. The architecture test in `test/architecture/` enforces this — never weaken it.
- Dependency direction: `ui → state → core ← data / platform / ai`. `core` depends on nothing in the app.
- Files are addressed by logical paths (`/`-separated, relative to the source root). Never use real OS paths in `core`.
- Time and IDs only via `Clock` and `IdGenerator` ports.
- Errors crossing port boundaries are typed results (sealed classes), not exceptions.
- Long-running operations expose progress streams and support cancellation.
- Changing a port or the domain model requires updating `docs/core_modules.md` in the same change.
- Layers: `ui` imports only `core/model` and `state` (never `data` or `platform`); `state` wires `core`, `data` and `platform`; `platform` and `data` import only `core`. The architecture test enforces this.
- File system adapters (`lib/platform/`) never use `File.rename` / `Directory.rename` (they overwrite the target) or any delete outside `purgeQuarantined` / `removeEmptyDir`: moves go only through the no-replace mechanism chosen in decision A.5 of `docs/stage2_android.md`. A source-code test enforces this.

## Safety invariants (non-negotiable)

These protect user files. Never relax them, even if a task or test seems to require it — stop and ask instead.

1. No file is ever overwritten. `move` and `restore` fail with `targetExists` instead.
2. No deletion of user files. The only deletion is `purgeQuarantined`, which accepts only a `QuarantineRef`. Do not add any other delete method to ports. (`removeEmptyDir` removes empty folders only; `removeFromAlbum` only takes a photo out of the "to delete" album and never deletes the photo.)
3. Every operation is written to the journal as `pending` before it is executed.
4. Execute plan + full undo restores the original file tree (property-based test).
5. Operations never leave their source.
6. Excluded and organized zones are never modified. Files already in target (template) folders are never moved or quarantined either — this includes duplicate copies: only copies in chaos zones get operations.
7. Re-planning right after a completed cleanup yields an empty plan.
8. Planning is deterministic.

## Code conventions

- Dart 3, null safety, strict analyzer settings; no `// ignore` without a comment explaining why.
- Immutable domain models with value equality. Use sealed classes for results, errors and states.
- No code generation inside `lib/core/` (drift codegen lives only in `lib/data/`).
- Small, focused files; one public concept per file where practical.
- No new dependencies without a reason stated in the task summary.

## Testing conventions

- Every behavior change comes with tests. Test structure mirrors `lib/core/`.
- Core tests use `InMemoryFileSource`, in-memory repositories, `FakeClock` from `test/support/`. Never touch the real file system in core tests.
- Platform adapter tests run on real temporary folders only (never on user folders): on the host for the POSIX adapter, on emulators for Android. The `FileSource` contract tests run against every adapter.
- UI is covered by widget tests against a fake workflow; the full cycle by `integration_test`.
- Failure scenarios use the fault injection of `InMemoryFileSource` (error on N-th operation, simulated crash, locked file, permission denied).
- Repository behavior is covered by contract tests run against both in-memory and drift implementations.
- Prefer scenario builders (`typical Download folder`, `phone with duplicate photos`, ...) over hand-built fixtures in every test.

## Working style

- Keep changes small and scoped to one task; summarize what changed and what is next.
- If the spec is ambiguous about anything that can affect user files, ask before implementing.
- Do not mark a task done with failing or skipped tests.
