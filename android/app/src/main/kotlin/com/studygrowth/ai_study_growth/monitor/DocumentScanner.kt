package com.studygrowth.ai_study_growth.monitor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
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
 * 文档扫描器 v10 —— Kotlin 产事实。
 *
 * 管线：缩放≤1000px → 双边滤波 → Canny 双阈值 + 膨胀 →
 * approxPolyDP epsilon 扫描（0.02→0.05）→ 面积>20% 最大四边形。
 * 失败回落链（禁死路）：四边形 → minAreaRect → 全幅内缩 2%（提示手动校准）。
 *
 * 返回 JSON：{"path": "...", "fallback": "none|minarea|fullframe"}
 * 支持 ROI（对准引导框作为感兴趣区域，提升检测成功率）。
 */
object DocumentScanner {

    init {
        try {
            System.loadLibrary(Core.NATIVE_LIBRARY_NAME)
        } catch (_: Throwable) {
        }
    }

    private fun opencvReady(): Boolean = try {
        Core.VERSION.isNotEmpty()
    } catch (_: Throwable) {
        false
    }

    /**
     * 扫描入口。
     * @param roi 归一化 ROI [x, y, w, h]（0-1），可空 = 全幅
     * @return JSON 字符串；完全失败返回 null
     */
    fun scan(srcPath: String, outDir: File, roi: DoubleArray?): String? {
        if (!opencvReady()) return null
        return try {
            val src = Imgcodecs.imread(srcPath)
            if (src.empty()) return null

            // ROI 裁剪（对准框 = 默认感兴趣区域）
            val workMat = if (roi != null && roi.size == 4) {
                val x = (roi[0] * src.cols()).toInt().coerceIn(0, src.cols() - 1)
                val y = (roi[1] * src.rows()).toInt().coerceIn(0, src.rows() - 1)
                val w = (roi[2] * src.cols()).toInt().coerceIn(1, src.cols() - x)
                val h = (roi[3] * src.rows()).toInt().coerceIn(1, src.rows() - y)
                Mat(src, Rect(x, y, w, h))
            } else {
                src.clone()
            }
            val roiOffX = if (roi != null && roi.size == 4) roi[0] * src.cols() else 0.0
            val roiOffY = if (roi != null && roi.size == 4) roi[1] * src.rows() else 0.0

            val quad = detectPaperQuad(workMat)
            var fallback = "none"

            val resultMat: Mat
            if (quad != null) {
                // 四边形坐标还原到原图尺度
                for (i in 0 until quad.rows()) {
                    val arr = quad.get(i, 0)
                    quad.put(i, 0, arr[0] + roiOffX, arr[1] + roiOffY)
                }
                resultMat = perspectiveCorrect(src, quad)
                quad.release()
            } else {
                // 回落 1：minAreaRect
                val rect = minAreaFallback(workMat)
                if (rect != null) {
                    val arr = Array(4) { Point() }
                    rect.points(arr)
                    // minAreaRect 点序不定，排序为 tl/tr/br/bl
                    val ordered = orderPoints(arr.map {
                        Point(it.x + roiOffX, it.y + roiOffY)
                    })
                    resultMat = perspectiveCorrect(src, ordered)
                    ordered.release()
                    fallback = "minarea"
                } else {
                    // 回落 2：全幅内缩 2%，提示手动校准
                    val m = 0.02
                    val inset = MatOfPoint2f(
                        Point(src.cols() * m, src.rows() * m),
                        Point(src.cols() * (1 - m), src.rows() * m),
                        Point(src.cols() * (1 - m), src.rows() * (1 - m)),
                        Point(src.cols() * m, src.rows() * (1 - m))
                    )
                    resultMat = perspectiveCorrect(src, inset)
                    inset.release()
                    fallback = "fullframe"
                }
            }

            val lit = evenLighting(resultMat)
            outDir.mkdirs()
            val out = File(outDir, "scan_${System.currentTimeMillis()}.jpg")
            val ok = Imgcodecs.imwrite(out.absolutePath, lit)
            src.release(); workMat.release(); resultMat.release(); lit.release()

            if (!ok) return null
            val json = JSONObject()
            json.put("path", out.absolutePath)
            json.put("fallback", fallback)
            json.toString()
        } catch (_: Throwable) {
            null
        }
    }

