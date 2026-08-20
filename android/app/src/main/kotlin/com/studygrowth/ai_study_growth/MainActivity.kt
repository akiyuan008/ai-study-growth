package com.studygrowth.ai_study_growth

import com.studygrowth.ai_study_growth.monitor.DocumentScanner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

/**
 * 原生桥接层 —— Kotlin 产事实，Dart 做决策。
 *
 * v13：文档扫描通道（OpenCV 四边形检测/透视拉正/匀光）。
 * 补钉 B：cropByPoints 返回 JSON Map 含 status/error，不再静默 null。
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val SCANNER_CHANNEL = "studygrowth/scanner"
        private const val TAG = "MainActivity"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanDocument" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val roiRaw = call.argument<List<Double>>("roi")
                        val roi: DoubleArray? = if (roiRaw != null && roiRaw.size == 4) {
                            doubleArrayOf(roiRaw[0], roiRaw[1], roiRaw[2], roiRaw[3])
                        } else null
                        val out = DocumentScanner.scan(path, File(filesDir, "scans"), roi)
                        result.success(out)
                    }
                    "getVersion" -> {
                        result.success(DocumentScanner.getVersion())
                    }
                    "getStatus" -> {
                        result.success(DocumentScanner.getStatus())
                    }
                    "enhance" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.success(null)
                        } else {
                            result.success(DocumentScanner.enhance(path, File(filesDir, "scans")))
                        }
                    }
                    "cropByPoints" -> {
                        val path = call.argument<String>("path")
                        // 补钉 B：用 List<Double> 接收再转 DoubleArray
                        // 避免类型转换问题
                        val tlRaw = call.argument<List<Double>>("tl")
                        val trRaw = call.argument<List<Double>>("tr")
                        val brRaw = call.argument<List<Double>>("br")
                        val blRaw = call.argument<List<Double>>("bl")
                        if (path == null || tlRaw == null || trRaw == null ||
                            brRaw == null || blRaw == null ||
                            tlRaw.size < 2 || trRaw.size < 2 ||
                            brRaw.size < 2 || blRaw.size < 2) {
                            // 返回错误 JSON 而非 null
                            val errJson = JSONObject()
                            errJson.put("status", "error")
                            errJson.put("error", "参数缺失或格式不对")
                            result.success(errJson.toString())
                            return@setMethodCallHandler
                        }
                        val ntl = doubleArrayOf(tlRaw[0], tlRaw[1])
                        val ntr = doubleArrayOf(trRaw[0], trRaw[1])
                        val nbr = doubleArrayOf(brRaw[0], brRaw[1])
                        val nbl = doubleArrayOf(blRaw[0], blRaw[1])
                        val raw = DocumentScanner.cropByNormalizedPoints(
                            path, File(filesDir, "scans"), ntl, ntr, nbr, nbl
                        )
                        // 解析 JSON 返回 Map
                        try {
                            val parsed = JSONObject(raw)
                            val map = HashMap<String, Any?>()
                            for (key in parsed.keys()) {
                                map[key] = parsed.get(key)
                            }
                            result.success(map)
                        } catch (_: Throwable) {
                            result.success(mapOf("status" to "error", "error" to "解析裁剪结果失败"))
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
