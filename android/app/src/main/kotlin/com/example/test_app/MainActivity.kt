package com.example.test_app

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Vibraciones de las barras de cristal directo al motor: muchas
        // tabletas (p. ej. Galaxy Tab) ignoran la vibración táctil del
        // sistema (performHapticFeedback), y la barra quedaba sin vibrar.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hymnal/haptics")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tick" -> { vibrate(VibrationEffect.EFFECT_TICK, 20); result.success(null) }
                    "settle" -> { vibrate(VibrationEffect.EFFECT_CLICK, 35); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }

    /** Efecto predefinido si el motor lo soporta; si no, un pulso corto. */
    private fun vibrate(effect: Int, fallbackMs: Long) {
        val vibrator = vibrator() ?: return
        if (!vibrator.hasVibrator()) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            vibrator.vibrate(fallbackMs)
            return
        }
        val supported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            vibrator.areAllEffectsSupported(effect) == Vibrator.VIBRATION_EFFECT_SUPPORT_YES
        val vibration = if (supported) {
            VibrationEffect.createPredefined(effect)
        } else {
            VibrationEffect.createOneShot(fallbackMs, VibrationEffect.DEFAULT_AMPLITUDE)
        }
        vibrator.vibrate(vibration)
    }
}
