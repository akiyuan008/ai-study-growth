package com.studygrowth.ai_study_growth

import android.Manifest
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.net.Uri
import com.studygrowth.ai_study_growth.monitor.DocumentScanner
import java.io.File
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.studygrowth.ai_study_growth.monitor.BehaviorEventBus
import com.studygrowth.ai_study_growth.monitor.LockScreenActivity
import com.studygrowth.ai_study_growth.monitor.UsageMonitorService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * 原生桥接层 —— MethodChannel 收指令，EventChannel 推事实。
 *
 * Kotlin 侧只负责产出行为事实（前台切换、锁屏显示），
 * 所有判定（是否分心、是否锁屏、专注时长）都在 Dart 侧完成。
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "studygrowth/monitor"
        const val EVENT_CHANNEL = "studygrowth/monitor/events"
        const val SCANNER_CHANNEL = "studygrowth/scanner"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BehaviorEventBus.init(this)

        // Part 2：文档扫描通道（Kotlin 产事实：四边形检测/透视拉正/匀光）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanDocument" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.success(null)
                        } else {
                            val out = DocumentScanner.scan(path, File(filesDir, "scans"))
                            result.success(out)
                        }
                    }
                    "cropByPoints" -> {
                        val path = call.argument<String>("path")
                        val ntl = call.argument<DoubleArray>("tl")
                        val ntr = call.argument<DoubleArray>("tr")
                        val nbr = call.argument<DoubleArray>("br")
                        val nbl = call.argument<DoubleArray>("bl")
                        if (path == null || ntl == null || ntr == null || nbr == null || nbl == null) {
                            result.success(null)
                        } else {
                            val out = DocumentScanner.cropByNormalizedPoints(
                                path, File(filesDir, "scans"), ntl, ntr, nbr, nbl
                            )
                            result.success(out)
                        }
                    }
                    "rotate90" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.success(null)
                        } else {
                            val out = DocumentScanner.rotate90(path, File(filesDir, "scans"))
                            result.success(out)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMonitor" -> {
                        UsageMonitorService.start(this)
                        result.success(true)
                    }
                    "stopMonitor" -> {
                        UsageMonitorService.stop(this)
                        result.success(true)
                    }
                    "showLock" -> {
                        val message = call.argument<String>("message")
                        LockScreenActivity.show(this, message)
                        result.success(true)
                    }
                    "ackEvents" -> {
                        BehaviorEventBus.ackAll()
                        result.success(true)
                    }
                    "isUsageAccessGranted" -> {
                        result.success(isUsageAccessGranted())
                    }
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }
                    "openUsageSettingsForPackage" -> {
                        // 使用统计权限（系统设置页）
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    }
                    "openOverlaySettings" -> {
                        // 悬浮窗权限
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                        result.success(true)
                    }
                    "openNotificationSettings" -> {
                        // 应用通知设置页
                        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "requestNotificationPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            if (ContextCompat.checkSelfPermission(
                                    this,
                                    Manifest.permission.POST_NOTIFICATIONS
                                ) == PackageManager.PERMISSION_GRANTED
                            ) {
                                result.success(true)
                            } else {
                                ActivityCompat.requestPermissions(
                                    this,
                                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                    3001
                                )
                                result.success(false)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var listener: ((String) -> Unit)? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // 1) 重放落盘中未确认的事件（重启补推）
                    for (pending in BehaviorEventBus.pending()) {
                        events?.success(pending)
                    }
                    // 2) 注册实时监听
                    val l: (String) -> Unit = { json -> events?.success(json) }
                    listener = l
                    BehaviorEventBus.register(l)
                }

                override fun onCancel(arguments: Any?) {
                    listener?.let { BehaviorEventBus.unregister(it) }
                    listener = null
                }
            })
    }

    private fun isUsageAccessGranted(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
