package app.replock.replock

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.os.Build
import android.provider.Settings
import android.telecom.TelecomManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingChallenge: MethodChannel.Result? = null
    private var pendingSteps: MethodChannel.Result? = null
    private val store by lazy { RepStore(this) }
    private fun apps(): List<Map<String, String>> {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val home = packageManager.resolveActivity(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), 0)?.activityInfo?.packageName
        val dialer = getSystemService(TelecomManager::class.java)?.defaultDialerPackage
        @Suppress("DEPRECATION")
        return packageManager.queryIntentActivities(launcher, 0)
            .filter { it.activityInfo.packageName !in setOf(packageName, home, dialer, "com.android.settings", "com.android.systemui") }
            .map { mapOf("id" to it.activityInfo.packageName, "name" to it.loadLabel(packageManager).toString()) }
            .distinctBy { it["id"] }.sortedBy { it["name"]?.lowercase() }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.replock/device").setMethodCallHandler { call, result ->
            try {
                val service = RepAccessibilityService.instance
                when (call.method) {
                    "state" -> result.success(store.state(service != null, (getSystemService(SENSOR_SERVICE) as SensorManager).getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null))
                    "apps" -> result.success(apps())
                    "onboard" -> { store.onboard(); result.success(null) }
                    "selectApps" -> {
                        val available = apps().map { it.getValue("id") }.toSet()
                        val chosen = call.argument<List<String>>("ids") ?: emptyList()
                        require(chosen.all { it in available }) { "Some selected apps are no longer installed." }
                        store.selected = chosen.toSet(); service?.checkNow(); result.success(null)
                    }
                    "openAccess" -> { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); result.success(null) }
                    "protect" -> {
                        val enabled = call.argument<Boolean>("enabled") == true
                        require(!enabled || service != null) { "Enable RepLock in Android Accessibility settings first." }
                        require(!enabled || store.selected.isNotEmpty()) { "Choose at least one app to protect." }
                        store.protection = enabled; if (!enabled) store.endPass(); service?.checkNow(); result.success(null)
                    }
                    "challenge" -> {
                        require(pendingChallenge == null) { "A challenge is already running." }
                        val exercise = store.canExercise(call.argument<String>("id") ?: "")
                        pendingChallenge = result
                        @Suppress("DEPRECATION")
                        startActivityForResult(Intent(this, ChallengeActivity::class.java).putExtra("exercise", exercise.id), 41)
                    }
                    "redeem" -> {
                        val id = call.argument<String>("id") ?: ""
                        val app = apps().find { it["id"] == id } ?: error("This app is no longer installed.")
                        store.redeem(id, app.getValue("name"), call.argument<Int>("minutes") ?: 0)
                        service?.checkNow(); result.success(null)
                    }
                    "launchApp" -> {
                        val id = call.argument<String>("id") ?: ""
                        require(id == store.activeApp && store.remainingMs > 0) { "This pass has ended." }
                        startActivity(packageManager.getLaunchIntentForPackage(id) ?: error("App unavailable.")); result.success(null)
                    }
                    "endPass" -> { store.endPass(); service?.checkNow(); result.success(null) }
                    "steps" -> {
                        if (call.argument<Boolean>("enabled") != true) {
                            stopService(Intent(this, StepService::class.java)); store.stepEnabled = false; store.resetSensorBaseline(); result.success(null)
                        } else {
                            require(pendingSteps == null) { "Step permission is already being requested." }
                            require((getSystemService(SENSOR_SERVICE) as SensorManager).getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null) { "This phone has no step-counter sensor." }
                            val permissions = mutableListOf<String>()
                            if (Build.VERSION.SDK_INT >= 29 && checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) != PackageManager.PERMISSION_GRANTED) permissions.add(Manifest.permission.ACTIVITY_RECOGNITION)
                            if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) permissions.add(Manifest.permission.POST_NOTIFICATIONS)
                            if (permissions.isNotEmpty()) { pendingSteps = result; requestPermissions(permissions.toTypedArray(), 42) }
                            else { startSteps(); result.success(null) }
                        }
                    }
                    "claimSteps" -> { store.claimSteps(); result.success(null) }
                    "reset" -> { stopService(Intent(this, StepService::class.java)); store.reset(); service?.checkNow(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("replock", e.message ?: "Couldn't complete that action. Try again.", null) }
        }
    }
    private fun startSteps() {
        store.resetSensorBaseline(); store.stepEnabled = true
        startForegroundService(Intent(this, StepService::class.java))
    }
    @Deprecated("Android result callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 41) { pendingChallenge?.success(if (resultCode == RESULT_OK) data?.getIntExtra("coins", 0) ?: 0 else 0); pendingChallenge = null }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 42) {
            if (Build.VERSION.SDK_INT < 29 || checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED) {
                try { startSteps(); pendingSteps?.success(null) } catch (e: Exception) { pendingSteps?.error("steps", e.message, null) }
            } else pendingSteps?.error("steps", "Activity permission was declined. You can still earn coins with camera challenges.", null)
            pendingSteps = null
        }
    }
}
