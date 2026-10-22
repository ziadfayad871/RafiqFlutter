package com.rafiq.rafiqflutter

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import org.junit.Assert.assertEquals
import org.junit.Test

class PrayerCalculatorTest {

    private val cairo = ZoneId.of("Africa/Cairo")

    @Test
    fun cairoOctober2026MatchesReference() {
        val times = PrayerCalculator.calculate(
            LocalDate.of(2026, 10, 20),
            30.0444,
            31.2357,
            cairo,
            CalculationMethod.EGYPTIAN
        )
        assertEquals(5, times.fajr.hour)
        assertEquals(33, times.fajr.minute)
        assertEquals(7, times.sunrise.hour)
        assertEquals(12, times.dhuhr.hour)
        assertEquals(40, times.dhuhr.minute)
        assertEquals(15, times.asr.hour)
        assertEquals(53, times.asr.minute)
        assertEquals(18, times.maghrib.hour)
        assertEquals(19, times.isha.hour)
    }

    @Test
    fun nextPrayerPicksUpcomingOrTomorrowFajr() {
        val today = PrayerCalculator.calculate(
            LocalDate.of(2026, 10, 20), 30.0444, 31.2357, cairo, CalculationMethod.EGYPTIAN
        )
        val tomorrow = PrayerCalculator.calculate(
            LocalDate.of(2026, 10, 21), 30.0444, 31.2357, cairo, CalculationMethod.EGYPTIAN
        )

        val beforeFajr = PrayerCalculator.nextPrayer(
            today,
            LocalDateTime.of(2026, 10, 20, 4, 0),
            tomorrow
        )
        assertEquals("الفجر", beforeFajr.first)

        val afterIsha = PrayerCalculator.nextPrayer(
            today,
            LocalDateTime.of(2026, 10, 20, 23, 0),
            tomorrow
        )
        assertEquals("الفجر", afterIsha.first)
        assertEquals(tomorrow.fajr, afterIsha.second)
    }

    @Test
    fun timezoneChangesShiftResult() {
        val cairoTimes = PrayerCalculator.calculate(
            LocalDate.of(2026, 10, 20), 30.0444, 31.2357, cairo, CalculationMethod.EGYPTIAN
        )
        val londonTimes = PrayerCalculator.calculate(
            LocalDate.of(2026, 10, 20), 30.0444, 31.2357, ZoneId.of("Europe/London"),
            CalculationMethod.EGYPTIAN
        )
        val diff = java.time.Duration.between(
            cairoTimes.fajr,
            londonTimes.fajr
        ).toMinutes()
        assertEquals(-120L, diff)
    }
}
