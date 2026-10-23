package app.replock.replock

import android.app.*
import android.content.Intent
import android.hardware.*
import android.os.IBinder

class StepService : Service(), SensorEventListener {
    companion object { var instance: StepService? = null; private set }
    private lateinit var sensors: SensorManager
    private lateinit var store: RepStore
    override fun onCreate() {
        super.onCreate(); instance = this; store = RepStore(this)
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(NotificationChannel("steps", "Step tracking", NotificationManager.IMPORTANCE_LOW))
        val open = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        val stop = PendingIntent.getService(this, 1, Intent(this, StepService::class.java).setAction("stop"), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        startForeground(7, Notification.Builder(this, "steps").setSmallIcon(R.drawable.replock_icon).setContentTitle("RepLock · Every step counts")
            .setContentText("500 tracked steps = 5 coins. Tap to see progress.").setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null, "Stop tracking", stop).build()).build())
        sensors = getSystemService(SENSOR_SERVICE) as SensorManager
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        if (sensor == null || !sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)) { store.stepEnabled = false; stopSelf() }
    }
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "stop" || !store.stepEnabled) { store.stepEnabled = false; store.resetSensorBaseline(); stopSelf() }
        return START_NOT_STICKY
    }
    override fun onSensorChanged(event: SensorEvent) { if (store.stepEnabled) store.sensor(event.values[0].toInt()) }
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onDestroy() { if (::sensors.isInitialized) sensors.unregisterListener(this); instance = null; super.onDestroy() }
}
