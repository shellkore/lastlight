package app.lastlight.lastlight

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class LastlightAccessibilityService : AccessibilityService() {
    companion object { var instance: LastlightAccessibilityService? = null; private set }
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var store: NightStore
    private var foreground = ""
    private var overlay: View? = null
    private var lastTick = 0L
    private var lastWall = 0L
    private var wasScreenOff = false
    private var verifiedForeground = false
    private val ticker = object : Runnable {
        override fun run() { checkNow(); handler.postDelayed(this, 1000) }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        store = NightStore(this)
        // Do not reward time during which this service was absent.
        if (store.active && !store.pending) store.quietMs = 0
        lastTick = SystemClock.elapsedRealtime()
        lastWall = System.currentTimeMillis()
        handler.post(ticker)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || !::store.isInitialized) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName && overlay != null && !event.className.toString().endsWith("MainActivity")) return
        if (pkg == "com.android.systemui") return
        // An input-method window is not a switch away from the underlying app.
        val inputMethods = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        if (inputMethods.enabledInputMethodList.any { it.packageName == pkg }) return
        // Account for the previous app before switching the foreground identity.
        checkNow()
        foreground = pkg
        verifiedForeground = true
        updateShield()
    }

    fun checkNow() {
        if (!::store.isInitialized) return
        val elapsed = SystemClock.elapsedRealtime()
        val power = getSystemService(POWER_SERVICE) as PowerManager
        val screenOff = !power.isInteractive
        val rawDelta = (elapsed - lastTick).coerceAtLeast(0)
        // Large gaps while the display was on are unverified; never award them.
        val delta = if (wasScreenOff) rawDelta else rawDelta.coerceAtMost(3000)
        lastTick = elapsed
        val now = System.currentTimeMillis()
        val window = NightPolicy.window(now, store.startMinute, store.endMinute)
        // If the screen slept across the morning boundary, credit only the
        // observed screen-off portion before that boundary, never service downtime.
        if (!store.active && store.endAt > lastWall && wasScreenOff && verifiedForeground) {
            val beforeMorning = (store.endAt - lastWall).coerceIn(0, rawDelta)
            store.quietMs = (store.quietMs + beforeMorning).coerceAtMost(900_000)
            if (store.quietMs >= 900_000) store.earn()
        }
        if (store.active) {
            // An overlay prevents feed interaction; screen-off is also an observed quiet state.
            if (verifiedForeground && (screenOff || wasScreenOff || foreground !in store.packages || overlay != null)) {
                store.quietMs = (store.quietMs + delta).coerceAtMost(900_000)
                if (store.quietMs >= 900_000) store.earn()
            }
        } else if (store.automatic && window.inside && window.id != store.bypassNight) {
            if (store.counterNight != window.id) store.resetCounter(window.id)
            if (!screenOff && !wasScreenOff && verifiedForeground && foreground in store.packages) {
                store.usedMs += rawDelta.coerceAtMost(3000)
                if (store.usedMs >= store.allowance * 60_000L) store.start(now)
            }
        }
        wasScreenOff = screenOff
        lastWall = now
        updateShield()
    }

    private fun updateShield() {
        val shouldBlock = store.active && foreground in store.packages
        if (!shouldBlock) { hideShield(); return }
        if (overlay != null) return
        store.interrupted()
        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()
        val panel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(32), dp(40), dp(32), dp(40))
            setBackgroundColor(Color.rgb(19, 39, 49))
        }
        fun text(content: String, size: Float, color: Int) = TextView(this).apply {
            this.text = content; textSize = size; setTextColor(color); gravity = Gravity.CENTER
            setPadding(0, dp(12), 0, dp(12))
        }
        val cream = Color.rgb(245, 240, 228)
        val mint = Color.rgb(172, 201, 183)
        panel.addView(text("✦  LASTLIGHT", 14f, mint))
        panel.addView(text("Let the coast\nkeep you tonight.", 30f, cream))
        panel.addView(text("This app is inside your quiet boundary.\nIt becomes available at ${"%02d:%02d".format(store.endMinute / 60, store.endMinute % 60)}.\n\nYour calls and other unselected apps still work.", 15f, mint))
        panel.addView(Button(this).apply {
            this.text = "Return to Lastlight"
            setOnClickListener {
                startActivity(Intent(this@LastlightAccessibilityService, MainActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP))
            }
        }, LinearLayout.LayoutParams(-1, dp(54)))
        panel.addView(Button(this).apply {
            this.text = "Put my phone down"
            setOnClickListener { performGlobalAction(GLOBAL_ACTION_HOME); this@LastlightAccessibilityService.foreground = ""; hideShield() }
        }, LinearLayout.LayoutParams(-1, dp(54)))
        panel.addView(text("Need access? Open Lastlight and intentionally end protection.\nYou stay in control.", 12f, mint))
        val params = WindowManager.LayoutParams(-1, -1, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN, android.graphics.PixelFormat.OPAQUE)
        try {
            (getSystemService(WINDOW_SERVICE) as WindowManager).addView(panel, params)
            overlay = panel
        } catch (_: RuntimeException) {
            // Do not leave selected content accessible if a device rejects the overlay.
            performGlobalAction(GLOBAL_ACTION_HOME)
        }
    }

    private fun hideShield() {
        overlay?.let { try { (getSystemService(WINDOW_SERVICE) as WindowManager).removeView(it) } catch (_: RuntimeException) {} }
        overlay = null
    }

    override fun onInterrupt() { hideShield(); verifiedForeground = false; if (::store.isInitialized && !store.pending) store.quietMs = 0 }
    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        hideShield()
        if (::store.isInitialized && store.active && !store.pending) store.quietMs = 0
        instance = null
        super.onDestroy()
    }
}
