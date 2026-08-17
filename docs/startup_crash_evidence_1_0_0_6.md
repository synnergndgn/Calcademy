# Calcademy 1.0.0+6 — startup crash evidence

**Captured:** 07-25 05:27:11 (device logcat, release build)
**Package:** `com.aligundogan.calcademy`
**Outcome:** process died during `handleBindApplication`, before any Flutter
frame — the splash layer was already up, so the user saw a flash and then a
force-close.

This file replaces the full-device logcat capture that used to be tracked as
`crash_log.txt`. That capture contained the complete installed-app inventory of
a personal device and had no business being in a public repository; only the
Calcademy fault matters as engineering evidence, and it is reproduced in full
below. The original remains local and is ignored by `.gitignore`.

## Fault

```
FATAL EXCEPTION: main
Process: com.aligundogan.calcademy, PID: 20098
java.lang.RuntimeException: Unable to get provider androidx.startup.InitializationProvider: com.google.android.gms.internal.ads.nd: java.lang.RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
	at android.app.ActivityThread.installProvider(ActivityThread.java:9157)
	at android.app.ActivityThread.installContentProviders(ActivityThread.java:8657)
	at android.app.ActivityThread.handleBindApplication(ActivityThread.java:8285)
	at android.app.ActivityThread.-$$Nest$mhandleBindApplication(ActivityThread.java:0)
	at android.app.ActivityThread$H.handleMessage(ActivityThread.java:2661)
	at android.os.Handler.dispatchMessage(Handler.java:107)
	at android.os.Looper.loopOnce(Looper.java:249)
	at android.os.Looper.loop(Looper.java:337)
	at android.app.ActivityThread.main(ActivityThread.java:9593)
	at java.lang.reflect.Method.invoke(Native Method)
	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:593)
	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:936)
Caused by: com.google.android.gms.internal.ads.nd: java.lang.RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
	at g1.a.b(r8-map-id-56994efe…:174)
	at g1.a.a(r8-map-id-56994efe…:84)
	at androidx.startup.InitializationProvider.onCreate(r8-map-id-56994efe…:55)
	at android.content.ContentProvider.attachInfo(ContentProvider.java:2654)
	at android.content.ContentProvider.attachInfo(ContentProvider.java:2620)
	at android.app.ActivityThread.installProvider(ActivityThread.java:9152)
	... 11 more
Caused by: java.lang.RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
	at v1.l.<init>(r8-map-id-56994efe…:593)
	at v1.l.c(r8-map-id-56994efe…:42)
	at androidx.work.WorkManagerInitializer.b(r8-map-id-56994efe…:27)
	at g1.a.b(r8-map-id-56994efe…:161)
	... 16 more
```

R8 map id, truncated above for width:
`56994efed3bb4cd0ccacad27a26aecbc1f83a2f9a9f920e598c24836cccc019a`

## Reading

The chain is `play-services-ads` → `androidx.startup.InitializationProvider` →
`WorkManagerInitializer` → `WorkDatabase`. The frames that fail are R8-renamed
(`g1.a`, `v1.l`), which is the tell: Room builds `WorkDatabase` reflectively, so
under R8 full mode the generated implementation class is stripped or renamed and
the instantiation fails at runtime. Nothing here is an AdMob defect — the ads SDK
only pulls in the `androidx.work`/Room pair that was already mismatched.

The crash therefore does not reproduce in debug or profile builds, which is why
1.0.0+5 and +6 shipped with it. It reproduces only in a minified release.

## Resolution

Fixed in 1.0.0+8 by forcing a consistent `androidx.work`/Room pair and keeping
the Room-generated classes through R8. See `docs/monetization_strategy.md` for
the sprint record. The keep rules and version forcing are load-bearing: removing
either brings this crash back, and only in release.
