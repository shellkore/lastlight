package app.replock.replock

import kotlin.math.*

data class Exercise(val id: String, val name: String, val target: Int, val reward: Int)
object RepPolicy {
    val exercises = mapOf(
        "squats" to Exercise("squats", "Squat & unlock", 10, 20),
        "jacks" to Exercise("jacks", "Jump into it", 15, 30),
        "march" to Exercise("march", "Find your stride", 20, 20)
    )
    fun cost(minutes: Int): Int { require(minutes in listOf(5, 10, 15)) { "Choose a 5, 10, or 15 minute pass." }; return minutes * 2 }
    fun stepReward(steps: Int) = (steps.coerceAtLeast(0) / 500 * 5).coerceAtMost(100)
    fun remaining(deadline: Long, elapsed: Long, savedBoot: Int, boot: Int): Long =
        if (savedBoot != boot) 0 else (deadline - elapsed).coerceIn(0, 900_000)
}

data class Joint(val x: Float, val y: Float, val confidence: Float = 1f)

/** Hysteresis + stable frames + complete cycles; a held pose cannot earn repeated reps. */
class RepCounter(private val exercise: String) {
    var count = 0; private set
    var hint = "Step back. Keep your full body in frame."; private set
    private var ready = false
    private var extended = false
    private var stable = 0
    private var lastPhase = 0
    private var lastRepAt = 0L
    private var lastSeenAt = 0L
    private var raisedSide = 0
    private var previousSide = 0
    fun lost() { ready = false; extended = false; stable = 0; lastPhase = 0; raisedSide = 0; hint = "Full body in frame. Find good lighting." }
    private fun angle(a: Joint, b: Joint, c: Joint): Double {
        val ux = (a.x - b.x).toDouble(); val uy = (a.y - b.y).toDouble()
        val vx = (c.x - b.x).toDouble(); val vy = (c.y - b.y).toDouble()
        val norm = hypot(ux, uy) * hypot(vx, vy)
        return if (norm < 1) 180.0 else acos(((ux * vx + uy * vy) / norm).coerceIn(-1.0, 1.0)) * 180 / PI
    }
    // Indices follow ML Kit PoseLandmark constants.
    fun update(p: Map<Int, Joint>, now: Long): Int {
        if (lastSeenAt > 0 && now - lastSeenAt > 900) lost()
        lastSeenAt = now
        val required = when (exercise) { "jacks" -> listOf(11,12,15,16,23,24,25,26,27,28); "squats" -> emptyList(); else -> listOf(11,12,23,24,25,26,27,28) }
        if (required.any { (p[it]?.confidence ?: 0f) < .65f }) { lost(); return count }
        var side = 0
        val phase: Int
        if (exercise == "squats") {
            val l = listOf(11,23,25,27); val r = listOf(12,24,26,28)
            val use = if (l.minOf { p[it]?.confidence ?: 0f } >= r.minOf { p[it]?.confidence ?: 0f }) l else r
            if (use.any { (p[it]?.confidence ?: 0f) < .7f }) { lost(); return count }
            val knee = angle(p.getValue(use[1]), p.getValue(use[2]), p.getValue(use[3]))
            phase = if (knee > 158) 1 else if (knee < 110) 2 else 0
            hint = if (extended) "Stand tall to finish the rep." else "Lower comfortably. Keep feet planted."
        } else {
            val lh = p.getValue(23); val rh = p.getValue(24)
            val ls = p.getValue(11); val rs = p.getValue(12)
            val torso = abs((lh.y + rh.y - ls.y - rs.y) / 2).coerceAtLeast(20f)
            if (exercise == "jacks") {
                val feet = abs(p.getValue(27).x - p.getValue(28).x)
                val width = abs(ls.x - rs.x).coerceAtLeast(torso * .5f)
                val armsUp = p.getValue(15).y < ls.y - torso * .3f && p.getValue(16).y < rs.y - torso * .3f
                val armsDown = p.getValue(15).y > ls.y + torso * .5f && p.getValue(16).y > rs.y + torso * .5f
                phase = if (armsUp && feet > width * 1.5) 2 else if (armsDown && feet < width * 1.2) 1 else 0
                hint = if (extended) "Feet together. Arms down." else "Open feet. Both arms overhead."
            } else {
                val leftUp = p.getValue(25).y < lh.y + torso * .38f
                val rightUp = p.getValue(26).y < rh.y + torso * .38f
                side = if (leftUp && !rightUp) 1 else if (rightUp && !leftUp) 2 else 0
                phase = if (side != 0 && side != previousSide) 2 else if (!leftUp && !rightUp) 1 else 0
                hint = if (extended) "Lower your foot with control." else "Lift the ${if (previousSide == 1) "right" else if (previousSide == 2) "left" else "first"} knee toward hip height."
            }
        }
        if (phase == 0) { stable = 0; lastPhase = 0; return count }
        stable = if (phase == lastPhase) stable + 1 else 1
        lastPhase = phase
        if (stable < 3) return count
        if (phase == 1 && !ready) { ready = true; hint = "Ready. Let's move!" }
        if (phase == 2 && ready) { extended = true; if (side != 0) raisedSide = side }
        if (phase == 1 && ready && extended) {
            if (now - lastRepAt >= 650) { count++; lastRepAt = now; previousSide = raisedSide }
            extended = false
        }
        return count
    }
}
