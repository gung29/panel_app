package com.example.panel_app

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.Deflater

/**
 * Port of contoh/ninja_sage/analytics_payload.py to Kotlin.
 *
 * Builds the compressed JSON payload required by Analytics.libraries.
 */
object AnalyticsPayload {

    private const val DEFAULT_ASSET_BASE_URL =
        "https://ns-assets.ninjasage.id/static/lib/"

    private val ASSET_NAMES = listOf(
        "skills",
        "library",
        "enemy",
        "npc",
        "pet",
        "mission",
        "gamedata",
        "talents",
        "senjutsu",
        "skill-effect",
        "weapon-effect",
        "back_item-effect",
        "accessory-effect",
        "arena-effect",
        "animation",
    )

    private val EXPECTED_ORDER = listOf(
        "weapon-effect",
        "library",
        "animation",
        "pet",
        "back_item-effect",
        "gamedata",
        "accessory-effect",
        "skills",
        "npc",
        "arena-effect",
        "talents",
        "enemy",
        "skill-effect",
        "senjutsu",
        "mission",
    )

    @Volatile
    private var cachedLengths: Map<String, Int>? = null

    private fun readAll(input: InputStream): ByteArray {
        val buffer = ByteArray(8 * 1024)
        val out = ByteArrayOutputStream()
        var read: Int
        while (true) {
            read = input.read(buffer)
            if (read <= 0) break
            out.write(buffer, 0, read)
        }
        return out.toByteArray()
    }

    private fun download(url: String): ByteArray {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = "GET"
        conn.connectTimeout = 20000
        conn.readTimeout = 20000
        return conn.inputStream.use { readAll(it) }
    }

    private fun fetchAssetLengths(
        baseUrl: String = DEFAULT_ASSET_BASE_URL,
    ): Map<String, Int> {
        cachedLengths?.let { return it }

        val base = baseUrl.trimEnd('/')
        val lengths = mutableMapOf<String, Int>()
        for (name in ASSET_NAMES) {
            val data = download("$base/$name.bin")
            lengths[name] = data.size
        }
        cachedLengths = lengths
        return lengths
    }

    fun buildAnalyticsPayload(
        baseUrl: String = DEFAULT_ASSET_BASE_URL,
    ): ByteArray {
        val lengths = fetchAssetLengths(baseUrl)
        val sb = StringBuilder()
        sb.append('{')
        var first = true
        for (key in EXPECTED_ORDER) {
            val len = lengths[key] ?: continue
            if (!first) {
                sb.append(',')
            }
            first = false
            sb.append('"').append(key).append('"').append(':').append(len)
        }
        sb.append('}')
        val jsonBytes = sb.toString().toByteArray(Charsets.UTF_8)

        // zlib/DEFLATE compression with maximum level (similar to Python level=9).
        val deflater = Deflater(Deflater.BEST_COMPRESSION)
        deflater.setInput(jsonBytes)
        deflater.finish()

        val out = ByteArrayOutputStream()
        val buffer = ByteArray(1024)
        while (!deflater.finished()) {
            val count = deflater.deflate(buffer)
            out.write(buffer, 0, count)
        }
        deflater.end()
        return out.toByteArray()
    }
}

