package com.example.king_food

import android.os.Bundle
import com.yandex.mapkit.MapKitFactory
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Safety net: make sure API key is set before plugin registration.
        MapKitFactory.setApiKey("0680a08c-f5b0-4e35-98fb-c1e3543be614")
        super.onCreate(savedInstanceState)
    }
}
