# Turn 30 — explain ANR in a Flutter project

**User prompt:**
> what is The ANR in flutter project

**Assistant response:**
Explained ANR = Android "Application Not Responding" — an Android
system error, not a Flutter concept. Fires when the app's main/UI
thread is blocked too long (~5s for an input event; also
BroadcastReceiver/Service timeouts).

In Flutter the Dart main isolate runs on Android's main thread, so it
gets triggered by synchronous CPU-heavy work on the main isolate (big
JSON parsing, image decode/resize, crypto, sorting large lists) or by
blocking platform-channel calls. `await`-ing a Future does **not**
cause it — that yields the event loop.

Fixes: offload heavy work with `compute()` / `Isolate`, use async I/O,
keep native plugin work off Android's main thread, profile with
DevTools / Android Studio Profiler / Play Console Android Vitals.

## Latest prompt

> what is The ANR in flutter project
