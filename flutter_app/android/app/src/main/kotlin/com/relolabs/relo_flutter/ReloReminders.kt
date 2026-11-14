package com.relolabs.relo_flutter

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * 마감 알림. 앱(Dart의 ReminderPlanner)이 정한 "언제 무엇을"을 받아 기기의 알람에 맡기고,
 * 그 시각이 되면 알림을 띄운다. 서버를 거치지 않으므로 알림 내용이 기기 밖으로 나가지 않는다.
 *
 *  - 알람은 "대략 그 시각"으로 맞춘다 (정확한 알람 권한을 요구하지 않는다).
 *  - 기기를 껐다 켜면 알람이 지워지므로, 맞춰 둔 목록을 기기에 적어 두고 [ReloBootReceiver]가 다시 맞춘다.
 *  - 로그아웃하거나 알림을 끄면 앱이 빈 목록을 보내고, 그러면 모두 지운다.
 */
object ReloReminders {
    const val EXTRA_CLAIM_ID = "relo_claim_id"
    private const val CHANNEL_ID = "relo_deadlines"
    private const val PREFS = "relo_reminders"
    private const val KEY_ITEMS = "items"
    private const val ACTION_FIRE = "com.relolabs.relo_flutter.REMINDER"
    private const val EXTRA_ID = "relo_id"
    private const val EXTRA_TITLE = "relo_title"
    private const val EXTRA_BODY = "relo_body"
    private const val BRAND_BLUE = 0xFF2B7FFF.toInt()

    data class Item(
        val id: Int,
        val at: Long,
        val title: String,
        val body: String,
        val claimId: String,
    ) {
        fun toJson(): JSONObject = JSONObject()
            .put("id", id).put("at", at).put("title", title).put("body", body).put("claimId", claimId)

        companion object {
            fun from(map: Map<String, Any?>): Item? {
                val id = (map["id"] as? Number)?.toInt() ?: return null
                val at = (map["at"] as? Number)?.toLong() ?: return null
                val title = map["title"] as? String ?: return null
                return Item(id, at, title, map["body"] as? String ?: "", map["claimId"] as? String ?: "")
            }

            fun from(json: JSONObject): Item = Item(
                json.getInt("id"),
                json.getLong("at"),
                json.getString("title"),
                json.optString("body"),
                json.optString("claimId"),
            )
        }
    }

    /** 이 앱의 알림이 기기에서 허용되어 있는지 */
    fun allowed(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        return context.getSystemService(NotificationManager::class.java).areNotificationsEnabled()
    }

    /** 맞춰 둔 알림을 모두 지우고 [items]로 바꾼다. */
    fun replaceAll(context: Context, items: List<Item>) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        for (old in load(context)) {
            firePendingIntent(context, old, create = false)?.let {
                alarms.cancel(it)
                it.cancel()
            }
        }
        save(context, items)
        schedule(context, items)
    }

    /** 기기를 다시 켠 뒤: 적어 둔 목록으로 다시 맞춘다. */
    fun rescheduleSaved(context: Context) = schedule(context, load(context))

    private fun schedule(context: Context, items: List<Item>) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        val now = System.currentTimeMillis()
        for (item in items) {
            if (item.at <= now) continue
            val fire = firePendingIntent(context, item, create = true) ?: continue
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, item.at, fire)
        }
    }

    private fun firePendingIntent(context: Context, item: Item, create: Boolean): PendingIntent? {
        val intent = Intent(context, ReloReminderReceiver::class.java)
            .setAction(ACTION_FIRE)
            .putExtra(EXTRA_ID, item.id)
            .putExtra(EXTRA_TITLE, item.title)
            .putExtra(EXTRA_BODY, item.body)
            .putExtra(EXTRA_CLAIM_ID, item.claimId)
        val mode = if (create) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE
        return PendingIntent.getBroadcast(context, item.id, intent, mode or PendingIntent.FLAG_IMMUTABLE)
    }

    /** 알람이 울렸을 때: 알림을 띄운다. 누르면 그 환불 건을 연다. */
    fun show(context: Context, fired: Intent) {
        if (fired.action != ACTION_FIRE || !allowed(context)) return
        val id = fired.getIntExtra(EXTRA_ID, 0)
        val title = fired.getStringExtra(EXTRA_TITLE) ?: return
        val body = fired.getStringExtra(EXTRA_BODY) ?: ""
        val notifications = context.getSystemService(NotificationManager::class.java)

        val builder = if (Build.VERSION.SDK_INT >= 26) {
            notifications.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.relo_channel_deadlines),
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        val open = Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            .putExtra(EXTRA_CLAIM_ID, fired.getStringExtra(EXTRA_CLAIM_ID))
        val tap = PendingIntent.getActivity(
            context,
            id,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        notifications.notify(
            id,
            builder
                .setSmallIcon(R.drawable.ic_stat_relo)
                .setColor(BRAND_BLUE)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(Notification.BigTextStyle().bigText(body))
                .setCategory(Notification.CATEGORY_REMINDER)
                .setContentIntent(tap)
                .setAutoCancel(true)
                .build(),
        )
    }

    private fun load(context: Context): List<Item> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_ITEMS, null)
            ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { Item.from(array.getJSONObject(it)) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun save(context: Context, items: List<Item>) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
        if (items.isEmpty()) {
            prefs.remove(KEY_ITEMS)
        } else {
            prefs.putString(KEY_ITEMS, JSONArray(items.map { it.toJson() }).toString())
        }
        prefs.apply()
    }
}

/** 맞춰 둔 시각이 되면 불린다. */
class ReloReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) = ReloReminders.show(context, intent)
}

/** 기기를 다시 켰거나 앱이 업데이트됐을 때 불린다. */
class ReloBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED ->
                ReloReminders.rescheduleSaved(context)
        }
    }
}
