package app.lastlight.lastlight

import java.time.Instant
import java.time.ZoneId
import org.junit.Assert.*
import org.junit.Test

class NightPolicyTest {
    private val zone = ZoneId.of("Asia/Kolkata")
    private fun time(value: String) = Instant.parse(value).toEpochMilli()
    @Test fun overnightWindowKeepsOneNightIdentityAcrossMidnight() {
        val before = NightPolicy.window(time("2026-10-23T18:00:00Z"), 1320, 420, zone)
        val after = NightPolicy.window(time("2026-10-23T20:00:00Z"), 1320, 420, zone)
        assertTrue(before.inside); assertTrue(after.inside)
        assertEquals(before.id, after.id)
        assertEquals(time("2026-10-24T01:30:00Z"), after.endAt)
    }
    @Test fun wakeTimeIsExclusiveAndNextSessionDoesNotEndInPast() {
        val now = time("2026-10-24T01:30:00Z")
        assertFalse(NightPolicy.window(now, 1320, 420, zone).inside)
        assertEquals(time("2026-10-25T01:30:00Z"), NightPolicy.nextMorning(now, 420, zone))
    }
    @Test fun daytimeWindowIsSupported() {
        assertTrue(NightPolicy.window(time("2026-10-23T06:00:00Z"), 600, 840, zone).inside)
        assertFalse(NightPolicy.window(time("2026-10-23T16:00:00Z"), 600, 840, zone).inside)
    }
    @Test fun overnightWindowUsesLocalCalendarThroughDaylightSaving() {
        val window = NightPolicy.window(time("2026-11-01T03:00:00Z"), 1320, 420, ZoneId.of("America/New_York"))
        assertTrue(window.inside)
        assertEquals(time("2026-11-01T12:00:00Z"), window.endAt)
    }
}
