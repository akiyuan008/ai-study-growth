package com.studygrowth.ai_study_growth.monitor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import org.json.JSONObject
import org.opencv.core.Core
import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Rect
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.sqrt

/**
 * 文档扫描器 v13 —— Kotlin 产事实。
 *
 * 管线：缩放≤1000px → 双边滤波 → Canny 双阈值 + 膨胀 →
 * approxPolyDP epsilon 扫描（0.02→0.05）→ 面积>20% 最大四边形。
 * 失败回落链（禁死路）：四边形 → minAreaRect → 全幅内缩 2%（提示手动校准）。
 *
 * 返回 JSON：{"path": "...", "fallback": "none|minarea|fullframe"}
 * 支持 ROI（对准引导框作为感兴趣区域，提升检测成功率）。
 *
 * 补钉 B：cropByNormalizedPoints 返回 JSON {"status":"success|error", "path":..., "error":...}
 * 不再静默吞错——每条失败路径都有明确原因。
 */
class DocumentScanner {

    companion object {
        private const val TAG = "DocumentScanner"
    }

    init {
        try {
            System.loadLibrary(Core.NATIVE_LIBRARY_NAME)
            Log.i(TAG, "OpenCV loaded: ${Core.VERSION}")
        } catch (e: Throwable) {
            Log.e(TAG, "OpenCV load failed", e)
        }
    }

    private fun opencvReady(): Boolean = try {
        Core.VERSION.isNotEmpty()
    } catch (_: Throwable) {
        false
    }

    /** 自动文档提取 */
    fun scan(srcPath: String, outDir: File, roi: DoubleArray?): String? {
        if (!opencvReady()) {
            Log.e(TAG, "scan: OpenCV not ready")
            return null
        }
        return try {
            val src = Imgcodecs.imread(srcPath)
            if (src.empty()) {
                Log.e(TAG, "scan: imread returned empty Mat for $srcPath")
                return null
            }
            val workMat = if (roi != null && roi.size == 4) {
                val x = (roi[0] * src.cols()).toInt().coerceIn(0, src.cols() - 1)
                val y = (roi[1] * src.rows()).toInt().coerceIn(0, src.rows() - 1)
                val w = (roi[2] * src.cols()).toInt().coerceIn(1, src.cols() - x)
                val h = (roi[3] * src.rows()).toInt().coerceIn(1, src.rows() - y)
                Mat(src, Rect(x, y, w, h))
            } else {
                src
            }

            val scale = 1000.0 / max(workMat.cols(), workMat.rows()).coerceAtLeast(1.0)
            val scaled = if (scale < 1.0) {
                val resized = Mat()
                Imgproc.resize(workMat, resized, Size(workMat.cols() * scale, workMat.rows() * scale))
                resized
            } else {
                workMat.clone()
            }

            val gray = Mat()
            Imgproc.cvtColor(scaled, gray, Imgproc.COLOR_BGR2GRAY)
            val filtered = Mat()
            Imgproc.bilateralFilter(gray, filtered, 5, 75.0, 75.0)
            val edges = Mat()
            Imgproc.Canny(filtered, edges, 75.0, 200.0)
            val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
            Imgproc.dilate(edges, edges, kernel)

            val contours = mutableListOf<MatOfPoint>()
            Imgproc.findContours(edges, contours, Mat(), Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE)

            var bestQuad: MatOfPoint2f? = null
            var bestArea = 0.0
            val imgArea = scaled.cols().toDouble() * scaled.rows()

            for (c in contours) {
                val c2f = MatOfPoint2f(*c.toArray())
                val peri = Imgproc.arcLength(c2f, true)
                for (eps in listOf(0.02, 0.03, 0.04, 0.05)) {
                    val approx = MatOfPoint2f()
                    Imgproc.approxPolyDP(c2f, approx, eps * peri, true)
                    if (approx.total() == 4L) {
                        val area = Imgproc.contourArea(approx)
                        if (area > imgArea * 0.20 && area > bestArea) {
                            bestArea = area
                            bestQuad = approx
                        }
                    }
                }
            }

            val srcQuad: MatOfPoint2f
            val fallback: String

            if (bestQuad != null) {
                srcQuad = bestQuad
                fallback = "none"
            } else {
                val contour = contours.maxByOrNull { Imgproc.contourArea(it) }
                if (contour != null && Imgproc.contourArea(contour) > imgArea * 0.15) {
                    val c2f = MatOfPoint2f(*contour.toArray())
                    val rect = Imgproc.minAreaRect(c2f)
                    val pts = arrayOfNulls<Point>(4)
                    rect.points(pts)
                    srcQuad = MatOfPoint2f(*pts.requireNoNulls())
                    fallback = "minarea"
                } else {
                    val w = scaled.cols().toDouble()
                    val h = scaled.rows().toDouble()
                    srcQuad = MatOfPoint2f(
                        Point(w * 0.02, h * 0.02),
                        Point(w * 0.98, h * 0.02),
                        Point(w * 0.98, h * 0.98),
                        Point(w * 0.02, h * 0.98)
                    )
                    fallback = "fullframe"
                }
            }

            val warped = perspectiveCorrect(scaled, srcQuad)
            outDir.mkdirs()
            val out = File(outDir, "scan_${System.currentTimeMillis()}.jpg")
            val ok = Imgcodecs.imwrite(out.absolutePath, warped)

            src.release(); scaled.release(); gray.release()
            filtered.release(); edges.release()

            if (!ok) {
                Log.e(TAG, "scan: imwrite failed for ${out.absolutePath}")
                return null
            }

            val json = JSONObject()
            json.put("path", out.absolutePath)
            json.put("fallback", fallback)
            json.toString()
        } catch (e: Throwable) {
            Log.e(TAG, "scan: exception", e)
            null
        }
    }

