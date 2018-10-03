package com.ediacaranstudio.datacard

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import com.google.gson.annotations.SerializedName
import org.jetbrains.anko.db.*

data class BloodPressure(@SerializedName("systolic") var systolic: Int,
                         @SerializedName("diastolic") var diastolic: Int,
                         @SerializedName("pulse") var pulse: Int)

data class PwvResult(val bloodPressure: Array<BloodPressure>, var leftPwv: Int, var rightPwv: Int)

data class User(val uid: Int, val name: String)

// value 储存json for BloodPressure/PwvResult
data class Record(@SerializedName("rid") val rid: Int,
                  @SerializedName("userName") val userName: String,
                  @SerializedName("time") val time: Int,
                  @SerializedName("type") val type: String,
                  @SerializedName("value") val value: String)

class DatabaseHelper(ctx: Context) : ManagedSQLiteOpenHelper(ctx, "NFCDataCard", null, 1) {

    companion object {
        private var instance: DatabaseHelper? = null

        @Synchronized
        fun Instance(context: Context): DatabaseHelper {
            if (instance == null) {
                instance = DatabaseHelper(context.applicationContext)
            }
            return instance!!
        }
    }

    override fun onCreate(db: SQLiteDatabase?) {
        db?.createTable("Records", true,
                "rid" to INTEGER + PRIMARY_KEY + UNIQUE + AUTOINCREMENT,
                "userName" to TEXT,
                "time" to INTEGER,
                "type" to TEXT,
                "value" to TEXT
        )
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        db?.dropTable("Records", true)
    }

    fun getRecords(): List<Record>? {
        val db = this.readableDatabase

        return db?.select("Records")
                ?.orderBy("rid", SqlOrderDirection.ASC)
                ?.exec {
                    parseList(classParser<Record>())
                }
    }

    fun saveRecord(name: String, time: Int, type: String, value: String): Record {
        val db = this.writableDatabase

        val rid = db?.insert("Records",
                "userName" to name,
                "time" to time,
                "type" to type,
                "value" to value
        )

        return Record(rid?.toInt()!!, name, time, type, value)
    }

    fun delResult(rid: Int) {
        val db = this.writableDatabase
        db?.delete("Records", "rid={rid}", "rid" to rid)
        Channels.rmRecord(rid)
    }
}
