package app.lastlight.lastlight

import android.content.Context
import org.json.JSONArray

class NightStore(context: Context) {
    private val prefs = context.getSharedPreferences("lastlight_nights", Context.MODE_PRIVATE)
    val startMinute get() = prefs.getInt("startMinute", 1320)
    val endMinute get() = prefs.getInt("endMinute", 420)
    val allowance get() = prefs.getInt("allowance", 20)
    val automatic get() = prefs.getBoolean("automatic", false)
    val packages: Set<String> get() {
        val array = JSONArray(prefs.getString("packages", "[]") ?: "[]")
        return (0 until array.length()).map { array.getString(it) }.toSet()
    }
    var endAt: Long
        get() = prefs.getLong("endAt", 0)
        set(value) { prefs.edit().putLong("endAt", value).apply() }
    var quietMs: Long
        get() = prefs.getLong("quietMs", 0)
        set(value) { prefs.edit().putLong("quietMs", value).apply() }
    var pending: Boolean
        get() = prefs.getBoolean("pending", false)
        set(value) { prefs.edit().putBoolean("pending", value).apply() }
    val chapters get() = prefs.getInt("chapters", 0)
    val revealAt get() = prefs.getLong("revealAt", 0)
    val active get() = endAt > System.currentTimeMillis()
    val bypassNight get() = prefs.getString("bypassNight", "") ?: ""
    val earnedNight get() = prefs.getString("earnedNight", "") ?: ""
    var usedMs: Long
        get() = prefs.getLong("usedMs", 0)
        set(value) { prefs.edit().putLong("usedMs", value).apply() }
    val counterNight get() = prefs.getString("counterNight", "") ?: ""
    val sessionNight get() = prefs.getString("sessionNight", "") ?: ""

    fun save(settings: Map<*, *>) {
        require(!active) { "End protection intentionally before editing your boundary." }
        val start = (settings["startMinute"] as? Number)?.toInt() ?: startMinute
        val end = (settings["endMinute"] as? Number)?.toInt() ?: endMinute
        val allowanceValue = (settings["allowance"] as? Number)?.toInt() ?: allowance
        require(start in 0..1439 && end in 0..1439 && start != end) { "Choose different evening and morning times." }
        require(allowanceValue in 5..60) { "Choose an allowance between 5 and 60 minutes." }
        val edit = prefs.edit().putInt("startMinute", start).putInt("endMinute", end).putInt("allowance", allowanceValue)
        (settings["automatic"] as? Boolean)?.let { edit.putBoolean("automatic", it) }
        (settings["packages"] as? List<*>)?.let { list ->
            edit.putString("packages", JSONArray(list.filterIsInstance<String>()).toString())
        }
        edit.apply()
    }

    fun start(now: Long = System.currentTimeMillis()) {
        require(packages.isNotEmpty()) { "Choose at least one distracting app first." }
        require(!active) { "Protection is already running." }
        val window = NightPolicy.window(now, startMinute, endMinute)
        require(window.id != bypassNight) { "Tonight was intentionally bypassed. Your next scheduled night is a fresh start." }
        // Starting another session never replaces an unclaimed postcard.
        prefs.edit().putLong("endAt", NightPolicy.nextMorning(now, endMinute))
            .putLong("quietMs", 0).putString("sessionNight", window.id).apply()
    }

    fun resetCounter(id: String) {
        prefs.edit().putString("counterNight", id).putLong("usedMs", 0).apply()
    }

    fun earn() {
        if (pending || sessionNight == earnedNight || chapters >= 7) return
        prefs.edit().putBoolean("pending", true).putLong("revealAt", endAt)
            .putString("earnedNight", sessionNight).apply()
    }

    fun bypass() {
        // A confirmation left open past morning must not revoke an earned chapter.
        if (!active) return
        val id = sessionNight.ifBlank { NightPolicy.window(System.currentTimeMillis(), startMinute, endMinute).id }
        val edit = prefs.edit().putLong("endAt", 0).putLong("quietMs", 0)
            .putString("bypassNight", id).putInt("bypasses", prefs.getInt("bypasses", 0) + 1)
        // A postcard from a prior night is not revoked by a later night's bypass.
        if (pending && earnedNight == id) edit.putBoolean("pending", false)
        edit.apply()
    }

    fun claim() {
        require(pending && System.currentTimeMillis() >= revealAt) { "Your postcard opens in the morning." }
        prefs.edit().putBoolean("pending", false).putInt("chapters", (chapters + 1).coerceAtMost(7)).apply()
    }

    fun interrupted() {
        prefs.edit().putInt("blockedAttempts", prefs.getInt("blockedAttempts", 0) + 1).apply()
    }

    fun state(connected: Boolean): Map<String, Any> = mapOf(
        "supported" to true, "connected" to connected, "active" to active,
        "pending" to pending, "canClaim" to (pending && System.currentTimeMillis() >= revealAt),
        "startMinute" to startMinute, "endMinute" to endMinute, "allowance" to allowance,
        "automatic" to automatic, "packages" to packages.toList(), "quietSeconds" to quietMs / 1000,
        "chapters" to chapters, "endAt" to endAt, "revealAt" to revealAt,
        "bypasses" to prefs.getInt("bypasses", 0), "blockedAttempts" to prefs.getInt("blockedAttempts", 0)
    )
}
