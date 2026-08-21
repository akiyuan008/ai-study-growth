package com.studygrowth.ai_study_growth.monitor

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Rect
import org.json.JSONObject
import org.opencv.core.Core
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.CLAHE
import org.opencv.imgproc.Imgproc
import java.io.File
import java.io.FileOutputStream
import kotlin.math.max
import kotlin.math.sqrt

/**
 * 文档扫描器 v14 —— 管线解耦：
 *
 * - 裁剪 / 四边形透视拉正（Matrix.setPolyToPoly）/ 旋转：
 *   全部用 android.graphics 实现，不依赖 OpenCV，OpenCV 未加载也全可用。
 * - OpenCV 仅负责：自动纸面检测 + 高级增强（背景压平 + CLAHE）。
 * - OpenCV 未加载时：自动检测返回 fallback 标志（Dart 侧显示
 *   「自动校准不可用，已为你保留手动调整」），增强走 Bitmap 基础引擎。
 *
 * 启动时 System.loadLibrary + 1x1 Mat 自测，结果可通过 getStatus 查询。
 */
object DocumentScanner {

    private var opencvLoaded = false
    private var opencvVersion = ""
    private var loadError = ""

    init {
        try {
            System.loadLibrary(Core.NATIVE_LIBRARY_NAME)
            // 自测：1x1 Mat 运算验证 JNI 真实可用
            val probe = Mat(1, 1, CvType.CV_8UC1)
            probe.put(0, 0, byteArrayOf(7))
            val v = probe.get(0, 0)[0].toInt()
            probe.release()
            if (v == 7) {
                opencvLoaded = true
                opencvVersion = Core.VERSION
            } else {
                loadError = "自测失败：Mat 读写不一致"
            }
        } catch (t: Throwable) {
            loadError = t.javaClass.simpleName
        }
    }

    /** 引擎状态 JSON：供设置页展示「增强引擎：已加载/未加载」 */
    fun getStatus(): String {
        val json = JSONObject()
        json.put("loaded", opencvLoaded)
        json.put("version", opencvVersion)
        json.put("error", loadError)
        return json.toString()
    }

    /** 兼容旧通道名 */
    fun getVersion(): String =
        if (opencvLoaded) opencvVersion else "unavailable"

    // ============================================================
    // 几何管线（android.graphics，零 OpenCV 依赖）
    // ============================================================

    /** 手动四角裁剪 + 透视拉正（归一化坐标 0-1，tl/tr/br/bl）。
     * 返回 JSON：{"status":"success","path":...} 或 {"status":"error","error":人话原因}
     * 失败不静默、不死循环：透视失败回落包围盒矩形裁剪。 */
    fun cropByNormalizedPoints(
        srcPath: String,
        outDir: File,
        ntl: DoubleArray, ntr: DoubleArray, nbr: DoubleArray, nbl: DoubleArray
    ): String {
        fun clamp(v: Double): Double = v.coerceIn(0.0, 1.0)
        fun err(msg: String): String {
            val json = JSONObject()
            json.put("status", "error")
            json.put("error", msg)
            return json.toString()
        }
        fun ok(path: String): String {
            val json = JSONObject()
            json.put("status", "success")
            json.put("path", path)
            return json.toString()
        }
        return try {
            val src = BitmapFactory.decodeFile(srcPath) ?: return err("图片读取失败，请重新拍摄")
            val w = src.width; val h = src.height

            val tl = floatArrayOf((clamp(ntl[0]) * w).toFloat(), (clamp(ntl[1]) * h).toFloat())
            val tr = floatArrayOf((clamp(ntr[0]) * w).toFloat(), (clamp(ntr[1]) * h).toFloat())
            val br = floatArrayOf((clamp(nbr[0]) * w).toFloat(), (clamp(nbr[1]) * h).toFloat())
            val bl = floatArrayOf((clamp(nbl[0]) * w).toFloat(), (clamp(nbl[1]) * h).toFloat())

            var out = perspectiveCorrect(src, floatArrayOf(
                tl[0], tl[1], tr[0], tr[1], br[0], br[1], bl[0], bl[1]
            ))
            if (out == null) {
                // 回落：包围盒矩形裁剪（禁死循环）
                val xs = listOf(tl[0], tr[0], br[0], bl[0])
                val ys = listOf(tl[1], tr[1], br[1], bl[1])
                val x = xs.min().toInt().coerceIn(0, w - 1)
                val y = ys.min().toInt().coerceIn(0, h - 1)
                val rw = (xs.max().toInt() - x).coerceAtLeast(1).coerceAtMost(w - x)
                val rh = (ys.max().toInt() - y).coerceAtLeast(1).coerceAtMost(h - y)
                out = Bitmap.createBitmap(src, x, y, rw, rh)
            }
            src.recycle()
            outDir.mkdirs()
            val file = File(outDir, "crop_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use {
                out.compress(Bitmap.CompressFormat.JPEG, 92, it)
            }
            out.recycle()
            ok(file.absolutePath)
        } catch (_: Throwable) {
            err("裁剪没成功，请调整裁剪框再试")
        }
    }

