package com.studygrowth.ai_study_growth.monitor

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * 锁屏遮罩 —— 深度干预（LEVEL 2/3）。
 *
 * 由 DisciplineEngine 判定持续分心后经服务拉起，盖住前台应用，
 * 给用户一个明确的「回到专注」出口。显示/离开都会产出事实事件。
 */
class LockScreenActivity : Activity() {

    companion object {
        const val EXTRA_MESSAGE = "message"

        fun show(context: Context, message: String?) {
            val intent = Intent(context, LockScreenActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (message != null) intent.putExtra(EXTRA_MESSAGE, message)
            context.startActivity(intent)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        BehaviorEventBus.append(
            "{\"eventType\":\"lock_shown\",\"at\":${System.currentTimeMillis()}}"
        )

        val message = intent.getStringExtra(EXTRA_MESSAGE)
            ?: "你已经离开专注一段时间了，回来吧。"

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF12151C.toInt())
            setPadding(96, 96, 96, 96)
        }

        val title = TextView(this).apply {
            text = "MOSS 伴读"
            textSize = 16f
            setTextColor(0x88FFFFFF.toInt())
            gravity = Gravity.CENTER
        }

        val body = TextView(this).apply {
            text = message
            textSize = 24f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 48, 0, 96)
        }

        val back = Button(this).apply {
            text = "回到专注"
            textSize = 18f
            setOnClickListener {
                BehaviorEventBus.append(
                    "{\"eventType\":\"lock_dismissed\",\"at\":${System.currentTimeMillis()}}"
                )
                finish()
            }
        }

        root.addView(title)
        root.addView(body)
        root.addView(back)
        setContentView(root)
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // 锁屏遮罩不允许直接返回键绕过
        BehaviorEventBus.append(
            "{\"eventType\":\"lock_blocked_back\",\"at\":${System.currentTimeMillis()}}"
        )
    }
}
