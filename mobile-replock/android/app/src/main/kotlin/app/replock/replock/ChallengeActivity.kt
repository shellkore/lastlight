package app.replock.replock

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Bundle
import android.os.SystemClock
import android.view.Gravity
import android.view.WindowManager
import android.widget.*
import androidx.activity.ComponentActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions

class ChallengeActivity : ComponentActivity() {
    private val detector = PoseDetection.getClient(PoseDetectorOptions.Builder().setDetectorMode(PoseDetectorOptions.STREAM_MODE).build())
    private lateinit var preview: PreviewView
    private lateinit var progress: TextView
    private lateinit var cue: TextView
    private lateinit var exercise: Exercise
    private lateinit var counter: RepCounter
    private var provider: ProcessCameraProvider? = null
    private var completed = false
    private var processing = false
    private var isActive = false
    private var startedAt = 0L
    private var errors = 0
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        exercise = RepPolicy.exercises[intent.getStringExtra("exercise")] ?: run { finish(); return }
        counter = RepCounter(exercise.id)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val frame = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        preview = PreviewView(this).apply { implementationMode = PreviewView.ImplementationMode.COMPATIBLE; scaleType = PreviewView.ScaleType.FIT_CENTER }
        frame.addView(preview, FrameLayout.LayoutParams(-1, -1))
        val top = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER; setPadding(24, 46, 24, 20); setBackgroundColor(0xDD111510.toInt()) }
        fun label(text: String, size: Float) = TextView(this).apply { this.text = text; textSize = size; gravity = Gravity.CENTER; setTextColor(Color.WHITE); setPadding(0, 6, 0, 6) }
        top.addView(label("REPLOCK  /  ${exercise.name.uppercase()}", 16f))
        progress = label("0 / ${exercise.target}", 44f).apply { setTextColor(Color.rgb(211,255,77)) }
        top.addView(progress)
        top.addView(label("+${exercise.reward} COINS · ON-DEVICE VERIFICATION", 12f))
        frame.addView(top, FrameLayout.LayoutParams(-1, -2, Gravity.TOP))
        val bottom = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER; setPadding(24, 18, 24, 32); setBackgroundColor(0xEE111510.toInt()) }
        cue = label("Set your phone down. Full body in frame.\n${if (exercise.id == "squats") "Turn sideways to the camera." else "Face the camera."}", 17f)
        bottom.addView(cue)
        bottom.addView(label("Live frames are processed here. No video is saved.", 12f))
        bottom.addView(Button(this).apply { text = "Stop challenge"; setOnClickListener { finish() } })
        frame.addView(bottom, FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM)); setContentView(frame)
        startedAt = SystemClock.elapsedRealtime()
        if (checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) startCamera() else requestPermissions(arrayOf(Manifest.permission.CAMERA), 8)
    }
    private fun startCamera() {
        val future = ProcessCameraProvider.getInstance(this)
        future.addListener({
            if (isFinishing || isDestroyed) return@addListener
            try {
                provider = future.get()
                val selector = if (provider!!.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
                val view = Preview.Builder().build().also { it.surfaceProvider = preview.surfaceProvider }
                val analysis = ImageAnalysis.Builder().setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST).build()
                analysis.setAnalyzer(ContextCompat.getMainExecutor(this)) { image -> analyze(image) }
                provider!!.unbindAll(); provider!!.bindToLifecycle(this, selector, view, analysis)
            } catch (_: Exception) { cue.text = "Camera unavailable. Close other camera apps and try again. No coins were awarded." }
        }, ContextCompat.getMainExecutor(this))
    }
    @androidx.camera.core.ExperimentalGetImage
    private fun analyze(proxy: ImageProxy) {
        val raw = proxy.image
        if (raw == null || processing || completed || !isActive) { proxy.close(); return }
        if (SystemClock.elapsedRealtime() - startedAt > 600_000) { proxy.close(); cue.text = "Challenge timed out. Rest, then start a new attempt."; provider?.unbindAll(); return }
        processing = true
        detector.process(InputImage.fromMediaImage(raw, proxy.imageInfo.rotationDegrees))
            .addOnSuccessListener { pose ->
                if (!isActive || isFinishing || completed) return@addOnSuccessListener
                errors = 0
                val joints = pose.allPoseLandmarks.associate { it.landmarkType to Joint(it.position.x, it.position.y, it.inFrameLikelihood) }
                val reps = counter.update(joints, SystemClock.elapsedRealtime())
                progress.text = "$reps / ${exercise.target}"; cue.text = counter.hint
                if (reps >= exercise.target) {
                    completed = true
                    try {
                        val coins = RepStore(this).complete(exercise.id)
                        setResult(RESULT_OK, Intent().putExtra("coins", coins)); finish()
                    } catch (e: Exception) { cue.text = e.message; provider?.unbindAll() }
                }
            }
            .addOnFailureListener { counter.lost(); errors++; cue.text = if (errors > 15) "Pose detection is unavailable. Stop and try again." else "Finding your movement. Try better lighting." }
            .addOnCompleteListener { processing = false; proxy.close() }
    }
    override fun onResume() { super.onResume(); isActive = true; if (::counter.isInitialized) counter.lost() }
    override fun onPause() { isActive = false; super.onPause() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 8 && grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) startCamera()
        else cue.text = "Camera permission was declined. No coins were awarded. You can earn with steps instead."
    }
    override fun onDestroy() { provider?.unbindAll(); detector.close(); super.onDestroy() }
}