    /** 透视拉正：Matrix.setPolyToPoly（纯 android.graphics） */
    private fun perspectiveCorrect(src: Bitmap, srcPts: FloatArray): Bitmap? {
        return try {
            // 目标尺寸：取对边距离较大者
            fun dist(x1: Float, y1: Float, x2: Float, y2: Float): Float {
                val dx = x1 - x2; val dy = y1 - y2
                return sqrt(dx * dx + dy * dy)
            }
            val wTop = dist(srcPts[0], srcPts[1], srcPts[2], srcPts[3])
            val wBot = dist(srcPts[6], srcPts[7], srcPts[4], srcPts[5])
            val hLeft = dist(srcPts[0], srcPts[1], srcPts[6], srcPts[7])
            val hRight = dist(srcPts[2], srcPts[3], srcPts[4], srcPts[5])
            val w = max(wTop, wBot).toInt().coerceAtLeast(64)
            val h = max(hLeft, hRight).toInt().coerceAtLeast(64)

            val dst = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(dst)
            val matrix = Matrix()
            val dstPts = floatArrayOf(
                0f, 0f, w.toFloat(), 0f,
                w.toFloat(), h.toFloat(), 0f, h.toFloat()
            )
            matrix.setPolyToPoly(srcPts, 0, dstPts, 0, 4)
            canvas.drawBitmap(src, matrix, Paint(Paint.FILTER_BITMAP_FLAG))
            dst
        } catch (_: Throwable) {
            null
        }
    }