    /** 透视拉正 */
    private fun perspectiveCorrect(src: Mat, quad: MatOfPoint2f): Mat {
        val pts = quad.toArray()
        val tl = pts[0]; val tr = pts[1]; val br = pts[2]; val bl = pts[3]
        val widthTop = sqrt((tr.x - tl.x).pow(2) + (tr.y - tl.y).pow(2))
        val widthBottom = sqrt((br.x - bl.x).pow(2) + (br.y - bl.y).pow(2))
        val heightLeft = sqrt((bl.x - tl.x).pow(2) + (bl.y - tl.y).pow(2))
        val heightRight = sqrt((br.x - tr.x).pow(2) + (br.y - tr.y).pow(2))
        val maxW = max(widthTop, widthBottom).toInt()
        val maxH = max(heightLeft, heightRight).toInt()
        val dst = MatOfPoint2f(
            Point(0.0, 0.0),
            Point(maxW.toDouble(), 0.0),
            Point(maxW.toDouble(), maxH.toDouble()),
            Point(0.0, maxH.toDouble())
        )
        val m = Imgproc.getPerspectiveTransform(quad, dst)
        val warped = Mat()
        Imgproc.warpPerspective(src, warped, m, Size(maxW.toDouble(), maxH.toDouble()))
        return warped
    }

    private fun Double.pow(n: Int): Double = Math.pow(this, n.toDouble())

    /**
     * 手动四角裁剪（归一化坐标 0-1）
     * 补钉 B：返回 JSON {"status":"success|error", "path":..., "error":...}
     */
    fun cropByNormalizedPoints(
        srcPath: String,
        outDir: File,
        ntl: DoubleArray, ntr: DoubleArray, nbr: DoubleArray, nbl: DoubleArray
    ): String {
        val json = JSONObject()
        try {
            if (!opencvReady()) {
                json.put("status", "error")
                json.put("error", "OpenCV 未加载")
                return json.toString()
            }
            val src = Imgcodecs.imread(srcPath)
            if (src.empty()) {
                json.put("status", "error")
                json.put("error", "无法读取图片: $srcPath")
                return json.toString()
            }
            val w = src.cols().toDouble()
            val h = src.rows().toDouble()

            val quad = MatOfPoint2f(
                Point(ntl[0] * w, ntl[1] * h),
                Point(ntr[0] * w, ntr[1] * h),
                Point(nbr[0] * w, nbr[1] * h),
                Point(nbl[0] * w, nbl[1] * h)
            )
            val warped = perspectiveCorrect(src, quad)
            outDir.mkdirs()
            val out = File(outDir, "crop_${System.currentTimeMillis()}.jpg")
            val ok = Imgcodecs.imwrite(out.absolutePath, warped)
            src.release(); warped.release(); quad.release()
            if (!ok) {
                json.put("status", "error")
                json.put("error", "写入裁剪图片失败: ${out.absolutePath}")
                return json.toString()
            }
            json.put("status", "success")
            json.put("path", out.absolutePath)
            return json.toString()
        } catch (e: Throwable) {
            Log.e(TAG, "cropByNormalizedPoints: exception", e)
            json.put("status", "error")
            json.put("error", "裁剪异常: ${e.message ?: e.javaClass.simpleName}")
            return json.toString()
        }
    }

    /** 旋转 90° */
    fun rotate90(srcPath: String, outDir: File): String? {
        return try {
            val bmp = BitmapFactory.decodeFile(srcPath) ?: run {
                Log.e(TAG, "rotate90: decodeFile failed for $srcPath")
                return null
            }
            val matrix = android.graphics.Matrix().apply { postRotate(90f) }
            val rotated = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, matrix, true)
            outDir.mkdirs()
            val out = File(outDir, "rot_${System.currentTimeMillis()}.jpg")
            FileOutputStream(out).use {
                rotated.compress(Bitmap.CompressFormat.JPEG, 92, it)
            }
            bmp.recycle(); rotated.recycle()
            out.absolutePath
        } catch (e: Throwable) {
            Log.e(TAG, "rotate90: exception", e)
            null
        }
    }
}
