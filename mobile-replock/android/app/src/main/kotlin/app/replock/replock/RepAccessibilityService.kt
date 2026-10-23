package app.replock.replock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class RepAccessibilityService : AccessibilityService() {
    companion object { var instance: RepAccessibilityService? = null; private set }
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var store: RepStore
    private var foreground = ""
    private var overlay: View? = null
    private val ticker = object : Runnable { override fun run() { checkNow(); handler.postDelayed(this, 500) } }
    override fun onServiceConnected() { super.onServiceConnected(); instance = this; store = RepStore(this); handler.post(ticker) }
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || !::store.isInitialized) return
        val pkg = event.packageName?.toString() ?: return
        if (pkg == packageName && overlay != null && !event.className.toString().endsWith("MainActivity")) return
        if (pkg == "com.android.systemui") return
        if ((getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager).enabledInputMethodList.any { it.packageName == pkg }) return
        foreground = pkg; checkNow()
    }
    fun checkNow() {
        if (!::store.isInitialized) return
        if (!store.blocked(foreground)) { hide(); return }
        if (overlay != null) return
        val density = resources.displayMetrics.density
        fun dp(n: Int) = (density * n).toInt()
        val panel = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER; setPadding(dp(28), dp(32), dp(28), dp(32)); setBackgroundColor(Color.rgb(17, 21, 16)) }
        fun label(value: String, size: Float, color: Int) = TextView(this).apply { text = value; textSize = size; setTextColor(color); gravity = Gravity.CENTER; setPadding(0, dp(12), 0, dp(12)) }
        val lime = Color.rgb(211,255,77)
        panel.addView(label("↗  REPLOCK", 18f, lime))
        panel.addView(label("MOVE FIRST.\nSCROLL LATER.", 36f, Color.WHITE))
        panel.addView(label("This feed is on a break.\nPick a challenge, earn coins,\nand trade them for a little scroll time.", 17f, Color.LTGRAY))
        panel.addView(label("${store.balance} COINS IN YOUR WALLET", 15f, lime))
        panel.addView(Button(this).apply { text = "LET'S EARN IT  ↗"; setBackgroundColor(lime); setTextColor(Color.BLACK); setOnClickListener { hide(); this@RepAccessibilityService.foreground = ""; startActivity(Intent(this@RepAccessibilityService, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)) } }, LinearLayout.LayoutParams(-1, dp(60)))
        panel.addView(Button(this).apply { text = "Head back home"; setOnClickListener { performGlobalAction(GLOBAL_ACTION_HOME); this@RepAccessibilityService.foreground = ""; hide() } }, LinearLayout.LayoutParams(-1, dp(60)))
        panel.addView(label("You're in charge. Pause protection in RepLock any time.", 13f, Color.LTGRAY))
        try {
            (getSystemService(WINDOW_SERVICE) as WindowManager).addView(panel, WindowManager.LayoutParams(-1, -1, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN, PixelFormat.OPAQUE))
            overlay = panel
        } catch (_: RuntimeException) { performGlobalAction(GLOBAL_ACTION_HOME) }
    }
    private fun hide() { overlay?.let { try { (getSystemService(WINDOW_SERVICE) as WindowManager).removeView(it) } catch (_: RuntimeException) {} }; overlay = null }
    override fun onInterrupt() { hide() }
    override fun onDestroy() { handler.removeCallbacksAndMessages(null); hide(); instance = null; super.onDestroy() }
}
