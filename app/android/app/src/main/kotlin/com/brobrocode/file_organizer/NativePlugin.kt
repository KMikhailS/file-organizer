package com.brobrocode.file_organizer

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationManager
import android.graphics.Bitmap
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.provider.MediaStore
import android.provider.Settings
import android.util.Size
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.io.IOException

/**
 * The native side of `pigeons/native_api.dart` (docs/stage2_android.md,
 * sections 5.2, 5.3 and 5.9): permissions, the storage root, capture dates
 * from MediaStore, and the foreground service.
 *
 * Nothing here reads, moves or deletes user files: file operations are
 * done in Dart (decision A.3).
 */
class NativePlugin :
    FlutterPlugin,
    ActivityAware,
    AccessApi,
    StorageApi,
    ForegroundApi,
    PluginRegistry.ActivityResultListener,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var context: Context
    private var activity: ActivityPluginBinding? = null
    private var allFilesRequest: ((Result<Boolean>) -> Unit)? = null
    private var notificationRequest: ((Result<Boolean>) -> Unit)? = null

    // ------------------------------------------------------------ plugin

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val messenger = binding.binaryMessenger
        AccessApi.setUp(messenger, this)
        StorageApi.setUp(messenger, this)
        ForegroundApi.setUp(messenger, this)
        val events = ForegroundEvents(messenger)
        CleanupService.onTimeout = { events.onTimeout {} }
        CleanupService.onCancel = { events.onCancelRequested {} }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        AccessApi.setUp(messenger, null)
        StorageApi.setUp(messenger, null)
        ForegroundApi.setUp(messenger, null)
        CleanupService.onTimeout = null
        CleanupService.onCancel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activity?.removeActivityResultListener(this)
        activity?.removeRequestPermissionsResultListener(this)
        activity = null
    }

    // ------------------------------------------------------------ access

    override fun hasAllFilesAccess(): Boolean = Environment.isExternalStorageManager()

    override fun requestAllFilesAccess(callback: (Result<Boolean>) -> Unit) {
        if (hasAllFilesAccess()) {
            callback(Result.success(true))
            return
        }
        val activity = activityOrFail(callback) ?: return
        if (allFilesRequest != null) {
            callback(Result.failure(FlutterError("busy", "a request is already open")))
            return
        }
        val forApp = Intent(
            Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
            Uri.fromParts("package", context.packageName, null),
        )
        // Some devices have only the list of all apps.
        val intent = if (forApp.resolveActivity(context.packageManager) != null) {
            forApp
        } else {
            Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
        }
        allFilesRequest = callback
        activity.startActivityForResult(intent, REQUEST_ALL_FILES)
    }

    override fun hasNotificationPermission(): Boolean {
        val granted = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        return granted && notificationManager().areNotificationsEnabled()
    }

    override fun requestNotificationPermission(callback: (Result<Boolean>) -> Unit) {
        if (hasNotificationPermission() || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            callback(Result.success(hasNotificationPermission()))
            return
        }
        val activity = activityOrFail(callback) ?: return
        if (notificationRequest != null) {
            callback(Result.failure(FlutterError("busy", "a request is already open")))
            return
        }
        notificationRequest = callback
        activity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_ALL_FILES) return false
        // The settings screen has no result: what counts is the state now.
        allFilesRequest?.invoke(Result.success(hasAllFilesAccess()))
        allFilesRequest = null
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_NOTIFICATIONS) return false
        notificationRequest?.invoke(Result.success(hasNotificationPermission()))
        notificationRequest = null
        return true
    }

    private fun activityOrFail(callback: (Result<Boolean>) -> Unit): Activity? {
        val activity = activity?.activity
        if (activity == null) {
            callback(Result.failure(FlutterError("no-activity", "the app is not on screen")))
        }
        return activity
    }

    // ----------------------------------------------------------- storage

    override fun primaryStorageRoot(): String? {
        val volume = context.getSystemService(StorageManager::class.java).primaryStorageVolume
        if (volume.state != Environment.MEDIA_MOUNTED) return null
        return volume.directory?.absolutePath
    }

    @Suppress("DEPRECATION") // DATA: the path, readable with "All files access".
    override fun capturedDates(paths: List<String>): Map<String, Long> {
        val dates = HashMap<String, Long>()
        val uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(MediaStore.MediaColumns.DATA, MediaStore.MediaColumns.DATE_TAKEN)
        for (batch in paths.distinct().chunked(DATES_BATCH)) {
            val selection = "${MediaStore.MediaColumns.DATA} IN (" +
                batch.joinToString(",") { "?" } + ") AND " +
                "${MediaStore.MediaColumns.DATE_TAKEN} IS NOT NULL"
            context.contentResolver
                .query(uri, projection, selection, batch.toTypedArray(), null)
                ?.use { cursor ->
                    while (cursor.moveToNext()) {
                        dates[cursor.getString(0)] = cursor.getLong(1)
                    }
                }
        }
        return dates
    }

    override fun thumbnail(path: String, size: Long): ByteArray? {
        val files = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        val projection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.Files.FileColumns.MEDIA_TYPE)
        val (id, mediaType) = context.contentResolver
            .query(files, projection, "${MediaStore.MediaColumns.DATA} = ?", arrayOf(path), null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getLong(0) to cursor.getInt(1) else null
            } ?: return null
        val collection = when (mediaType) {
            MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE ->
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
            MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO ->
                MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
            else -> return null
        }
        val edge = size.coerceIn(1, MAX_THUMBNAIL).toInt()
        return try {
            val bitmap = context.contentResolver.loadThumbnail(
                ContentUris.withAppendedId(collection, id),
                Size(edge, edge),
                null,
            )
            ByteArrayOutputStream().use { out ->
                bitmap.compress(Bitmap.CompressFormat.JPEG, THUMBNAIL_QUALITY, out)
                bitmap.recycle()
                out.toByteArray()
            }
        } catch (e: IOException) {
            // No thumbnail for this file (broken, or a format the system
            // cannot decode): the UI shows an icon.
            null
        }
    }

    // -------------------------------------------------------- foreground

    override fun start(notice: ForegroundNotice) = CleanupService.start(context, notice)

    override fun update(notice: ForegroundNotice) = CleanupService.update(context, notice)

    override fun stop() = CleanupService.stop(context)

    override fun isRunning(): Boolean = CleanupService.running

    override fun currentNotice(): ForegroundNotice? {
        val manager = notificationManager()
        val shown = manager.activeNotifications
            .firstOrNull { it.id == CleanupService.NOTIFICATION_ID } ?: return null
        val extras = shown.notification.extras
        val channel = manager.getNotificationChannel(shown.notification.channelId)
        return ForegroundNotice(
            title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: "",
            text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "",
            channelName = channel?.name?.toString() ?: "",
            done = extras.getInt(Notification.EXTRA_PROGRESS).toLong(),
            total = extras.getInt(Notification.EXTRA_PROGRESS_MAX).toLong(),
            cancelLabel = shown.notification.actions?.firstOrNull()?.title?.toString(),
        )
    }

    private fun notificationManager() =
        context.getSystemService(NotificationManager::class.java)

    private companion object {
        const val REQUEST_ALL_FILES = 4711
        const val REQUEST_NOTIFICATIONS = 4712

        /** Paths per MediaStore query: SQLite allows 999 parameters. */
        const val DATES_BATCH = 500

        /** The largest thumbnail edge served, in pixels. */
        const val MAX_THUMBNAIL = 512L
        const val THUMBNAIL_QUALITY = 85
    }
}
