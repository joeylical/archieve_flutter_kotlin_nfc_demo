package com.ediacaranstudio.datacard

import android.content.Context
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterView

object Channels {
    private val EVENTCHANNEL = "com.ediacaranstudio.datacard/events"
    private val MSGCHANNEL = "com.ediacaranstudio.datacard/showMsg"
    private val CMDCHANNEL = "com.ediacaranstudio.datacard/commands"
    private val RMCHANNEL = "com.ediacaranstudio.datacard/rmrecord"
    private val WRITECHANNEL = "com.ediacaranstudio.datacard/writecounter"

    private var eventSink: EventChannel.EventSink? = null
    private var eventMsgSink: EventChannel.EventSink? = null
    private var eventRmSink: EventChannel.EventSink? = null
    private var eventWriteSink: EventChannel.EventSink? = null

    fun initial(ctx: Context, view: FlutterView, nfc: NFCAdapter, db: DatabaseHelper) {

        // 注册各通道的处理函数
        MethodChannel(view, CMDCHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "deleteRecord") {
                val rid = call.argument<Int>("rid")
                db.delResult(rid)
            } else if (call.method == "writeNfc") {
                val info = NFCInfo(
                        call.argument<String>("protocolVersion"),
                        call.argument<String>("deviceName"),
                        call.argument<String>("manufacturer"),
                        call.argument<String>("model"),
                        call.argument<String>("serialNumber"),
                        call.argument<String>("hardwareVersion"),
                        call.argument<String>("softwareVersion"),
                        call.argument<String>("eeVersion")
                )
                nfc.setWriteMode(info)
            } else if (call.method == "cancelWrite") {
                nfc.setReadMode()
            } else if (call.method == "loaded") {
                val list = db.getRecords()
                if (list != null)
                    for (record in list) {
                        Channels.sendRecord(record)
                    }
            } else if (call.method == "setIdle") {
                nfc.setIdle()
            } else if (call.method == "setRead") {
                nfc.setReadMode()
            }
        }

        EventChannel(view, EVENTCHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                eventSink = p1
                nfc.setReadMode()
            }

            override fun onCancel(p0: Any?) {
                eventSink = null
                nfc.setIdle()
            }
        })

        EventChannel(view, MSGCHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                eventMsgSink = p1
            }

            override fun onCancel(p0: Any?) {
                eventMsgSink = null
            }
        })

        EventChannel(view, RMCHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                eventRmSink = p1
            }

            override fun onCancel(p0: Any?) {
                eventRmSink = null
            }
        })

        EventChannel(view, WRITECHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(p0: Any?, p1: EventChannel.EventSink?) {
                eventWriteSink = p1
            }

            override fun onCancel(p0: Any?) {
                eventWriteSink = null
            }
        })
    }

    fun showMsg(str: String) {
        eventMsgSink?.success(str)
    }

    fun sendRecord(result: Record) {
        val s = Gson().toJson(result)
        eventSink?.success(s)
    }

    fun rmRecord(rid: Int) {
        eventRmSink?.success(rid.toString())
    }

    fun sendWriteOk() {
        eventWriteSink?.success("sucess")
    }

    fun sendWriteFailed() {
        eventWriteSink?.success("failed")
    }
}