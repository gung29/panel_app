package com.example.panel_app

import java.io.ByteArrayOutputStream
import java.nio.charset.Charset
import java.util.Date

/**
 * Minimal AMF3 encoder/decoder for the subset of types
 * used by the Ninja Sage workflow (String, num, bool,
 * List, Map, Date, ByteArray).
 *
 * This is intentionally self-contained and does not depend
 * on any external AMF libraries.
 */
object Amf3 {
    const val UNDEFINED_TYPE = 0
    const val NULL_TYPE = 1
    const val FALSE_TYPE = 2
    const val TRUE_TYPE = 3
    const val INTEGER_TYPE = 4
    const val DOUBLE_TYPE = 5
    const val STRING_TYPE = 6
    const val DATE_TYPE = 8
    const val ARRAY_TYPE = 9
    const val OBJECT_TYPE = 10
    const val BYTEARRAY_TYPE = 12
    const val AMF0_AMF3 = 17

    private const val UINT29_MASK = 0x1FFFFFFF
    private const val INT28_MAX_VALUE = 0x0FFFFFFF
    private const val INT28_MIN_VALUE = -0x0FFFFFFF

    class Writer {
        private val buffer = ByteArrayOutputStream()

        fun toByteArray(): ByteArray = buffer.toByteArray()

        fun writeByte(v: Int) {
            buffer.write(v and 0xFF)
        }

        fun writeShort(v: Int) {
            writeByte((v ushr 8) and 0xFF)
            writeByte(v and 0xFF)
        }

        fun writeInt(v: Int) {
            writeByte((v ushr 24) and 0xFF)
            writeByte((v ushr 16) and 0xFF)
            writeByte((v ushr 8) and 0xFF)
            writeByte(v and 0xFF)
        }

        fun writeUInt29(value: Int) {
            var v = value and UINT29_MASK
            when {
                v < 0x80 -> writeByte(v)
                v < 0x4000 -> {
                    writeByte(((v shr 7) and 0x7F) or 0x80)
                    writeByte(v and 0x7F)
                }
                v < 0x200000 -> {
                    writeByte(((v shr 14) and 0x7F) or 0x80)
                    writeByte(((v shr 7) and 0x7F) or 0x80)
                    writeByte(v and 0x7F)
                }
                v < 0x40000000 -> {
                    writeByte(((v shr 22) and 0x7F) or 0x80)
                    writeByte(((v shr 15) and 0x7F) or 0x80)
                    writeByte(((v shr 8) and 0x7F) or 0x80)
                    writeByte(v and 0xFF)
                }
                else -> error("Integer out of range: $value")
            }
        }

        fun writeBytes(bytes: ByteArray) {
            buffer.write(bytes)
        }

        fun writeUTF(str: String, asAmf: Boolean) {
            val bytes = str.toByteArray(Charset.forName("UTF-8"))
            if (asAmf) {
                writeUInt29((bytes.size shl 1) or 1)
                writeBytes(bytes)
            } else {
                writeShort(bytes.size)
                writeBytes(bytes)
            }
        }

        fun writeStringWithoutType(str: String) {
            if (str.isEmpty()) {
                // empty inline string
                writeUInt29(1)
            } else {
                // always inline; no reference table
                writeUTF(str, true)
            }
        }

        private fun writeAmfInt(v: Int) {
            if (v in INT28_MIN_VALUE..INT28_MAX_VALUE) {
                val masked = v and UINT29_MASK
                writeByte(INTEGER_TYPE)
                writeUInt29(masked)
            } else {
                writeByte(DOUBLE_TYPE)
                writeDouble(v.toDouble())
            }
        }

        private fun writeDouble(value: Double) {
            val bits = java.lang.Double.doubleToRawLongBits(value)
            for (i in 7 downTo 0) {
                writeByte(((bits shr (8 * i)) and 0xFF).toInt())
            }
        }

        fun writeObject(value: Any?) {
            when (value) {
                null -> writeByte(NULL_TYPE)
                is String -> {
                    writeByte(STRING_TYPE)
                    writeStringWithoutType(value)
                }
                is Boolean -> writeByte(if (value) TRUE_TYPE else FALSE_TYPE)
                is Int, is Short, is Byte -> writeAmfInt((value as Number).toInt())
                is Long -> {
                    val v = value.toInt()
                    writeAmfInt(v)
                }
                is Number -> {
                    writeByte(DOUBLE_TYPE)
                    writeDouble(value.toDouble())
                }
                is List<*> -> writeArray(value)
                is Map<*, *> -> writeMap(value)
                is Date -> {
                    writeByte(DATE_TYPE)
                    writeUInt29(1) // inline
                    writeDouble(value.time.toDouble())
                }
                is ByteArray -> {
                    writeByte(BYTEARRAY_TYPE)
                    writeUInt29((value.size shl 1) or 1)
                    writeBytes(value)
                }
                else -> {
                    // Fallback: encode as string
                    val s = value.toString()
                    writeByte(STRING_TYPE)
                    writeStringWithoutType(s)
                }
            }
        }

