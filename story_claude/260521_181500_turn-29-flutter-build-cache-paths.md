# Turn 29 — Flutter build cache paths (offline dev)

**User prompt:**
> I build flutter project for android and windows. Where cache files
> are stored when building flutter project like vLearn2. I can
> manually copy cache files to a area where no internet so i can
> continue develop

**Assistant response:**
Identified the four caches to mirror for offline Flutter dev, with
sizes measured on this machine:

| Cache | Path | Size | Override env |
|---|---|---|---|
| Flutter SDK (+ `bin/cache/` engine artifacts) | `C:\flutter` | ~2–5 GB | on PATH |
| Pub cache | `C:\Users\aaa\AppData\Local\Pub\Cache` | ~2 GB | `PUB_CACHE` |
| Gradle cache | `C:\Users\aaa\.gradle` | ~16 GB | `GRADLE_USER_HOME` |
| Android SDK | `C:\Users\aaa\AppData\Local\Android\Sdk` | ~33 GB | `ANDROID_HOME` |

Total ≈ 50–55 GB. Offline box still needs a JDK and Visual Studio's
"Desktop development with C++" workload (not copyable as cache). Use
`flutter pub get --offline`; run `flutter pub get` online first so
everything in `pubspec.lock` is in the pub cache. Project-local
`.dart_tool/`, `build/`, `android/.gradle/`, `windows/build/` are
regenerable derivatives — optional to copy.

## Latest prompt

> I build flutter project for android and windows.
> Where cache files are stored when building flutter project like
> vLearn2. I can manually copy cache files to a area where no internet
> so i can continue develop
