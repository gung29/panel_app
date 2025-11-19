package com.example.panel_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.panel_app/amf"
    private val amfClient = NinjaSageAmfClient()

    @Volatile
    private var characterSeed: Int? = null

    @Volatile
    private var characterKey: String? = null

    @Volatile
    private var uid: Int? = null

    @Volatile
    private var sessionKey: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "bootstrapNinjaSage" -> {
                    Thread {
                        try {
                            // 1. SystemLogin.checkVersion
                            val versionBody = listOf(listOf("Public 0.52"))
                            val versionMap =
                                amfClient.invoke("SystemLogin.checkVersion", versionBody)

                            val seedAny = versionMap["_"] ?: versionMap["character_seed"]
                            val keyAny = versionMap["__"] ?: versionMap["character_key"]
                            characterSeed = (seedAny as? Number)?.toInt()
                            characterKey = keyAny?.toString()

                            // 2. Analytics.libraries
                            val analyticsPayload =
                                AnalyticsPayload.buildAnalyticsPayload()
                            val analyticsBody = listOf(listOf(analyticsPayload))
                            val analyticsMap =
                                amfClient.invoke("Analytics.libraries", analyticsBody)

                            // 3. EventsService.get
                            val eventsBody = listOf<Any?>(null)
                            val eventsMap =
                                amfClient.invoke("EventsService.get", eventsBody)

                            val payload = mapOf(
                                "version" to versionMap,
                                "analytics" to analyticsMap,
                                "events" to eventsMap,
                            )

                            runOnUiThread { result.success(payload) }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "bootstrap_error",
                                    "Failed to bootstrap Ninja Sage: ${e.message}",
                                    null,
                                )
                            }
                        }
                    }.start()
                }

                "getCharacterData" -> {
                    val charId = call.argument<Int>("charId")
                    val localSession = sessionKey

                    if (charId == null) {
                        result.error(
                            "invalid_args",
                            "Missing 'charId' for getCharacterData",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    if (localSession.isNullOrEmpty()) {
                        result.error(
                            "no_session",
                            "Session belum tersedia. Pastikan loginUser sudah berhasil.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val body = listOf(listOf(charId, localSession))
                            val data = amfClient.invoke(
                                target = "SystemLogin.getCharacterData",
                                body = body,
                            )
                            runOnUiThread { result.success(data) }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "char_data_error",
                                    "Failed to fetch character data: ${e.message}",
                                    null,
                                )
                            }
                        }
                    }.start()
                }

                "loginUser" -> {
                    val username = call.argument<String>("username")
                    val password = call.argument<String>("password")

                    if (username.isNullOrEmpty() || password == null) {
                        result.error(
                            "invalid_args",
                            "Missing username/password for loginUser",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    val seed = characterSeed
                    val key = characterKey
                    if (seed == null || key.isNullOrEmpty()) {
                        result.error(
                            "no_version",
                            "checkVersion belum dipanggil. Jalankan bootstrap terlebih dahulu.",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val components = LoginPayload.buildLoginComponents(
                                username = username,
                                password = password,
                                characterSeedRaw = seed,
                                characterKey = key,
                            )

                            val params = listOf(
                                components["username"] as String,
                                components["encrypted_password"] as String,
                                (components["character_seed"] as Number).toDouble(),
                                (components["bytes_loaded"] as Number).toInt(),
                                (components["bytes_total"] as Number).toInt(),
                                components["character_key"] as String,
                                components["specific_item"] as String,
                                components["random_seed"] as String,
                                (components["password_length"] as Number).toInt(),
                            )

                            val loginMap = amfClient.invoke(
                                target = "SystemLogin.loginUser",
                                body = listOf(params),
                            )

                            val statusVal =
                                (loginMap["status"] as? Number)?.toInt() ?: 0

                            // Jika status bukan 1, anggap login gagal
                            // dan jangan lanjut ke getAllCharacters.
                            if (statusVal != 1) {
                                val payload = mapOf(
                                    "login" to loginMap,
                                    "characters" to null,
                                )
                                runOnUiThread { result.success(payload) }
                                return@Thread
                            }

                            val uidVal = (loginMap["uid"] as? Number)?.toInt()
                            val sessionVal = loginMap["sessionkey"]?.toString()
                            uid = uidVal
                            sessionKey = sessionVal

                            if (uidVal == null || sessionVal.isNullOrEmpty()) {
                                throw IllegalStateException(
                                    "Tidak menemukan uid/sessionkey dari loginUser",
                                )
                            }

                            // Langsung panggil getAllCharacters setelah login berhasil.
                            val charsBody = listOf(listOf(uidVal, sessionVal))
                            val charsMap = amfClient.invoke(
                                target = "SystemLogin.getAllCharacters",
                                body = charsBody,
                            )

                            val payload = mapOf(
                                "login" to loginMap,
                                "characters" to charsMap,
                            )

                            runOnUiThread { result.success(payload) }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "login_error",
                                    "Failed to login and fetch characters: ${e.message}",
                                    null,
                                )
                            }
                        }
                    }.start()
                }

                "invokeAmf" -> {
                    val target = call.argument<String>("target")
                    @Suppress("UNCHECKED_CAST")
                    val body = call.argument<List<Any?>>("body")

                    if (target.isNullOrEmpty()) {
                        result.error(
                            "invalid_args",
                            "Missing 'target' for AMF invocation",
                            null,
                        )
                        return@setMethodCallHandler
                    }

                    Thread {
                        try {
                            val effectiveBody: List<Any?> =
                                if (target == "SystemLogin.getAllCharacters" &&
                                    (body == null || body.isEmpty())
                                ) {
                                    val localUid = uid
                                    val localSession = sessionKey
                                    if (localUid == null || localSession.isNullOrEmpty()) {
                                        throw IllegalStateException(
                                            "Session belum diinisialisasi. Panggil loginUser terlebih dahulu.",
                                        )
                                    }
                                    listOf(listOf(localUid, localSession))
                                } else {
                                    body ?: emptyList()
                                }

                            val normalized =
                                amfClient.invoke(target = target, body = effectiveBody)
                            runOnUiThread { result.success(normalized) }
                        } catch (e: Exception) {
                            runOnUiThread {
                                result.error(
                                    "amf_error",
                                    "Failed to invoke AMF: ${e.message}",
                                    null,
                                )
                            }
                        }
                    }.start()
                }

                else -> result.notImplemented()
            }
        }
    }
}
