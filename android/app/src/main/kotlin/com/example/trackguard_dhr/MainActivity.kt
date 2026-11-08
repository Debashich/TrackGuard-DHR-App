package com.example.trackguard_dhr

import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // 1. Install AndroidX SplashScreen before super.onCreate
        val splashScreen = installSplashScreen()

        super.onCreate(savedInstanceState)

        // 4. Do not add an exit animation; immediately remove the splash view
        // 5. Allow Android to remove the splash as soon as the Flutter activity is ready to draw
        splashScreen.setOnExitAnimationListener { splashScreenViewProvider ->
            splashScreenViewProvider.remove()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }
}
