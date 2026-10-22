package com.rafiq.rafiqflutter

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Geocoder
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class LocationChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "rafiq/location"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "hasPermission" -> result.success(hasPermission())
            "requestPermission" -> {
                val activity = context as? android.app.Activity
                if (activity == null) {
                    result.error("no_activity", "activity not available", null)
                    return
                }
                androidx.core.app.ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION
                    ),
                    7001
                )
                result.success(true)
            }
            "getCurrentLocation" -> {
                Thread {
                    val location = resolveLocation()
                    if (location == null) {
                        result.success(null)
                        return@Thread
                    }
                    val city = geocodeCity(location.latitude, location.longitude)
                    result.success(
                        mapOf(
                            "latitude" to location.latitude,
                            "longitude" to location.longitude,
                            "city" to city
                        )
                    )
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    private fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    private fun resolveLocation(): Location? {
        if (!hasPermission()) return null
        val manager = context.getSystemService(LocationManager::class.java) ?: return null
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)
        val lastKnown = providers.mapNotNull { provider ->
            runCatching { manager.getLastKnownLocation(provider) }.getOrNull()
        }.maxByOrNull { it.time }
        val fresh = providers.firstNotNullOfOrNull { provider ->
            runCatching { requestSingle(manager, provider) }.getOrNull()
        }
        return fresh ?: lastKnown
    }

    private fun requestSingle(manager: LocationManager, provider: String): Location? {
        if (!manager.isProviderEnabled(provider)) return null
        val latch = java.util.concurrent.CountDownLatch(1)
        var resolved: Location? = null
        val listener = object : android.location.LocationListener {
            override fun onLocationChanged(location: Location) {
                resolved = location
                runCatching { manager.removeUpdates(this) }
                latch.countDown()
            }

            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
            override fun onProviderEnabled(provider: String) = Unit
            override fun onProviderDisabled(provider: String) = Unit
        }
        runCatching {
            manager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
        }.getOrElse { return null }
        latch.await(12, java.util.concurrent.TimeUnit.SECONDS)
        runCatching { manager.removeUpdates(listener) }
        return resolved
    }

    private fun geocodeCity(latitude: Double, longitude: Double): String? = runCatching {
        if (!Geocoder.isPresent()) return null
        @Suppress("DEPRECATION")
        val results = Geocoder(context, Locale("ar")).getFromLocation(latitude, longitude, 1)
        results?.firstOrNull()?.let { address ->
            address.locality ?: address.subAdminArea ?: address.adminArea
        }
    }.getOrNull()
}