        private fun writeArray(list: List<*>?) {
            writeByte(ARRAY_TYPE)
            val items = list ?: emptyList<Any?>()
            writeUInt29((items.size shl 1) or 1) // inline, length
            writeUInt29(1) // empty string -> no named keys
            for (item in items) {
                writeObject(item)
            }
        }

        @Suppress("UNCHECKED_CAST")
        private fun writeMap(map: Map<*, *>?) {
            writeByte(OBJECT_TYPE)
            val entries = map ?: emptyMap<Any?, Any?>()
            // Inline object, dynamic, zero sealed properties.
            writeUInt29(0x0B)
            writeStringWithoutType("") // class name
            for ((k, v) in entries) {
                val key = k?.toString() ?: ""
                writeStringWithoutType(key)
                writeObject(v)
            }
            writeStringWithoutType("") // end of dynamic members
        }
    }

    private class Reader(private val data: ByteArray) {
        private var pos: Int = 0
        private val objects = mutableListOf<Any?>()
        private val strings = mutableListOf<String>()
        private val traits = mutableListOf<Traits>()

        data class Traits(
            val className: String?,
            val externalizable: Boolean,
            val dynamic: Boolean,
            val props: List<String>,
        )

        fun read(): Int {
            return data[pos++].toInt() and 0xFF
        }

        fun readUnsignedShort(): Int {
            val c1 = read()
            val c2 = read()
            return (c1 shl 8) or c2
        }

        fun readUInt29(): Int {
            var b = read()
            if (b < 0x80) return b
            var value = (b and 0x7F) shl 7
            b = read()
            if (b < 0x80) return value or b
            value = (value or (b and 0x7F)) shl 7
            b = read()
            if (b < 0x80) return value or b
            value = (value or (b and 0x7F)) shl 8
            b = read()
            return value or b
        }

        private fun readBytes(length: Int): ByteArray {
            val result = data.copyOfRange(pos, pos + length)
            pos += length
            return result
        }

        fun readUTF(length: Int? = null): String {
            val len = length ?: readUnsignedShort()
            if (len == 0) return ""
            val bytes = readBytes(len)
            return String(bytes, Charset.forName("UTF-8"))
        }

        fun reset() {
            objects.clear()
            strings.clear()
            traits.clear()
        }

        fun readObject(): Any? {
            val type = read()
            return readObjectValue(type)
        }

        fun readHeaderObject(): Any? {
            var type = read()
            if (type == AMF0_AMF3) {
                type = read()
                return readObjectValue(type)
            }
            return readHeaderObjectValue(type)
        }

        private fun readString(): String {
            val ref = readUInt29()
            if (ref and 1 == 0) {
                val index = ref shr 1
                return strings[index]
            }
            val len = ref shr 1
            if (len == 0) return ""
            val str = readUTF(len)
            strings.add(str)
            return str
        }

        private fun rememberObject(value: Any?) {
            objects.add(value)
        }

        private fun getObject(index: Int): Any? {
            return objects[index]
        }

        private fun rememberTraits(t: Traits) {
            traits.add(t)
        }

        private fun getTraits(index: Int): Traits {
            return traits[index]
        }

        private fun readTraits(ref: Int): Traits {
            return if (ref and 3 == 1) {
                getTraits(ref shr 2)
            } else {
                val count = ref shr 4
                val className = readString().takeIf { it.isNotEmpty() }
                val externalizable = (ref and 4) == 4
                val dynamic = (ref and 8) == 8
                val props = mutableListOf<String>()
                repeat(count) {
                    props.add(readString())
                }
                val traits = Traits(
                    className = className,
                    externalizable = externalizable,
                    dynamic = dynamic,
                    props = props,
                )
                rememberTraits(traits)
                traits
            }
        }

        private fun readScriptObject(): Any? {
            val ref = readUInt29()
            if (ref and 1 == 0) {
                return getObject(ref shr 1)
            }

            val traits = readTraits(ref)
            val map = mutableMapOf<String, Any?>()
            rememberObject(map)

            if (traits.externalizable) {
                // limited support: handle ArrayCollection and simple maps if needed
                // For game payloads we do not expect externalizable objects,
                // so this path is intentionally minimal.
                return map
            }

            for (prop in traits.props) {
                val value = readObject()
                map[prop] = value
            }

            if (traits.dynamic) {
                while (true) {
                    val name = readString()
                    if (name.isEmpty()) break
                    map[name] = readObject()
                }
            }

            return map
        }

        private fun readArray(): Any? {
            val ref = readUInt29()
            if (ref and 1 == 0) {
                return getObject(ref shr 1)
            }
            val len = ref shr 1

            var map: MutableMap<String, Any?>? = null
            while (true) {
                val name = readString()
                if (name.isEmpty()) break
                if (map == null) {
                    map = mutableMapOf()
                    rememberObject(map)
                }
                map[name] = readObject()
            }

            if (map == null) {
                val list = MutableList<Any?>(len) { null }
                rememberObject(list)
                for (i in 0 until len) {
                    list[i] = readObject()
                }
                return list
            } else {
                for (i in 0 until len) {
                    map[i.toString()] = readObject()
                }
                return map
            }
        }

