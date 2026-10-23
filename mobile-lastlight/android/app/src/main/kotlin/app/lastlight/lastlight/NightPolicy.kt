package app.lastlight.lastlight

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

data class NightWindow(val id: String, val endAt: Long, val inside: Boolean)

object NightPolicy {
    fun window(now: Long, start: Int, end: Int, zone: ZoneId = ZoneId.systemDefault()): NightWindow {
        val time = Instant.ofEpochMilli(now).atZone(zone)
        val minute = time.hour * 60 + time.minute
        val crossesMidnight = start > end
        val inside = if (crossesMidnight) minute >= start || minute < end else minute >= start && minute < end
        val date = if (crossesMidnight && minute < end) time.toLocalDate().minusDays(1) else time.toLocalDate()
        val endDate = if (crossesMidnight) date.plusDays(1) else date
        return NightWindow(date.toString(), at(endDate, end, zone), inside)
    }

    fun nextMorning(now: Long, end: Int, zone: ZoneId = ZoneId.systemDefault()): Long {
        val date = Instant.ofEpochMilli(now).atZone(zone).toLocalDate()
        val today = at(date, end, zone)
        return if (today > now) today else at(date.plusDays(1), end, zone)
    }

    private fun at(date: LocalDate, minute: Int, zone: ZoneId) =
        date.atTime(minute / 60, minute % 60).atZone(zone).toInstant().toEpochMilli()
}