    /** 旋转 90°（纯 android.graphics） */
    fun rotate90(srcPath: String, outDir: File): String? {
        return try {
            val bmp = BitmapFactory.decodeFile(srcPath) ?: return null
            val matrix = Matrix().apply { postRotate(90f) }
            val rotated = Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, matrix, true)
            outDir.mkdirs()
            val out = File(outDir, "rot_${System.currentTimeMillis()}.jpg")
            FileOutputStream(out).use {
                rotated.compress(Bitmap.CompressFormat.JPEG, 92, it)
            }
            bmp.recycle()
            if (rotated !== bmp) rotated.recycle()
            out.absolutePath
        } catch (_: Throwable) {
            null
        }
    }

    // ============================================================
    // 自动纸面检测（仅 OpenCV；未加载 → fallback=fullframe）
    // ============================================================

    /**
     * 自动扫描：检测到纸面→透视拉正+匀光；
     * 未检测到/未加载 OpenCV → 全幅内缩 2% + fallback 标志（禁静默）。
     * 返回 JSON：{"path":..., "fallback":"none|minarea|fullframe|noengine"}
     */
    fun scan(srcPath: String, outDir: File, roi: DoubleArray?): String? {
        val src = BitmapFactory.decodeFile(srcPath) ?: return null
        val w = src.width; val h = src.height

        fun finish(bitmap: Bitmap, fallback: String): String {
            outDir.mkdirs()
            val file = File(outDir, "scan_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 92, it)
            }
            val json = JSONObject()
            json.put("path", file.absolutePath)
            json.put("fallback", fallback)
            return json.toString()
        }

        if (!opencvLoaded) {
            // 无引擎：全幅内缩 2%，人话提示由 Dart 侧给出
            val inset = insetCrop(src, 0.02)
            src.recycle()
            return finish(inset, "noengine")
        }

        return try {
            val mat = Imgcodecs.imread(srcPath)
            if (mat.empty()) {
                src.recycle()
                return finish(insetCrop(src, 0.02), "fullframe")
            }

            val quad = detectPaperQuad(mat, roi)
            mat.release()

            if (quad == null) {
                val inset = insetCrop(src, 0.02)
                src.recycle()
                return finish(inset, "fullframe")
            }

            // OpenCV 四边形 → graphics 透视拉正（解耦）
            val arr = quad.toArray()
            quad.release()
            val ordered = orderPoints(arr.map { Point(it.x, it.y) })
            val pts = ordered.toArray()
            ordered.release()
            val srcPts = FloatArray(8)
            for (i in 0..3) {
                srcPts[i * 2] = pts[i].x.toFloat()
                srcPts[i * 2 + 1] = pts[i].y.toFloat()
            }
            src.recycle()
            val corrected = perspectiveCorrectBitmap(srcPath, srcPts)
                ?: return finish(insetCrop(BitmapFactory.decodeFile(srcPath) ?: return null, 0.02), "fullframe")
            finish(corrected, "none")
        } catch (_: Throwable) {
            val inset = insetCrop(src, 0.02)
            src.recycle()
            finish(inset, "fullframe")
        }
    }

    /** 全幅内缩裁剪 */
    private fun insetCrop(src: Bitmap, ratio: Double): Bitmap {
        val x = (src.width * ratio).toInt()
        val y = (src.height * ratio).toInt()
        return Bitmap.createBitmap(
            src, x, y,
            (src.width - 2 * x).coerceAtLeast(1),
            (src.height - 2 * y).coerceAtLeast(1)
        )
    }

    /** OpenCV 四边形检测（缩放≤1000→双边滤波→Canny→膨胀→epsilon 扫描 0.02→0.05） */
    private fun detectPaperQuad(src: Mat, roi: DoubleArray?): MatOfPoint2f? {
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
        val filtered = Mat()
        Imgproc.bilateralFilter(gray, filtered, 9, 75.0, 75.0)
        val edges = Mat()
        Imgproc.Canny(filtered, edges, 50.0, 150.0)
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
        Imgproc.dilate(edges, edges, kernel)

        val contours = ArrayList<MatOfPoint>()
        val hierarchy = Mat()
        Imgproc.findContours(edges, contours, hierarchy, Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE)

        val frameArea = small.cols().toDouble() * small.rows().toDouble()
        var best: MatOfPoint2f? = null
        var bestArea = 0.0

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

    /** OpenCV Mat 直接透视（检测路径专用） */
    private fun perspectiveCorrectBitmap(srcPath: String, srcPts: FloatArray): Bitmap? {
        val src = BitmapFactory.decodeFile(srcPath) ?: return null
        val out = perspectiveCorrect(src, srcPts)
        src.recycle()
        return out
    }

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

    // ============================================================
    // 增强双引擎（都产出"扫描白"）
    // ============================================================

    /**
     * 增强入口：OpenCV 在→背景压平+CLAHE；不在→Bitmap 直方图拉伸+白平衡。
     * 返回增强图路径；失败返回 null（Dart 侧保留原图）。
     */
    fun enhance(srcPath: String, outDir: File): String? {
        return if (opencvLoaded) {
            enhanceOpenCv(srcPath, outDir) ?: enhanceBasic(srcPath, outDir)
        } else {
            enhanceBasic(srcPath, outDir)
        }
    }

    /** OpenCV 引擎（扫描王"魔术色"式）：
     *  逐通道背景估计→光照压平（纸面变白）→提亮+加对比（文字突显），保留彩色 */
    private fun enhanceOpenCv(srcPath: String, outDir: File): String? {
        return try {
            val src = Imgcodecs.imread(srcPath)
            if (src.empty()) return null

            // 逐通道压平：每通道 ÷ 自身大核高斯背景 × 255
            val channels = ArrayList<Mat>()
            Core.split(src, channels)
            for (i in channels.indices) {
                val bg = Mat()
                Imgproc.GaussianBlur(channels[i], bg, Size(0.0, 0.0), 50.0)
                val flat = Mat()
                Core.divide(channels[i], bg, flat, 255.0)
                channels[i].release()
                channels[i] = flat
                bg.release()
            }
            val flatBgr = Mat()
            Core.merge(channels, flatBgr)

            // 提亮 + 加对比：out = 1.16*x + 6（纸面推向白，笔画推向黑）
            val out = Mat()
            flatBgr.convertTo(out, -1, 1.16, 6.0)

            outDir.mkdirs()
            val file = File(outDir, "enh_${System.currentTimeMillis()}.jpg")
            val ok = Imgcodecs.imwrite(
                file.absolutePath, out,
                intArrayOf(Imgcodecs.IMWRITE_JPEG_QUALITY, 92)
            )
            src.release(); flatBgr.release(); out.release()
            for (c in channels) c.release()
            if (ok) file.absolutePath else null
        } catch (_: Throwable) {
            null
        }
    }

    /** Bitmap 基础引擎：直方图拉伸 + ColorMatrix 白平衡（无 OpenCV 兜底） */
    private fun enhanceBasic(srcPath: String, outDir: File): String? {
        return try {
            val src = BitmapFactory.decodeFile(srcPath) ?: return null
            val w = src.width; val h = src.height

            // 采样统计亮度分位数（2%/98%）与亮区均值（白平衡）
            val step = max(1, (w * h) / 40000)
            val luma = ArrayList<Int>(40000)
            var rSum = 0L; var gSum = 0L; var bSum = 0L; var brightN = 0L
            var i = 0
            while (i < w * h) {
                val px = src.getPixel(i % w, i / w)
                val r = (px shr 16) and 0xFF
                val g = (px shr 8) and 0xFF
                val b = px and 0xFF
                val y = (0.299 * r + 0.587 * g + 0.114 * b).toInt()
                luma.add(y)
                if (y > 160) {
                    rSum += r; gSum += g; bSum += b; brightN++
                }
                i += step
            }
            luma.sort()
            val lo = luma[(luma.size * 0.01).toInt().coerceAtMost(luma.size - 1)]
            val hi = luma[(luma.size * 0.99).toInt().coerceAtMost(luma.size - 1)].coerceAtLeast(lo + 20)

            // 对比拉伸系数 + 亮度提升（纸面推向白，笔画推向黑）
            val scale = 255f / (hi - lo)
            val brightnessLift = 12f

            // 白平衡增益（亮区均值 → 中性灰）
            var rGain = 1f; var gGain = 1f; var bGain = 1f
            if (brightN > 100) {
                val rAvg = rSum / brightN.toFloat()
                val gAvg = gSum / brightN.toFloat()
                val bAvg = bSum / brightN.toFloat()
                val target = max(rAvg, max(gAvg, bAvg)).coerceAtLeast(1f)
                rGain = (target / rAvg).coerceIn(0.85f, 1.2f)
                gGain = (target / gAvg).coerceIn(0.85f, 1.2f)
                bGain = (target / bAvg).coerceIn(0.85f, 1.2f)
            }

            val cm = ColorMatrix(floatArrayOf(
                scale * rGain, 0f, 0f, 0f, -lo * scale * rGain + brightnessLift,
                0f, scale * gGain, 0f, 0f, -lo * scale * gGain + brightnessLift,
                0f, 0f, scale * bGain, 0f, -lo * scale * bGain + brightnessLift,
                0f, 0f, 0f, 1f, 0f
            ))
            val paint = Paint().apply { colorFilter = ColorMatrixColorFilter(cm) }
            val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
            Canvas(out).drawBitmap(src, 0f, 0f, paint)

            outDir.mkdirs()
            val file = File(outDir, "enh_${System.currentTimeMillis()}.jpg")
            FileOutputStream(file).use {
                out.compress(Bitmap.CompressFormat.JPEG, 92, it)
            }
            src.recycle(); out.recycle()
            file.absolutePath
        } catch (_: Throwable) {
            null
        }
    }
}