    /**
     * 纸面四边形检测 v10：
     * 缩放≤1000 → 灰度 → 双边滤波 → Canny 双阈值 → 膨胀 → 轮廓 →
     * approxPolyDP epsilon 扫描 0.02→0.05 → 面积>20% 最大四边形
     */
    private fun detectPaperQuad(src: Mat): MatOfPoint2f? {
        val maxSide = 1000.0
        val scale = maxSide / max(src.cols(), src.rows())
        val small = Mat()
        if (scale < 1.0) {
            Imgproc.resize(src, small, Size(src.cols() * scale, src.rows() * scale))
        } else {
            src.copyTo(small)
        }

        val gray = Mat()
        Imgproc.cvtColor(small, gray, Imgproc.COLOR_BGR2GRAY)

        // 双边滤波：保边去噪
        val filtered = Mat()
        Imgproc.bilateralFilter(gray, filtered, 9, 75.0, 75.0)

        // Canny 双阈值
        val edges = Mat()
        Imgproc.Canny(filtered, edges, 50.0, 150.0)

        // 膨胀连接断边
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
        Imgproc.dilate(edges, edges, kernel)

        val contours = ArrayList<MatOfPoint>()
        val hierarchy = Mat()
        Imgproc.findContours(edges, contours, hierarchy, Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE)

        val frameArea = small.cols().toDouble() * small.rows().toDouble()
        var best: MatOfPoint2f? = null
        var bestArea = 0.0

        // epsilon 扫描：0.02 → 0.05
        var eps = 0.02
        while (eps <= 0.051 && best == null) {
            for (c in contours) {
                val c2f = MatOfPoint2f(*c.toArray())
                val peri = Imgproc.arcLength(c2f, true)
                val approx = MatOfPoint2f()
                Imgproc.approxPolyDP(c2f, approx, eps * peri, true)
                if (approx.rows() != 4) {
                    approx.release(); c2f.release()
                    continue
                }
                val area = Imgproc.contourArea(approx)
                if (area > frameArea * 0.20 && area > bestArea) {
                    best?.release()
                    best = approx
                    bestArea = area
                } else {
                    approx.release()
                }
                c2f.release()
            }
            eps += 0.01
        }

        small.release(); gray.release(); filtered.release(); edges.release()
        hierarchy.release(); kernel.release()
        for (c in contours) c.release()

        val found = best ?: return null
        val invScale = if (scale < 1.0) 1.0 / scale else 1.0
        val pts = found.toArray().map { Point(it.x * invScale, it.y * invScale) }
        found.release()
        return orderPoints(pts)
    }

    /** 回落：最小外接旋转矩形（取最大轮廓） */
    private fun minAreaFallback(src: Mat): org.opencv.core.RotatedRect? {
        val gray = Mat()
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.GaussianBlur(gray, gray, Size(5.0, 5.0), 0.0)
        val thresh = Mat()
        Imgproc.adaptiveThreshold(
            gray, thresh, 255.0,
            Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
            Imgproc.THRESH_BINARY, 25, 15.0
        )
        Core.bitwise_not(thresh, thresh)
        val contours = ArrayList<MatOfPoint>()
        val hierarchy = Mat()
        Imgproc.findContours(thresh, contours, hierarchy, Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE)
        gray.release(); thresh.release(); hierarchy.release()

        val frameArea = src.cols().toDouble() * src.rows().toDouble()
        var bestRect: org.opencv.core.RotatedRect? = null
        var bestArea = 0.0
        for (c in contours) {
            val area = Imgproc.contourArea(c)
            if (area > frameArea * 0.20 && area > bestArea) {
                bestArea = area
                bestRect = Imgproc.minAreaRect(MatOfPoint2f(*c.toArray()))
            }
            c.release()
        }
        return bestRect
    }

