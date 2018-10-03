package com.ediacaranstudio.datacard

import android.os.Build
import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity() : FlutterActivity() {

    private lateinit var db: DatabaseHelper
    private lateinit var nfc: NFCAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP)
            window.statusBarColor = 0

        GeneratedPluginRegistrant.registerWith(this)

        db = DatabaseHelper(this)
        nfc = NFCAdapter(this, this, db)
        Channels.initial(this, flutterView, nfc, db)
    }

    override fun onPause() {
        super.onPause()
    }

    override fun onResume() {
        super.onResume()
    }
}
