package com.example.panel_app

import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.zip.GZIPInputStream

/**
 * Simple HTTP client that talks directly to the Ninja Sage
 * AMF backend using the minimal AMF3 encoder/decoder in [Amf3].
 *
 * This reproduces the behaviour of the Python NinjaSageClient
 * + amf_utils.build_envelope for a single request.
 */
class NinjaSageAmfClient(
    private val baseUrl: String = "https://play.ninjasage.id",
    private val endpointPath: String = "/amf",
) {

    fun invoke(
        target: String,
        body: List<Any?>,
    ): Map<String, Any?> {
        val message = Amf3.ActionMessage(
            version = 3,
            bodies = listOf(
                Amf3.MessageBody(
                    targetURI = target,
                    responseURI = "/1",
                    data = body,
                ),
            ),
        )

        val serializer = Amf3.Serializer()
        val payload = serializer.writeMessage(message)

        val responseBytes = sendRequest(payload)
        val firstBody = Amf3.decodeFirstBody(responseBytes)
            ?: return emptyMap()

        return normalizeContent(firstBody.data)
    }

    private fun sendRequest(payload: ByteArray): ByteArray {
        val url = URL(baseUrl.trimEnd('/') + endpointPath)
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            doOutput = true
            connectTimeout = 20000
            readTimeout = 20000

            setRequestProperty("Content-Type", "application/x-amf")
            setRequestProperty("Referer", "app:/NinjaSage.swf")
            setRequestProperty(
                "Accept",
                "text/xml, application/xml, application/xhtml+xml, text/html;q=0.9, text/plain;q=0.8, " +
                    "text/css, image/png, image/jpeg, image/gif;q=0.8, application/x-shockwave-flash, " +
                    "video/mp4;q=0.9, flv-application/octet-stream;q=0.8, video/x-flv;q=0.7, audio/mp4, " +
                    "application/futuresplash, */*;q=0.5, application/x-mpegURL",
            )
            setRequestProperty("x-flash-version", "51,1,3,10")
            setRequestProperty(
                "User-Agent",
                "Mozilla/5.0 (Windows; U; en) AppleWebKit/533.19.4 (KHTML, like Gecko) AdobeAIR/51.1",
            )
            setRequestProperty("Accept-Encoding", "gzip,deflate")
            setRequestProperty("Connection", "keep-alive")
        }

        conn.outputStream.use { out ->
            out.write(payload)
            out.flush()
        }

        val code = conn.responseCode
        val stream: InputStream = if (code in 200..299) {
            conn.inputStream
        } else {
            conn.errorStream ?: conn.inputStream
        }

        val encoding = (conn.getHeaderField("Content-Encoding") ?: "").lowercase()
        val rawStream = when {
            encoding.contains("gzip") -> GZIPInputStream(stream)
            else -> stream
        }

        return rawStream.use { readAll(it) }
    }

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

    /**
     * Rough port of response_utils.normalize_content from Python:
     * - If content is Map -> returned as-is
     * - If content is List -> {"status": firstElement}
     * - Otherwise -> {"status": scalar}
     */
    @Suppress("UNCHECKED_CAST")
    private fun normalizeContent(content: Any?): Map<String, Any?> {
        if (content == null) return emptyMap()

        if (content is Map<*, *>) {
            val result = mutableMapOf<String, Any?>()
            for ((k, v) in content) {
                val key = k?.toString() ?: continue
                result[key] = v
            }
            return result
        }

        if (content is List<*>) {
            val status = content.firstOrNull()
            return mapOf("status" to status)
        }

        return mapOf("status" to content)
    }
}