    /** 四点排序：左上 → 右上 → 右下 → 左下 */
    private fun orderPoints(pts: List<Point>): MatOfPoint2f {
        val sum = pts.map { it.x + it.y }
        val diff = pts.map { it.y - it.x }
        val tl = pts[sum.indexOf(sum.min())]
        val br = pts[sum.indexOf(sum.max())]
        val tr = pts[diff.indexOf(diff.min())]
        val bl = pts[diff.indexOf(diff.max())]
        return MatOfPoint2f(tl, tr, br, bl)
    }

    private fun List<Double>.min(): Double = this.minByOrNull { it } ?: 0.0
    private fun List<Double>.max(): Double = this.maxByOrNull { it } ?: 0.0

    /** 透视拉正 */
    private fun perspectiveCorrect(src: Mat, quad: MatOfPoint2f): Mat {
        val pts = quad.toArray()
        val tl = pts[0]; val tr = pts[1]; val br = pts[2]; val bl = pts[3]

        val widthTop = dist(tl, tr); val widthBottom = dist(bl, br)
        val heightLeft = dist(tl, bl); val heightRight = dist(tr, br)
        val w = max(widthTop, widthBottom).toInt().coerceAtLeast(100)
        val h = max(heightLeft, heightRight).toInt().coerceAtLeast(100)

        val dst = MatOfPoint2f(
            Point(0.0, 0.0), Point(w - 1.0, 0.0),
            Point(w - 1.0, h - 1.0), Point(0.0, h - 1.0)
        )
        val m = Imgproc.getPerspectiveTransform(quad, dst)
        val warped = Mat()
        Imgproc.warpPerspective(src, warped, m, Size(w.toDouble(), h.toDouble()))
        m.release(); dst.release()
        return warped
    }

    private fun dist(a: Point, b: Point): Double {
        val dx = a.x - b.x; val dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }

    /** 匀光：除以大核高斯背景（去阴影/光照不均），再归一化 */
    private fun evenLighting(src: Mat): Mat {
        val gray = Mat()
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)

        val bg = Mat()
        Imgproc.GaussianBlur(gray, bg, Size(0.0, 0.0), 50.0)

        val divided = Mat()
        Core.divide(gray, bg, divided, 255.0)

        val result = Mat()
        Core.normalize(divided, result, 40.0, 255.0, Core.NORM_MINMAX)

        val out = Mat()
        Imgproc.cvtColor(result, out, Imgproc.COLOR_GRAY2BGR)

        gray.release(); bg.release(); divided.release(); result.release()
        return out
    }

    /** 手动四角裁剪（归一化坐标 0-1） */
    fun cropByNormalizedPoints(
        srcPath: String,
        outDir: File,
        ntl: DoubleArray, ntr: DoubleArray, nbr: DoubleArray, nbl: DoubleArray
    ): String? {
        if (!opencvReady()) return null
        return try {
            val src = Imgcodecs.imread(srcPath)
            if (src.empty()) return null
            val w = src.cols().toDouble(); val h = src.rows().toDouble()
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
            if (ok) out.absolutePath else null
        } catch (_: Throwable) {
            null
        }
    }

    /** 旋转 90° */
    fun rotate90(srcPath: String, outDir: File): String? {
        return try {
            val bmp = BitmapFactory.decodeFile(srcPath) ?: return null
            val matrix = android.graphics.Matrix().apply { postRotate(90f) }
            val rotated = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, matrix, true)
            outDir.mkdirs()
            val out = File(outDir, "rot_${System.currentTimeMillis()}.jpg")
            FileOutputStream(out).use {
                rotated.compress(Bitmap.CompressFormat.JPEG, 92, it)
            }
            bmp.recycle(); rotated.recycle()
            out.absolutePath
        } catch (_: Throwable) {
            null
        }
    }
}
