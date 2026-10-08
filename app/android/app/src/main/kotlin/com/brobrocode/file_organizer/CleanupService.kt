package com.brobrocode.file_organizer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock

/**
 * Foreground service of type `dataSync` (decision A.7): keeps the process
 * alive while a scan, cleanup or undo runs, and shows its progress.
 *
 * It does no work itself; the Dart code runs in the same process. All state
 * lives on the main thread.
 */
class CleanupService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notice = latest
        if (notice == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        // Called every time: startForegroundService() requires it.
        startForeground(
            NOTIFICATION_ID,
            build(this, notice),
            ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
        )
        running = true
        starting = false
        lastPosted = SystemClock.elapsedRealtime()
        if (stopRequested) {
            // stop() came while the service was starting.
            stopSelf()
        }
        return START_NOT_STICKY
    }

    /** Android 15+: the daily `dataSync` limit ran out. */
    override fun onTimeout(startId: Int, fgsType: Int) {
        onTimeout?.invoke()
        stopSelf()
    }

    override fun onDestroy() {
        running = false
        starting = false
        stopRequested = false
        handler.removeCallbacks(postLatest)
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    companion object {
        const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "cleanup"

        /** At most this many notification updates per second. */
        private const val MIN_UPDATE_INTERVAL_MS = 250L

        /** Whether the service runs in the foreground. */
        @Volatile
        var running = false
            private set

        /** Called when the system stops the service for its time limit. */
        var onTimeout: (() -> Unit)? = null

        private val handler = Handler(Looper.getMainLooper())
        private var latest: ForegroundNotice? = null

        /** startForegroundService() was called, startForeground() not yet. */
        private var starting = false
        private var stopRequested = false
        private var lastPosted = 0L
        private var appContext: Context? = null
        private val postLatest = Runnable { post() }

        fun start(context: Context, notice: ForegroundNotice) {
            appContext = context.applicationContext
            latest = notice
            stopRequested = false
            ensureChannel(context, notice.channelName)
            if (!running) starting = true
            context.startForegroundService(Intent(context, CleanupService::class.java))
        }

        fun update(context: Context, notice: ForegroundNotice) {
            appContext = context.applicationContext
            latest = notice
            if (!running) return
            val wait = lastPosted + MIN_UPDATE_INTERVAL_MS - SystemClock.elapsedRealtime()
            handler.removeCallbacks(postLatest)
            if (wait <= 0) post() else handler.postDelayed(postLatest, wait)
        }

        fun stop(context: Context) {
            handler.removeCallbacks(postLatest)
            if (starting) {
                // Stopping a service before it calls startForeground() makes
                // the system kill the app (ForegroundServiceDidNotStartInTime);
                // it stops itself right after instead.
                stopRequested = true
                return
            }
            context.stopService(Intent(context, CleanupService::class.java))
        }

        private fun post() {
            val context = appContext ?: return
            val notice = latest ?: return
            if (!running) return
            lastPosted = SystemClock.elapsedRealtime()
            context.getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, build(context, notice))
        }

        private fun ensureChannel(context: Context, name: String) {
            // Creating it again only updates the name.
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_LOW),
            )
        }

        private fun build(context: Context, notice: ForegroundNotice): Notification {
            val open = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val tap = open?.let {
                PendingIntent.getActivity(
                    context,
                    0,
                    it,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                )
            }
            val total = notice.total.coerceIn(0, Int.MAX_VALUE.toLong()).toInt()
            val done = notice.done.coerceIn(0, total.toLong()).toInt()
            val builder = Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(notice.title)
                .setContentText(notice.text)
                .setProgress(total, done, total == 0)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_PROGRESS)
                .setContentIntent(tap)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+ may delay it by up to 10 s otherwise.
                builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            return builder.build()
        }
    }
}
