package com.brobrocode.file_organizer

import android.content.Context
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * The only screen. Its Flutter engine lives in [FlutterEngineCache], not in
 * the activity (decision A.7, docs/stage2_android.md, section 5.3): closing
 * or leaving the screen does not stop the Dart code, so a cleanup goes on
 * under the foreground service, and the reopened screen shows its current
 * state.
 */
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(ENGINE_ID)?.let { return it }
        // Once per process; integration_test/lifecycle counts this line.
        Log.i(LOG_TAG, "new Flutter engine")
        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        cache.put(ENGINE_ID, engine)
        return engine
    }

    /** The engine outlives the activity; it goes with the process. */
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Called for every new activity on the same engine: register once.
        if (!flutterEngine.plugins.has(NativePlugin::class.java)) {
            super.configureFlutterEngine(flutterEngine)
            flutterEngine.plugins.add(NativePlugin())
        }
    }

    private companion object {
        const val ENGINE_ID = "main"
        const val LOG_TAG = "FileOrganizer"
    }
}
