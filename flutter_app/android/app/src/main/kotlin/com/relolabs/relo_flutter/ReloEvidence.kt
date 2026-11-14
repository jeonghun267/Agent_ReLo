package com.relolabs.relo_flutter

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

/**
 * 영수증 · 사진 하나를 기기에서 가져온다.
 *
 *  - camera: 기기의 카메라 앱으로 찍는다. 앱은 카메라 권한을 갖지 않는다 (찍는 것은 카메라 앱이다).
 *  - photo:  기기의 사진 고르기 화면. 사진첩 전체를 읽는 권한 없이, 고른 한 장만 받는다.
 *  - file:   기기의 파일 고르기 화면 (PDF · 사진).
 *
 * 사진은 여기서 바로 세우고(찍은 방향 반영) 긴 쪽 2560px 이하로 줄여 JPEG로 다시 저장한다.
 * 다시 저장하면서 촬영 위치 같은 덧붙은 정보가 빠진다. PDF · PNG · WebP는 그대로 넘긴다.
 * 종류 확인 · 크기 확인은 앱 쪽(EvidenceRules)에서 한 번 더 한다.
 */
class ReloEvidence(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var maxBytes = DEFAULT_MAX_BYTES
    private var captureFile: File? = null
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private class Failure(val code: String) : Exception(code)

    fun start(source: String, maxBytes: Int, result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", null, null)
            return
        }
        this.maxBytes = maxBytes
        try {
            val intent = when (source) {
                "camera" -> cameraIntent()
                "photo" -> photoIntent()
                else -> fileIntent()
            }
            pending = result
            activity.startActivityForResult(intent, REQUEST_PICK)
        } catch (e: Exception) {
            // 카메라나 고르기 화면이 없는 기기
            pending = null
            captureFile = null
            result.error("unavailable", null, null)
        }
    }

    private fun cameraIntent(): Intent {
        val dir = File(activity.cacheDir, "captures").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() } // 지난 촬영본을 남겨 두지 않는다
        val file = File(dir, "capture_${System.currentTimeMillis()}.jpg")
        captureFile = file
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.relo.files", file)
        return Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            clipData = ClipData.newRawUri("", uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun photoIntent(): Intent =
        if (Build.VERSION.SDK_INT >= 33) {
            Intent(MediaStore.ACTION_PICK_IMAGES).setType("image/*")
        } else {
            Intent(Intent.ACTION_GET_CONTENT).setType("image/*").addCategory(Intent.CATEGORY_OPENABLE)
        }

    private fun fileIntent(): Intent =
        Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/pdf", "image/*"))

    /** 고르기 화면에서 돌아왔을 때. 우리 요청이 아니면 false. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = pending ?: return true
        pending = null
        val capture = captureFile
        captureFile = null
        if (resultCode != Activity.RESULT_OK) {
            capture?.delete()
            result.success(null) // 그만둠
            return true
        }
        val uri = data?.data
        readInBackground(result, cleanup = { capture?.delete() }) {
            when {
                capture != null && capture.length() > 0 -> readCapture(capture)
                uri != null -> readPicked(uri)
                else -> null
            }
        }
        return true
    }

    /** 다른 앱에서 "공유 → ReLo"로 넘어온 파일 하나를 읽는다. */
    fun readShared(uri: Uri, maxBytes: Int, result: MethodChannel.Result) {
        this.maxBytes = maxBytes
        readInBackground(result) { readPicked(uri) }
    }

    /** 파일 읽기와 사진 줄이기는 화면을 멈추지 않게 뒤에서 하고, 답은 화면 쪽 줄(main)에서 돌려준다. */
    private fun readInBackground(
        result: MethodChannel.Result,
        cleanup: () -> Unit = {},
        read: () -> Map<String, Any>?,
    ) {
        worker.execute {
            var picked: Map<String, Any>? = null
            var error = "unreadable"
            try {
                picked = read()
            } catch (f: Failure) {
                error = f.code
            } catch (t: Throwable) {
                // 메모리 부족 · 읽기 실패 등
            } finally {
                cleanup()
            }
            main.post {
                if (picked != null) result.success(picked) else result.error(error, null, null)
            }
        }
    }

    private fun readCapture(file: File): Map<String, Any> {
        val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        return mapOf("name" to "photo_$stamp.jpg", "bytes" to toJpeg { FileInputStream(file) })
    }

    private fun readPicked(uri: Uri): Map<String, Any> {
        val resolver = activity.contentResolver
        val name = displayName(uri) ?: "evidence"
        val head = ByteArray(12)
        val headLength = resolver.openInputStream(uri)?.use { it.read(head) } ?: throw Failure("unreadable")
        val declared = resolver.getType(uri) ?: ""
        return when (sniff(head, headLength)) {
            "pdf" -> mapOf("name" to name, "bytes" to readAll(uri))
            "png", "webp" -> {
                // 글자가 선명하게 남도록 그대로 넘긴다. 10MB를 넘을 때만 줄여서 JPEG로 바꾼다.
                val bytes = try {
                    readAll(uri)
                } catch (f: Failure) {
                    if (f.code != "too_large") throw f
                    toJpeg { resolver.openInputStream(uri) }
                }
                mapOf("name" to name, "bytes" to bytes)
            }
            "jpeg" -> mapOf("name" to name, "bytes" to toJpeg { resolver.openInputStream(uri) })
            // HEIC 같은 다른 사진 형식은 JPEG로 바꿔 받는다
            else -> if (declared.startsWith("image/")) {
                mapOf("name" to name, "bytes" to toJpeg { resolver.openInputStream(uri) })
            } else {
                throw Failure("unsupported_type")
            }
        }
    }

    private fun sniff(b: ByteArray, n: Int): String? = when {
        n >= 3 && b[0] == 0xFF.toByte() && b[1] == 0xD8.toByte() && b[2] == 0xFF.toByte() -> "jpeg"
        n >= 8 && b[0] == 0x89.toByte() && b[1] == 'P'.code.toByte() && b[2] == 'N'.code.toByte() &&
            b[3] == 'G'.code.toByte() -> "png"
        n >= 12 && String(b, 0, 4, Charsets.US_ASCII) == "RIFF" &&
            String(b, 8, 4, Charsets.US_ASCII) == "WEBP" -> "webp"
        n >= 5 && String(b, 0, 5, Charsets.US_ASCII) == "%PDF-" -> "pdf"
        else -> null
    }

    private fun readAll(uri: Uri): ByteArray {
        val out = ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        val input = activity.contentResolver.openInputStream(uri) ?: throw Failure("unreadable")
        input.use {
            while (true) {
                val read = it.read(buffer)
                if (read < 0) break
                out.write(buffer, 0, read)
                if (out.size() > maxBytes) throw Failure("too_large")
            }
        }
        return out.toByteArray()
    }

    /** 사진을 바로 세우고, 긴 쪽이 [MAX_EDGE] 이하가 되게 줄여 JPEG로 만든다. */
    private fun toJpeg(open: () -> InputStream?): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        (open() ?: throw Failure("unreadable")).use { BitmapFactory.decodeStream(it, null, bounds) }
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) throw Failure("unsupported_type")

        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_EDGE) sample *= 2
        val options = BitmapFactory.Options().apply { inSampleSize = sample }
        val decoded = (open() ?: throw Failure("unreadable")).use {
            BitmapFactory.decodeStream(it, null, options)
        } ?: throw Failure("unreadable")

        val matrix = (open() ?: throw Failure("unreadable")).use(::orientationOf)
        val longest = maxOf(decoded.width, decoded.height)
        if (longest > MAX_EDGE) {
            val scale = MAX_EDGE.toFloat() / longest
            matrix.postScale(scale, scale)
        }
        val upright = if (matrix.isIdentity) {
            decoded
        } else {
            Bitmap.createBitmap(decoded, 0, 0, decoded.width, decoded.height, matrix, true)
        }

        var quality = 88
        while (true) {
            val out = ByteArrayOutputStream()
            upright.compress(Bitmap.CompressFormat.JPEG, quality, out)
            if (out.size() <= maxBytes || quality <= 50) {
                if (upright !== decoded) upright.recycle()
                decoded.recycle()
                if (out.size() > maxBytes) throw Failure("too_large")
                return out.toByteArray()
            }
            quality -= 12
        }
    }

    /** 사진에 적힌 "찍은 방향"을 그림을 돌리는 값으로 바꾼다. */
    private fun orientationOf(input: InputStream): Matrix {
        val matrix = Matrix()
        val orientation = try {
            ExifInterface(input).getAttributeInt(
                ExifInterface.TAG_ORIENTATION,
                ExifInterface.ORIENTATION_NORMAL,
            )
        } catch (e: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            ExifInterface.ORIENTATION_TRANSPOSE -> {
                matrix.postRotate(90f)
                matrix.postScale(-1f, 1f)
            }
            ExifInterface.ORIENTATION_TRANSVERSE -> {
                matrix.postRotate(270f)
                matrix.postScale(-1f, 1f)
            }
        }
        return matrix
    }

    private fun displayName(uri: Uri): String? = try {
        activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
    } catch (e: Exception) {
        null
    }

    companion object {
        const val DEFAULT_MAX_BYTES = 10 * 1024 * 1024
        private const val REQUEST_PICK = 4181
        private const val MAX_EDGE = 2560
    }
}
