package app.replock.replock

import org.junit.Assert.*
import org.junit.Test

class RepPolicyTest {
    @Test fun passesHaveFixedPrices() { assertEquals(10, RepPolicy.cost(5)); assertEquals(20, RepPolicy.cost(10)); assertEquals(30, RepPolicy.cost(15)) }
    @Test(expected = IllegalArgumentException::class) fun invalidPassCannotBePurchased() { RepPolicy.cost(-5) }
    @Test fun stepRewardUsesCompleteBatchesAndDailyCap() {
        assertEquals(0, RepPolicy.stepReward(-500)); assertEquals(0, RepPolicy.stepReward(499))
        assertEquals(5, RepPolicy.stepReward(500)); assertEquals(5, RepPolicy.stepReward(999)); assertEquals(100, RepPolicy.stepReward(50000))
    }
    @Test fun passesExpireAndFailClosedOnReboot() {
        assertEquals(60000L, RepPolicy.remaining(70000, 10000, 8, 8))
        assertEquals(0L, RepPolicy.remaining(70000, 70000, 8, 8))
        assertEquals(0L, RepPolicy.remaining(70000, 10000, 8, 9))
    }
    private fun squat(down: Boolean, confidence: Float = 1f) = mapOf(
        11 to Joint(100f, 40f, confidence), 23 to Joint(if (down) 50f else 100f, 100f, confidence),
        25 to Joint(100f, if (down) 100f else 150f, confidence), 27 to Joint(100f, 200f, confidence))
    private fun frames(counter: RepCounter, pose: Map<Int, Joint>, start: Long, n: Int = 5) { repeat(n) { counter.update(pose, start + it * 50) } }
    @Test fun squatRequiresFullCycleAndCannotFarmHeldPose() {
        val c = RepCounter("squats")
        frames(c, squat(true), 1000); assertEquals(0, c.count)
        frames(c, squat(false), 1400); frames(c, squat(true), 1800); assertEquals(0, c.count)
        frames(c, squat(false), 2200); assertEquals(1, c.count)
        frames(c, squat(false), 2600, 100); assertEquals(1, c.count)
    }
    @Test fun lostOrLowConfidencePoseCannotCompleteRep() {
        val c = RepCounter("squats")
        frames(c, squat(false), 1000); frames(c, squat(true), 1400)
        frames(c, squat(false, .2f), 1800); frames(c, squat(false), 2200); assertEquals(0, c.count)
    }
    @Test fun cameraGapDiscardsPartialRep() {
        val c = RepCounter("squats")
        frames(c, squat(false), 1000); frames(c, squat(true), 1400); frames(c, squat(false), 5000)
        assertEquals(0, c.count)
    }
    @Test fun singleNoisyFrameDoesNotCount() {
        val c = RepCounter("squats")
        frames(c, squat(false), 1000); frames(c, squat(true), 1400, 1); frames(c, squat(false), 1500)
        assertEquals(0, c.count)
    }
    private fun body() = mutableMapOf(11 to Joint(80f,50f),12 to Joint(120f,50f),23 to Joint(85f,150f),24 to Joint(115f,150f),25 to Joint(85f,220f),26 to Joint(115f,220f),27 to Joint(85f,300f),28 to Joint(115f,300f),15 to Joint(65f,180f),16 to Joint(135f,180f))
    @Test fun jumpingJackNeedsArmsAndFeetTogether() {
        val c = RepCounter("jacks"); val rest = body()
        val open = body().apply { put(15,Joint(10f,0f)); put(16,Joint(190f,0f)); put(27,Joint(20f,300f)); put(28,Joint(180f,300f)) }
        frames(c,rest,1000); frames(c,open,1400); frames(c,rest,1800); assertEquals(1,c.count)
        val armsOnly = body().apply { put(15,Joint(10f,0f)); put(16,Joint(190f,0f)) }
        frames(c,armsOnly,2200); frames(c,rest,2600); assertEquals(1,c.count)
    }
    @Test fun marchingRequiresAlternatingKnees() {
        val c = RepCounter("march"); val rest = body()
        val left = body().apply { put(25, Joint(85f,160f)) }; val right = body().apply { put(26,Joint(115f,160f)) }
        frames(c,rest,1000); frames(c,left,1400); frames(c,rest,1800); assertEquals(1,c.count)
        frames(c,left,2200); frames(c,rest,2600); assertEquals(1,c.count)
        frames(c,right,3000); frames(c,rest,3400); assertEquals(2,c.count)
    }
}
