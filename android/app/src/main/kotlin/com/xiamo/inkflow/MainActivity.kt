package com.xiaomo.inkflow

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val updateChannelName = "com.xiaomo.inkflow/update"
    private val notificationChannelId = "inkflow_updates"
    private val downloadNotificationId = 1001
    private val notificationPermissionRequestCode = 2001
    private var notificationPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updateChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensureNotificationPermission" -> ensureNotificationPermission(result)
                "showDownloadProgress" -> {
                    showDownloadProgress(
                        call.argument<String>("title").orEmpty(),
                        call.argument<String>("text").orEmpty(),
                        call.argument<Int>("progress") ?: 0,
                        call.argument<Boolean>("indeterminate") ?: false,
                    )
                    result.success(null)
                }
                "showDownloadComplete" -> {
                    showDownloadComplete(
                        call.argument<String>("title").orEmpty(),
                        call.argument<String>("text").orEmpty(),
                        call.argument<String>("filePath").orEmpty(),
                    )
                    result.success(null)
                }
                "showDownloadFailed" -> {
                    showDownloadFailed(
                        call.argument<String>("title").orEmpty(),
                        call.argument<String>("text").orEmpty(),
                    )
                    result.success(null)
                }
                "cancelDownloadNotification" -> {
                    notificationManager().cancel(downloadNotificationId)
                    result.success(null)
                }
                "installApk" -> {
                    try {
                        installApk(call.argument<String>("filePath").orEmpty())
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("INSTALL_APK_FAILED", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensureNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        if (notificationPermissionResult != null) {
            result.success(false)
            return
        }

        notificationPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), notificationPermissionRequestCode)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationPermissionRequestCode) {
            val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
            notificationPermissionResult?.success(granted)
            notificationPermissionResult = null
        }
    }

    private fun showDownloadProgress(title: String, text: String, progress: Int, indeterminate: Boolean) {
        if (!canPostNotifications()) return
        val manager = notificationManager()
        createNotificationChannel(manager)

        val builder = notificationBuilder()
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(appPendingIntent())
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setProgress(100, progress.coerceIn(0, 100), indeterminate)

        manager.notify(downloadNotificationId, builder.build())
    }

    private fun showDownloadComplete(title: String, text: String, filePath: String) {
        if (!canPostNotifications()) return
        val manager = notificationManager()
        createNotificationChannel(manager)

        val builder = notificationBuilder()
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(installPendingIntent(filePath))
            .setAutoCancel(true)
            .setOngoing(false)
            .setProgress(0, 0, false)

        manager.notify(downloadNotificationId, builder.build())
    }

    private fun showDownloadFailed(title: String, text: String) {
        if (!canPostNotifications()) return
        val manager = notificationManager()
        createNotificationChannel(manager)

        val builder = notificationBuilder()
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(appPendingIntent())
            .setAutoCancel(true)
            .setOngoing(false)
            .setProgress(0, 0, false)

        manager.notify(downloadNotificationId, builder.build())
    }

    private fun installApk(filePath: String) {
        if (filePath.isBlank()) return
        startActivity(installIntent(filePath).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }

    private fun notificationBuilder(): Notification.Builder {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, notificationChannelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun createNotificationChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val existing = manager.getNotificationChannel(notificationChannelId)
        if (existing != null) return

        val channel = NotificationChannel(
            notificationChannelId,
            "InkFlow Updates",
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    private fun canPostNotifications(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    private fun appPendingIntent(): PendingIntent {
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(this, 0, intent, pendingIntentFlags())
    }

    private fun installPendingIntent(filePath: String): PendingIntent {
        return PendingIntent.getActivity(this, 1, installIntent(filePath), pendingIntentFlags())
    }

    private fun installIntent(filePath: String): Intent {
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            File(filePath),
        )
        return Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun pendingIntentFlags(): Int {
        val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
        return PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
    }
}
