package com.example.bagoo_rider_mobile

import android.Manifest
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationRequest: MethodChannel.Result? = null
    private val notificationRequestCode = 4107

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bagoo/navigation_permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "notificationsAllowed" -> result.success(notificationsAllowed())
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT < 33 || notificationsAllowed()) {
                            result.success(notificationsAllowed())
                        } else if (notificationRequest != null) {
                            result.error("REQUEST_PENDING", "Notification permission is already being requested.", null)
                        } else {
                            notificationRequest = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), notificationRequestCode)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun notificationsAllowed(): Boolean {
        val granted = Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        val enabled = Build.VERSION.SDK_INT < 24 ||
            getSystemService(NotificationManager::class.java).areNotificationsEnabled()
        return granted && enabled
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationRequestCode) {
            notificationRequest?.success(notificationsAllowed())
            notificationRequest = null
        }
    }

    override fun onDestroy() {
        notificationRequest?.error("ACTIVITY_CLOSED", "Return to the app to request notification permission.", null)
        notificationRequest = null
        super.onDestroy()
    }
}
