package app.lastlight.lastlight

import android.content.Intent
import android.provider.Settings
import android.telecom.TelecomManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val store = NightStore(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.lastlight/night").setMethodCallHandler { call, result ->
            try {
                val service = LastlightAccessibilityService.instance
                when (call.method) {
                    "state" -> { service?.checkNow(); result.success(store.state(service != null)) }
                    "apps" -> {
                        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                        val home = packageManager.resolveActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), 0)?.activityInfo?.packageName
                        val dialer = getSystemService(TelecomManager::class.java)?.defaultDialerPackage
                        @Suppress("DEPRECATION")
                        val apps = packageManager.queryIntentActivities(launcher, 0)
                            .filter { it.activityInfo.packageName !in setOf(packageName, home, dialer, "com.android.settings") }
                            .map { mapOf("packageName" to it.activityInfo.packageName, "name" to it.loadLabel(packageManager).toString()) }
                            .distinctBy { it["packageName"] }.sortedBy { it["name"]?.lowercase() }
                        result.success(apps)
                    }
                    "saveSettings" -> { store.save(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()); result.success(null) }
                    "openAccess" -> { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); result.success(null) }
                    "start" -> {
                        require(service != null) { "Enable Lastlight Accessibility in Android Settings first." }
                        store.start(); service.checkNow(); result.success(null)
                    }
                    "bypass" -> { store.bypass(); service?.checkNow(); result.success(null) }
                    "claim" -> { store.claim(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: IllegalArgumentException) { result.error("boundary", e.message, null) }
            catch (_: Exception) { result.error("native", "The action could not finish. Please try again.", null) }
        }
    }
}