        private fun readDouble(): Double {
            val b0 = read()
            val b1 = read()
            val b2 = read()
            val b3 = read()
            val b4 = read()
            val b5 = read()
            val b6 = read()
            val b7 = read()
            val bits =
                (b0.toLong() shl 56) or
                    (b1.toLong() shl 48) or
                    (b2.toLong() shl 40) or
                    (b3.toLong() shl 32) or
                    (b4.toLong() shl 24) or
                    (b5.toLong() shl 16) or
                    (b6.toLong() shl 8) or
                    b7.toLong()
            return java.lang.Double.longBitsToDouble(bits)
        }

        private fun readDate(): Any? {
            val ref = readUInt29()
            if (ref and 1 == 0) {
                return getObject(ref shr 1)
            }
            val time = readDouble().toLong()
            val date = Date(time)
            rememberObject(date)
            return date
        }

        private fun readMap(): Map<String, Any?> {
            val ref = readUInt29()
            if (ref and 1 == 0) {
                @Suppress("UNCHECKED_CAST")
                return getObject(ref shr 1) as Map<String, Any?>
            }
            val length = ref shr 1
            val map = mutableMapOf<String, Any?>()
            if (length > 0) {
                rememberObject(map)
                while (true) {
                    val name = readObject() as? String ?: break
                    map[name] = readObject()
                }
            }
            return map
        }

        private fun readByteArray(): ByteArray {
            val ref = readUInt29()
            if (ref and 1 == 0) {
                @Suppress("UNCHECKED_CAST")
                return getObject(ref shr 1) as ByteArray
            }
            val len = ref shr 1
            val ba = readBytes(len)
            rememberObject(ba)
            return ba
        }

        private fun readHeaderObjectValue(type: Int): Any? {
            return when (type) {
                2 -> readUTF()
                else -> error("Unknown AMF0 header type: $type")
            }
        }

        private fun readObjectValue(type: Int): Any? {
            return when (type) {
                STRING_TYPE -> readString()
                OBJECT_TYPE -> readScriptObject()
                ARRAY_TYPE -> readArray()
                FALSE_TYPE -> false
                TRUE_TYPE -> true
                INTEGER_TYPE -> {
                    val tmp = readUInt29()
                    (tmp shl 3) shr 3
                }
                DOUBLE_TYPE -> readDouble()
                UNDEFINED_TYPE, NULL_TYPE -> null
                DATE_TYPE -> readDate()
                BYTEARRAY_TYPE -> readByteArray()
                AMF0_AMF3 -> readObject()
                else -> error("Unknown AMF3 type: $type")
            }
        }
    }

    data class MessageBody(
        val targetURI: String,
        val responseURI: String,
        val data: Any?,
    )

    private class Deserializer(private val reader: Reader) {
        fun readFirstBody(): MessageBody? {
            reader.readUnsignedShort() // version

            val headerCount = reader.readUnsignedShort()
            repeat(headerCount) {
                readHeader()
            }

            val bodyCount = reader.readUnsignedShort()
            if (bodyCount == 0) return null
            return readBody()
        }

        private fun readHeader() {
            reader.readUTF() // name
            reader.read() // mustUnderstand
            repeat(4) { reader.read() } // length
            reader.reset()
            reader.readHeaderObject()
        }

        private fun readBody(): MessageBody {
            val target = reader.readUTF()
            val response = reader.readUTF()
            repeat(4) { reader.read() } // length
            reader.reset()
            val data = reader.readObject()
            return MessageBody(target, response, data)
        }
    }

    fun decodeFirstBody(data: ByteArray): MessageBody? {
        val reader = Reader(data)
        val deserializer = Deserializer(reader)
        return deserializer.readFirstBody()
    }

    data class ActionMessage(
        val version: Int = 3,
        val bodies: List<MessageBody>,
    )

    class Serializer {
        fun writeMessage(message: ActionMessage): ByteArray {
            val writer = Writer()
            writer.writeShort(message.version)
            writer.writeShort(0) // header count
            writer.writeShort(message.bodies.size)

            for (body in message.bodies) {
                writeBody(writer, body)
            }

            return writer.toByteArray()
        }

        private fun writeBody(writer: Writer, body: MessageBody) {
            writer.writeUTF(body.targetURI, asAmf = false)
            writer.writeUTF(body.responseURI, asAmf = false)

            val bodyWriter = Writer()
            bodyWriter.writeByte(AMF0_AMF3)
            bodyWriter.writeObject(body.data)

            val bodyBytes = bodyWriter.toByteArray()
            writer.writeInt(bodyBytes.size)
            writer.writeBytes(bodyBytes)
        }
    }
}
