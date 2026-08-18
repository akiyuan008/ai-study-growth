package com.studygrowth.ai_study_growth.monitor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * 文档扫描器（Part 2 核心）—— Kotlin 产事实。
 *
 * 页面级四边形检测：背景混入杂物时，只要纸面在画面内，
 * 自动提取纸面 → 透视拉正 → 匀光，产出"扫描件"。
 * 任何环节失败返回 null，Dart 侧回落原图 + 手动裁剪，不阻塞。
 */
object DocumentScanner {

    init {
        try {
            System.loadLibrary(Core.NATIVE_LIBRARY_NAME)
        } catch (_: Throwable) {
            // OpenCV 加载失败时所有方法安全降级为 null
        }
    }

    private fun opencvReady(): Boolean = try {
        Core.VERSION.isNotEmpty()
    } catch (_: Throwable) {
        false
    }

    /**
     * 扫描入口：输入原图路径，输出扫描件路径；失败返回 null。
     */
    fun scan(srcPath: String, outDir: File): String? {
        if (!opencvReady()) return null
        return try {
            val src = Imgcodecs.imread(srcPath)
            if (src.empty()) return null

            val quad = detectPaperQuad(src) ?: return null
            val warped = perspectiveCorrect(src, quad)
            val lit = evenLighting(warped)

            outDir.mkdirs()
            val out = File(outDir, "scan_${System.currentTimeMillis()}.jpg")
            val ok = Imgcodecs.imwrite(out.absolutePath, lit)
            src.release(); warped.release(); lit.release()
            if (ok) out.absolutePath else null
        } catch (_: Throwable) {
            null
        }
    }

    /**
     * 纸面四边形检测：灰度 → 模糊 → 自适应阈值 → 轮廓 → 最大四点近似轮廓。
     */
    private fun detectPaperQuad(src: Mat): MatOfPoint2f? {
        val scale = 1000.0 / max(src.cols(), src.rows())
        val small = Mat()
        if (scale < 1.0) {
            Imgproc.resize(
                src, small,
                Size(src.cols() * scale, src.rows() * scale)
            )
        } else {
            src.copyTo(small)
        }

        val gray = Mat()
        Imgproc.cvtColor(small, gray, Imgproc.COLOR_BGR2GRAY)
        Imgproc.GaussianBlur(gray, gray, Size(7.0, 7.0), 0.0)

        val thresh = Mat()
        Imgproc.adaptiveThreshold(
            gray, thresh, 255.0,
            Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
            Imgproc.THRESH_BINARY, 25, 15.0
        )
        // 纸面是亮区：反相后闭运算连通
        Core.bitwise_not(thresh, thresh)
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(5.0, 5.0))
        Imgproc.morphologyEx(thresh, thresh, Imgproc.MORPH_CLOSE, kernel)

        val contours = ArrayList<MatOfPoint>()
        val hierarchy = Mat()
        Imgproc.findContours(
            thresh, contours, hierarchy,
            Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE
        )

        val frameArea = small.cols().toDouble() * small.rows().toDouble()
        var best: MatOfPoint2f? = null
        var bestArea = 0.0

        for (c in contours) {
            val c2f = MatOfPoint2f(*c.toArray())
            val peri = Imgproc.arcLength(c2f, true)
            val approx = MatOfPoint2f()
            Imgproc.approxPolyDP(c2f, approx, 0.02 * peri, true)
            if (approx.rows() != 4) continue
            val area = Imgproc.contourArea(approx)
            // 纸面至少占画面 15%
            if (area < frameArea * 0.15) continue
            if (area > bestArea) {
                bestArea = area
                best = approx
            }
        }

        small.release(); gray.release(); thresh.release(); hierarchy.release()
        kernel.release()
        for (c in contours) c.release()

        val found = best ?: return null
        // 还原到原图尺度
        val pts = found.toArray().map { Point(it.x / scale, it.y / scale) }
        found.release()
        return orderPoints(pts)
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

        // 输出三通道（与下游管线一致）
        val out = Mat()
        Imgproc.cvtColor(result, out, Imgproc.COLOR_GRAY2BGR)

        gray.release(); bg.release(); divided.release(); result.release()
        return out
    }

    /**
     * 手动裁剪辅助：按用户给定的四角（归一化 0-1 坐标）透视拉正。
     * 编辑屏拖拽裁剪框后调用；失败返回 null。
     */
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
            src.release(); warped.release()
            if (ok) out.absolutePath else null
        } catch (_: Throwable) {
            null
        }
    }

    /** 旋转 90°（编辑屏手动旋转） */
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
