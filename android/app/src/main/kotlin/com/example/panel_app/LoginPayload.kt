package com.example.panel_app

import android.util.Base64
import org.json.JSONArray
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.util.zip.InflaterInputStream
import javax.crypto.Cipher
import javax.crypto.spec.IvParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Port of contoh/ninja_sage/login_payload.py to Kotlin.
 *
 * This module rebuilds SystemLogin.loginUser parameters from
 * username/password, character_seed and character_key.
 */

data class LoaderInfo(
    val bytesLoaded: Int = 8_216_461,
    val bytesTotal: Int = 8_216_461,
)

object LoginPayload {

    private const val DEFAULT_LIBRARY_URL =
        "https://ns-assets.ninjasage.id/static/lib/library.bin"

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

    private class Crypt {
        companion object {
            private fun makeIv(seed: String): ByteArray {
                val iv = seed.toByteArray(Charsets.ISO_8859_1)
                val blockSize = 16
                val padLen = blockSize - (iv.size % blockSize)
                val padded = ByteArray(iv.size + padLen)
                System.arraycopy(iv, 0, padded, 0, iv.size)
                for (i in iv.size until padded.size) {
                    padded[i] = padLen.toByte()
                }
                return padded.copyOf(blockSize)
            }

            fun encrypt(
                plaintext: String,
                key: String,
                seed: Int,
            ): String {
                val aesKey = key.toByteArray(Charsets.ISO_8859_1)
                val iv = makeIv(seed.toString())
                val secretKey = SecretKeySpec(aesKey, "AES")
                val cipher = Cipher.getInstance("AES/CBC/PKCS5Padding")
                cipher.init(
                    Cipher.ENCRYPT_MODE,
                    secretKey,
                    IvParameterSpec(iv),
                )
                val data = plaintext.toByteArray(Charsets.ISO_8859_1)
                val ciphertext = cipher.doFinal(data)
                return Base64.encodeToString(ciphertext, Base64.NO_WRAP)
            }
        }
    }

    private class PMPrng(seed: Int) {
        private val mod = 2_147_483_647
        private val mul = 16_807
        private var value: Int

        init {
            var s = seed
            if (s == 0) {
                val t = System.currentTimeMillis()
                val r = (Math.random() * 0.025 * 0x7FFFFFFF).toInt()
                s = ((t.toLong() xor r.toLong()) and 0x7FFFFFFF).toInt()
            }
            value = s and 0x7FFFFFFF
        }

        fun nextInt(): Int {
            value = ((value.toLong() * mul) % mod).toInt()
            return value
        }
    }

    @Volatile
    private var cachedLevels: Map<String, Int>? = null

    private fun loadLibraryLevels(
        libraryUrl: String = DEFAULT_LIBRARY_URL,
    ): Map<String, Int> {
        cachedLevels?.let { return it }

        val conn = URL(libraryUrl).openConnection() as HttpURLConnection
        conn.requestMethod = "GET"
        conn.connectTimeout = 20000
        conn.readTimeout = 20000
        val compressed = conn.inputStream.use { readAll(it) }

        val inflater = InflaterInputStream(ByteArrayInputStream(compressed))
        val decompressed = inflater.use { readAll(it) }
        val text = String(decompressed, Charsets.UTF_8)

        val items = JSONArray(text)
        val levels = mutableMapOf<String, Int>()
        for (i in 0 until items.length()) {
            val obj = items.getJSONObject(i)
            val id = obj.optString("id", null) ?: continue
            val level = obj.optInt("level", 0)
            levels[id] = level
        }

        cachedLevels = levels
        return levels
    }

    private fun cucsgHash(value: String): String {
        val payload = ByteArray(value.length) { index ->
            (value[index].code and 0xFF).toByte()
        }
        val digest = MessageDigest.getInstance("SHA-256").digest(payload)
        val sb = StringBuilder()
        for (b in digest) {
            sb.append(String.format("%02x", b))
        }
        return sb.toString()
    }

    private fun safeMod(a: Int, b: Int): Int {
        return if (b == 0) 0 else a % b
    }

    private fun getSpecificItem(
        loader: LoaderInfo,
        characterSeed: Int,
        levels: Map<String, Int>,
    ): String {
        val bytesTotal = loader.bytesTotal
        val bytesLoaded = loader.bytesLoaded
        val lvlHair1 = levels["hair_10000_1"] ?: 0
        val lvlHair0 = levels["hair_10000_0"] ?: 0
        val lvlAcc2003 = levels["accessory_2003"] ?: 0

        val loc4Num =
            (bytesTotal xor bytesLoaded) +
                1337 xor characterSeed xor 1337 +
                1337 xor characterSeed xor 1337 +
                1337 xor 0x0539 and
                safeMod(safeMod(bytesLoaded, lvlHair1), bytesLoaded) and
                bytesTotal xor
                safeMod(safeMod(lvlHair0, characterSeed), 1_333_777) +
                lvlAcc2003

        val loc4Str = loc4Num.toString()
        val hashed = cucsgHash(loc4Str)
        val seedStr = characterSeed.toString()
        return seedStr + hashed + seedStr.repeat(4)
    }

    private fun getRandomNSeed(
        characterSeed: Int,
        loader: LoaderInfo,
    ): String {
        val seedRng = characterSeed % loader.bytesLoaded
        val rng = PMPrng(seedRng)
        return buildString {
            repeat(4) {
                append(rng.nextInt())
            }
        }
    }

    fun buildLoginComponents(
        username: String,
        password: String,
        characterSeedRaw: Number,
        characterKey: String,
        loader: LoaderInfo = LoaderInfo(),
        libraryUrl: String = DEFAULT_LIBRARY_URL,
    ): Map<String, Any> {
        val characterSeed = characterSeedRaw.toInt()
        val levels = loadLibraryLevels(libraryUrl)
        val encryptedPassword =
            Crypt.encrypt(password, characterKey, characterSeed)
        val specificItem = getSpecificItem(loader, characterSeed, levels)
        val randomSeed = getRandomNSeed(characterSeed, loader)

        return linkedMapOf(
            "username" to username,
            "encrypted_password" to encryptedPassword,
            "character_seed" to characterSeed,
            "bytes_loaded" to loader.bytesLoaded,
            "bytes_total" to loader.bytesTotal,
            "character_key" to characterKey,
            "specific_item" to specificItem,
            "random_seed" to randomSeed,
            "password_length" to password.length,
        )
    }
}

