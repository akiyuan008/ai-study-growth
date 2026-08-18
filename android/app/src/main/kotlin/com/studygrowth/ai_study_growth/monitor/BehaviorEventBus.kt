package com.studygrowth.ai_study_growth.monitor

import android.content.Context
import java.io.File

/**
 * 行为事件总线 —— 「Kotlin 产事实」的落盘层。
 *
 * 所有事件先写 JSONL 文件，再推给 Dart；Dart 确认消费后清空。
 * 服务被杀重启时，未确认事件重放，一条事实不丢。
 */
object BehaviorEventBus {
    private const val FILE_NAME = "behavior_events.jsonl"

    private var file: File? = null
    private val listeners = mutableListOf<(String) -> Unit>()

    fun init(context: Context) {
        if (file == null) {
            file = File(context.filesDir, FILE_NAME)
        }
    }

    /** 追加一条事件：先落盘，再广播给实时监听者 */
    @Synchronized
    fun append(eventJson: String) {
        val f = file ?: return
        try {
            f.appendText(eventJson + "\n")
        } catch (_: Exception) {
            // 落盘失败时仍然尝试实时推送，尽力而为
        }
        for (l in listeners.toList()) {
            try {
                l(eventJson)
            } catch (_: Exception) {
            }
        }
    }

    /** 未确认的全部事件（重启用） */
    @Synchronized
    fun pending(): List<String> {
        val f = file ?: return emptyList()
        return try {
            f.readLines().filter { it.isNotBlank() }
        } catch (_: Exception) {
            emptyList()
        }
    }

    /** Dart 确认消费后清空积压 */
    @Synchronized
    fun ackAll() {
        val f = file ?: return
        try {
            f.writeText("")
        } catch (_: Exception) {
        }
    }

    @Synchronized
    fun register(listener: (String) -> Unit) {
        listeners.add(listener)
    }

    @Synchronized
    fun unregister(listener: (String) -> Unit) {
        listeners.remove(listener)
    }
}
