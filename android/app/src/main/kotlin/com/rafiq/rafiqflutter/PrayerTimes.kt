package com.rafiq.rafiqflutter

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import kotlin.math.abs
import kotlin.math.acos
import kotlin.math.asin
import kotlin.math.atan
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.roundToLong
import kotlin.math.sin
import kotlin.math.tan

enum class CalculationMethod(
    val id: String,
    val fajrAngle: Double,
    val ishaAngle: Double?,
    val ishaIntervalMinutes: Int? = null
) {
    EGYPTIAN("egyptian", 19.5, 17.5),
    UMM_AL_QURA("umm_al_qura", 18.5, null, 90),
    MWL("mwl", 18.0, 17.0),
    KARACHI("karachi", 18.0, 18.0),
    ISNA("isna", 15.0, 15.0),
    DUBAI("dubai", 18.2, 18.2),
    KUWAIT("kuwait", 18.0, 17.5),
    QATAR("qatar", 18.0, null, 90),
    SINGAPORE("singapore", 20.0, 18.0),
    TURKEY("turkey", 18.0, 18.0),
    MOROCCO("morocco", 19.0, 17.0);

    companion object {
        fun fromId(id: String?): CalculationMethod =
            entries.firstOrNull { it.id == id } ?: EGYPTIAN
    }
}

data class PrayerTimes(
    val date: LocalDate,
    val fajr: LocalDateTime,
    val sunrise: LocalDateTime,
    val dhuhr: LocalDateTime,
    val asr: LocalDateTime,
    val maghrib: LocalDateTime,
    val isha: LocalDateTime
) {
    val prayers: List<Pair<String, LocalDateTime>> = listOf(
        "الفجر" to fajr,
        "الظهر" to dhuhr,
        "العصر" to asr,
        "المغرب" to maghrib,
        "العشاء" to isha
    )
}

object PrayerCalculator {

    private const val SUNRISE_ANGLE = 0.833

    fun calculate(
        date: LocalDate,
        latitude: Double,
        longitude: Double,
        zoneId: ZoneId,
        method: CalculationMethod
    ): PrayerTimes {
        val lat = latitude.coerceIn(-89.5, 89.5)
        val lng = longitude.coerceIn(-180.0, 180.0)
        val jd = julianDate(date)
        val tzOffset = zoneId.rules.getOffset(date.atTime(12, 0)).totalSeconds / 3600.0
        val adjust = tzOffset - lng / 15.0

        val dhuhrSolar = midDay(jd)
        val sunriseSolar = sunAngleTime(jd, lat, SUNRISE_ANGLE, 0.5, true)
        val sunsetSolar = sunAngleTime(jd, lat, SUNRISE_ANGLE, 0.5, false)
        var fajrSolar = sunAngleTime(jd, lat, method.fajrAngle, 0.5, true)
        var ishaSolar = method.ishaAngle?.let {
            sunAngleTime(jd, lat, it, 0.5, false)
        } ?: (sunsetSolar + (method.ishaIntervalMinutes ?: 90) / 60.0)
        val asrSolar = asrTime(jd, lat, 0.5, 1)

        val nightLength = fixHour(sunriseSolar - sunsetSolar + 24.0)
        if (fajrSolar.isNaN()) {
            fajrSolar = sunriseSolar - nightLength / 2.0
        }
        if (ishaSolar.isNaN()) {
            ishaSolar = sunsetSolar + nightLength / 2.0
        }

        return PrayerTimes(
            date = date,
            fajr = toLocal(date, fajrSolar + adjust),
            sunrise = toLocal(date, sunriseSolar + adjust),
            dhuhr = toLocal(date, dhuhrSolar + adjust),
            asr = toLocal(date, asrSolar + adjust),
            maghrib = toLocal(date, sunsetSolar + adjust),
            isha = toLocal(date, ishaSolar + adjust)
        )
    }

    fun nextPrayer(
        today: PrayerTimes,
        now: LocalDateTime,
        tomorrow: PrayerTimes
    ): Pair<String, LocalDateTime> {
        val next = today.prayers.firstOrNull { it.second.isAfter(now) }
        return next ?: tomorrow.prayers.first()
    }

    fun formatTime(time: LocalDateTime): String =
        "%02d:%02d".format(time.hour, time.minute)

    private fun toLocal(date: LocalDate, solarTime: Double): LocalDateTime {
        val normalized = fixHour(solarTime)
        val totalMinutes = (normalized * 60.0).roundToLong()
        return date.atStartOfDay().plusMinutes(totalMinutes)
    }

    private fun julianDate(date: LocalDate): Double {
        var year = date.year
        var month = date.monthValue
        val day = date.dayOfMonth
        if (month <= 2) {
            year -= 1
            month += 12
        }
        val a = floor(year / 100.0)
        val b = 2 - a + floor(a / 4.0)
        return floor(365.25 * (year + 4716)) +
            floor(30.6001 * (month + 1)) +
            day + b - 1524.5
    }

    private fun midDay(jd: Double): Double = fixHour(12.0 - sunPosition(jd).equationOfTime)

    private fun sunPosition(jd: Double): SunPosition {
        val d = jd - 2451545.0
        val g = fixAngle(357.529 + 0.98560028 * d)
        val q = fixAngle(280.459 + 0.98564736 * d)
        val l = fixAngle(q + 1.915 * sin(rad(g)) + 0.020 * sin(rad(2.0 * g)))
        val e = 23.439 - 0.00000036 * d
        val ra = fixHour(
            atan2(cos(rad(e)) * sin(rad(l)), cos(rad(l))) * 180 / Math.PI / 15
        )
        val eqt = q / 15.0 - ra
        val decl = asin(sin(rad(e)) * sin(rad(l))) * 180 / Math.PI
        return SunPosition(decl, eqt)
    }

    private fun sunAngleTime(
        jd: Double,
        lat: Double,
        angle: Double,
        time: Double,
        beforeNoon: Boolean
    ): Double {
        val declination = sunPosition(jd + time).declination
        val noon = midDay(jd + time)
        val denominator = cos(rad(declination)) * cos(rad(lat))
        if (abs(denominator) < 1e-9) return Double.NaN
        val raw = (-sin(rad(angle)) - sin(rad(declination)) * sin(rad(lat))) / denominator
        if (raw.isNaN() || raw < -1.0 || raw > 1.0) return Double.NaN
        val t = acos(raw) * 180 / Math.PI / 15.0
        return noon + if (beforeNoon) -t else t
    }

    private fun asrTime(jd: Double, lat: Double, time: Double, factor: Int): Double {
        val declination = sunPosition(jd + time).declination
        val angle = -arccot(factor + tan(rad(abs(lat - declination))))
        return sunAngleTime(jd, lat, angle, time, false)
    }

    private fun arccot(x: Double): Double = atan(1.0 / x) * 180 / Math.PI

    private fun fixAngle(angle: Double): Double = angle - 360.0 * floor(angle / 360.0)

    private fun fixHour(hour: Double): Double = hour - 24.0 * floor(hour / 24.0)

    private fun rad(degrees: Double): Double = degrees * Math.PI / 180.0

    private data class SunPosition(val declination: Double, val equationOfTime: Double)
}
