package com.studygrowth.ai_study_growth.monitor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * 使用监控前台服务 —— 只产事实，不做判定。
 *
 * 每 [POLL_MS] 查询一次前台应用，应用切换时产出 APP_FOREGROUND 事件
 * （携带上一个应用的实际停留时长），经 [BehaviorEventBus] 落盘并推给 Dart。
 * 分心判定、锁屏决策全部在 Dart 侧的 DisciplineEngine 完成。
 */
class UsageMonitorService : Service() {

    companion object {
        const val CHANNEL_ID = "growth_monitor"
        const val NOTIFICATION_ID = 2001
        const val POLL_MS = 15_000L
        const val ACTION_START = "com.studygrowth.monitor.START"
        const val ACTION_STOP = "com.studygrowth.monitor.STOP"

        fun start(context: Context) {
            val intent = Intent(context, UsageMonitorService::class.java)
                .setAction(ACTION_START)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.startService(
                Intent(context, UsageMonitorService::class.java).setAction(ACTION_STOP)
            )
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastPackage: String? = null
    private var lastSwitchAt: Long = System.currentTimeMillis()
    private var running = false

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (!running) return
            pollForegroundApp()
            handler.postDelayed(this, POLL_MS)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        BehaviorEventBus.init(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopMonitoring()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIFICATION_ID, buildNotification())
                startMonitoring()
            }
        }
        return START_STICKY
    }

    private fun startMonitoring() {
        if (running) return
        running = true
        lastPackage = currentForegroundApp()
        lastSwitchAt = System.currentTimeMillis()
        handler.removeCallbacks(pollRunnable)
        handler.postDelayed(pollRunnable, POLL_MS)
    }

    private fun stopMonitoring() {
        running = false
        handler.removeCallbacks(pollRunnable)
    }

    private fun pollForegroundApp() {
        val pkg = currentForegroundApp() ?: return
        if (pkg == lastPackage) return

        val now = System.currentTimeMillis()
        val duration = now - lastSwitchAt
        val prev = lastPackage
        lastPackage = pkg
        lastSwitchAt = now

        val prevField = if (prev != null) "\"prevPackage\":\"$prev\"," else ""
        BehaviorEventBus.append(
            "{\"eventType\":\"app_foreground\",\"appPackage\":\"$pkg\"," +
                "$prevField\"at\":$now,\"durationMs\":$duration}"
        )
    }

    private fun currentForegroundApp(): String? {
        val usage = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return null
        val end = System.currentTimeMillis()
        val begin = end - 1000L * 60 * 2
        return try {
            usage.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, begin, end)
                .maxByOrNull { it.lastTimeUsed }
                ?.packageName
        } catch (_: Exception) {
            null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "专注监控",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "专注期间监控前台应用，产出行为事实"
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("AI 学习成长系统")
            .setContentText("专注监控运行中")
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        stopMonitoring()
        super.onDestroy()
    }
}
