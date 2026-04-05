package com.example.king_food

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Required for yandex_mapkit plugin registration.
        MapKitFactory.setApiKey("0680a08c-f5b0-4e35-98fb-c1e3543be614")
    }
}
