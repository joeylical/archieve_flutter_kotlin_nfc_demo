package com.ediacaranstudio.datacard

import android.content.Context
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.NfcA
import android.util.Log
import com.google.gson.Gson
import io.flutter.plugin.common.JSONUtil
import java.io.IOException

class TagReader(_db: DatabaseHelper) : NfcAdapter.ReaderCallback {
    private var db: DatabaseHelper = _db

    private fun getType(na: NfcA): String? {
        val sendCmd = byteArrayOf(0x30, 0x1c)
        return String(na.transceive(sendCmd))
                .trimEnd('\u0000')
    }

    private fun getRawBP(na: NfcA, index: Int = 1): BloodPressure {
        val sendCmd = byteArrayOf(0x30, (0x6f + index).toByte())
        val temp = na.transceive(sendCmd)
        return BloodPressure(
                systolic = (temp[0].toInt() and 0xff) + 25,
                diastolic = (temp[1].toInt() and 0xff) + 25,
                pulse = (temp[2].toInt() and 0xff)
        )
//        return BloodPressure(
//                systolic = 120,
//                diastolic = 80,
//                pulse = 70
//        )
    }

    private fun getBP(na: NfcA): Record? {
        val r = getRawBP(na, 1)
        if (r.systolic == 0 || r.diastolic == 0 || r.pulse == 0)
            return null;
        val result = Gson().toJson(r)
        return db.saveRecord("示例用户", (System.currentTimeMillis() / 1000).toInt(), "bloodpressure", result)
    }

    private fun getPwv(na: NfcA): Record {
        val t = Array(4,
                { getRawBP(na, it + 1) }
        )
        val temp = na.transceive(byteArrayOf(0x30, 0x74))
        val leftPwv = (temp[0].toInt() and 0xff) * 256 + (temp[1].toInt() and 0xff)
        val rightPwv = (temp[2].toInt() and 0xff) * 256 + (temp[3].toInt() and 0xff)
        val resultl0 = PwvResult(t, leftPwv, rightPwv)
        val result = Gson().toJson(resultl0)
        return db.saveRecord("示例用户", (System.currentTimeMillis() / 1000).toInt(), "pwv", result)
    }

    override fun onTagDiscovered(p0: Tag?) {
        if (p0 != null) {
            try {
                val na = NfcA.get(p0)
                na.connect()
                na.timeout = 3000
                val model = getType(na)
                Log.i("", model)
                if(model == "KD-560" || model == "KD-567") {
                    val result = getBP(na)
                    if (result != null)
                        Channels.sendRecord(result)
                    else
                        Channels.showMsg("无数据")
                } else if (model == "AGP-BP-100") {
                    val result = getPwv(na)
                    Channels.sendRecord(result)
                } else {
                    Channels.showMsg("型号不支持")
                }
                na.close()
            } catch (e: IOException) {
                Channels.showMsg("读取错误")
            } finally {
                //do nothing here
            }
        }
    }
}

data class NFCInfo(val protocolVersion: String,
                   val deviceName: String,
                   val manufacturer: String,
                   val model: String,
                   val serialNumber: String,
                   val hardwareVersion: String,
                   val softwareVersion: String,
                   val eeVersion: String) {

    fun toBytes(): ByteArray {
        val result = StringBuilder()
        result.append(protocolVersion.padEnd(16, '\u0000'))
        result.append(deviceName.padEnd(16, '\u0000'))
        result.append(manufacturer.padEnd(16, '\u0000'))
        result.append(model.padEnd(16, '\u0000'))
        result.append(serialNumber.padEnd(16, '\u0000'))
        result.append(hardwareVersion.replace(".", "").padEnd(4, '\u0000'))
        result.append(softwareVersion.replace(".", "").padEnd(4, '\u0000'))
        result.append(eeVersion.replace(".", "").padEnd(4, '\u0000'))

        return result.toString().toByteArray()
    }
}

class TagWriter(info: NFCInfo) : NfcAdapter.ReaderCallback {
    private val baseAddress = 0x10

    private var wInfo: NFCInfo = info

    private fun doWrite(na: NfcA) {
        val _bytes = wInfo.toBytes()

        val newSize = if (_bytes.size and 3 != 0)
            (_bytes.size and 3) + 4
        else
            _bytes.size

        val bytes = _bytes.copyOf(newSize)

        for (i in 0..newSize step 4) {
            val bytesToSend = byteArrayOf((0xa2).toByte(),
                    (baseAddress + i/4).toByte())
                        .plus(bytes.slice(i..i + 3))

            val temp = na.transceive(bytesToSend)

            if (temp.size != 1 || temp[0].toInt() != 10) {
                throw IOException()
            }
        }

//        na.transceive(byteArrayOf(0xa2.toByte(), 0x70, 0x39, 0x38, 0x00, 0x00))
//        na.transceive(byteArrayOf(0xa2.toByte(), 0x71, 0x31, 0x32, 0x35, 0x00))
//        na.transceive(byteArrayOf(0xa2.toByte(), 0x72, 0x31, 0x33, 0x32, 0x00))
    }

    override fun onTagDiscovered(p0: Tag?) {
        if (p0 != null) {
            try {
                val na = NfcA.get(p0)
                na.connect()
                na.timeout = 3000
                doWrite(na)
                na.close()
                Channels.sendWriteOk()
            } catch (e: IOException) {
                Channels.sendWriteFailed()
            } finally {
                //do nothing here
            }
        }
    }
}

class NFCAdapter(context: Context, _activity: MainActivity, _db: DatabaseHelper) {
    private var adapter: NfcAdapter = NfcAdapter.getDefaultAdapter(context)
    private var activity: MainActivity = _activity
    private var db: DatabaseHelper = _db

    fun setReadMode() {
        adapter.disableReaderMode(activity)
        adapter.enableReaderMode(activity, TagReader(db), NfcAdapter.FLAG_READER_NFC_A, null);
    }

    fun setWriteMode(info: NFCInfo) {
        adapter.disableReaderMode(activity)
        adapter.enableReaderMode(activity, TagWriter(info), NfcAdapter.FLAG_READER_NFC_A, null);
    }

    fun setIdle() {
        adapter.disableReaderMode(activity)
    }
}
