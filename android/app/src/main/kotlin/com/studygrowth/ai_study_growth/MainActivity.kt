package com.studygrowth.ai_study_growth

import com.studygrowth.ai_study_growth.monitor.DocumentScanner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 原生桥接层 —— Kotlin 产事实，Dart 做决策。
 *
 * v10：仅保留文档扫描通道（OpenCV 四边形检测/透视拉正/匀光）。
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val SCANNER_CHANNEL = "studygrowth/scanner"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 文档扫描通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanDocument" -> {
                        val path = call.argument<String>("path")
                        val roi = call.argument<DoubleArray>("roi")
                        if (path == null) {
                            result.success(null)
                        } else {
                            val out = DocumentScanner.scan(path, File(filesDir, "scans"), roi)
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
    }
}
