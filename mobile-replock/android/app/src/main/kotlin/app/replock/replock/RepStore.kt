package app.replock.replock

import android.content.Context
import android.os.SystemClock
import android.provider.Settings
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate

class RepStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("replock.v1", Context.MODE_PRIVATE)
    companion object { private val lock = Any() }
    private val boot get() = Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, -1)
    var protection: Boolean
        get() = prefs.getBoolean("protection", false)
        set(v) { prefs.edit().putBoolean("protection", v).commit() }
    var selected: Set<String>
        get() = prefs.getStringSet("selected", emptySet())!!.toSet()
        set(v) { synchronized(lock) { prefs.edit().putStringSet("selected", v).commit() } }
    var stepEnabled: Boolean
        get() = prefs.getBoolean("stepEnabled", false)
        set(v) { prefs.edit().putBoolean("stepEnabled", v).commit() }
    val balance get() = prefs.getInt("balance", 0)
    val activeApp get() = if (remainingMs > 0) prefs.getString("activeApp", "")!! else ""
    val remainingMs get() = RepPolicy.remaining(prefs.getLong("deadline", 0), SystemClock.elapsedRealtime(), prefs.getInt("boot", -2), boot)
    fun onboard() { prefs.edit().putBoolean("onboarded", true).commit() }
    private fun daily() {
        val today = LocalDate.now().toString()
        if (today > prefs.getString("day", "")!!) {
            prefs.edit().putString("day", today).putInt("earnedToday", 0).putInt("steps", 0).putInt("stepCoins", 0).commit()
        }
    }
    private fun ledger(title: String, coins: Int): String {
        val old = JSONArray(prefs.getString("history", "[]"))
        val entries = JSONArray().put(JSONObject().put("title", title).put("coins", coins).put("timestamp", System.currentTimeMillis()))
        for (i in 0 until minOf(old.length(), 99)) entries.put(old.get(i))
        return entries.toString()
    }
    fun canExercise(id: String) = synchronized(lock) {
        daily()
        val exercise = requireNotNull(RepPolicy.exercises[id]) { "Unknown challenge." }
        require(prefs.getInt("earnedToday", 0) + exercise.reward <= 200) { "Today's 200 workout coins are earned. Take a breather and come back tomorrow." }
        val last = prefs.getLong("lastWorkout", 0)
        require(last == 0L || (prefs.getInt("lastWorkoutBoot", -2) == boot && SystemClock.elapsedRealtime() - last >= 45_000) || prefs.getInt("lastWorkoutBoot", -2) != boot) { "Take 45 seconds between challenges. You've earned a breather." }
        exercise
    }
    // Called only by the non-exported native camera activity after verified reps.
    fun complete(id: String): Int = synchronized(lock) {
        val exercise = canExercise(id)
        prefs.edit().putInt("balance", balance + exercise.reward)
            .putInt("totalEarned", prefs.getInt("totalEarned", 0) + exercise.reward)
            .putInt("earnedToday", prefs.getInt("earnedToday", 0) + exercise.reward)
            .putInt("workouts", prefs.getInt("workouts", 0) + 1)
            .putLong("lastWorkout", SystemClock.elapsedRealtime()).putInt("lastWorkoutBoot", boot)
            .putString("history", ledger(exercise.name, exercise.reward)).commit()
        exercise.reward
    }
    fun redeem(id: String, name: String, minutes: Int) = synchronized(lock) {
        val cost = RepPolicy.cost(minutes)
        require(protection && RepAccessibilityService.instance != null) { "Turn on app protection first." }
        require(id in selected) { "Select this app in your protected apps first." }
        require(remainingMs == 0L) { "Finish your current pass before opening another." }
        require(balance >= cost) { "You need $cost coins. Pick a challenge to earn them." }
        prefs.edit().putInt("balance", balance - cost).putString("activeApp", id)
            .putLong("deadline", SystemClock.elapsedRealtime() + minutes * 60_000L).putInt("boot", boot)
            .putString("history", ledger("$minutes min · $name", -cost)).commit()
    }
    fun endPass() { prefs.edit().remove("deadline").remove("activeApp").commit() }
    fun blocked(id: String) = protection && id in selected && !(remainingMs > 0 && activeApp == id)
    fun sensor(value: Int, now: Long = SystemClock.elapsedRealtime()) = synchronized(lock) {
        daily()
        val previous = prefs.getInt("sensorValue", -1)
        val sameBoot = prefs.getInt("sensorBoot", -2) == boot
        val lastAt = prefs.getLong("sensorAt", now)
        val lastDay = prefs.getString("sensorDay", "")
        val today = LocalDate.now().toString()
        // Never back-credit time before permission or across an unobserved midnight.
        val delta = if (previous >= 0 && sameBoot && lastDay == today && value >= previous) (value - previous).coerceAtMost(((now - lastAt).coerceAtLeast(0) / 1000 * 5 + 10).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()) else 0
        val steps = prefs.getInt("steps", 0) + delta
        prefs.edit().putInt("steps", steps).putInt("sensorValue", value).putInt("sensorBoot", boot)
            .putLong("sensorAt", now).putString("sensorDay", today).commit()
    }
    fun resetSensorBaseline() { prefs.edit().remove("sensorValue").commit() }
    fun claimSteps(): Int = synchronized(lock) {
        daily()
        val earned = RepPolicy.stepReward(prefs.getInt("steps", 0))
        val amount = earned - prefs.getInt("stepCoins", 0)
        require(amount > 0) { "Every 500 tracked steps earns 5 coins. Keep moving!" }
        prefs.edit().putInt("stepCoins", earned).putInt("balance", balance + amount)
            .putInt("totalEarned", prefs.getInt("totalEarned", 0) + amount)
            .putString("history", ledger("Step rewards", amount)).commit()
        amount
    }
    fun state(access: Boolean, sensorAvailable: Boolean): Map<String, Any> = synchronized(lock) {
        daily()
        val entries = JSONArray(prefs.getString("history", "[]"))
        mapOf("onboarded" to prefs.getBoolean("onboarded", false), "protection" to protection,
            "accessEnabled" to access, "stepEnabled" to (stepEnabled && StepService.instance != null), "stepAvailable" to sensorAvailable,
            "balance" to balance, "earnedToday" to prefs.getInt("earnedToday", 0), "steps" to prefs.getInt("steps", 0),
            "stepCoins" to prefs.getInt("stepCoins", 0), "workouts" to prefs.getInt("workouts", 0),
            "totalEarned" to prefs.getInt("totalEarned", 0), "selected" to selected.toList(), "activeApp" to activeApp,
            "remainingSeconds" to ((remainingMs + 999) / 1000).toInt(), "platform" to "Android",
            "history" to (0 until entries.length()).map { val e = entries.getJSONObject(it); mapOf("title" to e.getString("title"), "coins" to e.getInt("coins"), "timestamp" to e.getLong("timestamp")) })
    }
    fun reset() = synchronized(lock) { prefs.edit().clear().commit() }
}
