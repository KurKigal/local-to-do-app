package com.emirhankeser.flowtask

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private var pendingPickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            REMINDER_SOUND_CHANNEL,
        ).setMethodCallHandler(::handleReminderSoundMethod)
    }

    private fun handleReminderSoundMethod(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        when (call.method) {
            "chooseAndImport" -> chooseAndImport(result)
            "deleteImported" -> {
                val uri = call.argument<String>("uri")
                if (uri.isNullOrBlank()) {
                    result.success(false)
                    return
                }

                try {
                    val deleted = contentResolver.delete(
                        android.net.Uri.parse(uri),
                        null,
                        null,
                    ) > 0
                    result.success(deleted)
                } catch (_: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun chooseAndImport(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "unsupported_android_version",
                "Custom notification sounds require Android 10 or newer.",
                null,
            )
            return
        }

        if (pendingPickerResult != null) {
            result.error("picker_active", "The audio picker is already open.", null)
            return
        }

        pendingPickerResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
        }

        startActivityForResult(intent, PICK_AUDIO_REQUEST)
    }

    @Deprecated("Deprecated in Android; retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != PICK_AUDIO_REQUEST) {
            return
        }

        val result = pendingPickerResult ?: return
        pendingPickerResult = null

        val sourceUri = data?.data
        if (resultCode != Activity.RESULT_OK || sourceUri == null) {
            result.success(null)
            return
        }

        thread(name = "flowtask-sound-import") {
            try {
                val imported = importIntoMediaStore(sourceUri)
                runOnUiThread { result.success(imported) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "sound_import_failed",
                        error.message ?: "Could not import the audio file.",
                        null,
                    )
                }
            }
        }
    }

    private fun importIntoMediaStore(sourceUri: android.net.Uri): Map<String, String> {
        val mimeType = contentResolver.getType(sourceUri)
            ?.takeIf { it.startsWith("audio/") }
            ?: throw IllegalArgumentException("The selected file is not recognized as audio.")

        val displayName = queryDisplayName(sourceUri)
            ?.substringAfterLast('/')
            ?.takeIf { it.isNotBlank() }
            ?: "flowtask_notification_${System.currentTimeMillis()}"

        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Audio.Media.MIME_TYPE, mimeType)
            put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_NOTIFICATIONS}/FlowTask")
            put(MediaStore.Audio.AudioColumns.IS_NOTIFICATION, 1)
            put(MediaStore.Audio.Media.IS_PENDING, 1)
        }

        val destinationUri = contentResolver.insert(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw IllegalStateException("Android could not create the notification sound.")

        try {
            contentResolver.openInputStream(sourceUri).use { input ->
                requireNotNull(input) { "Could not open the selected audio file." }
                contentResolver.openOutputStream(destinationUri).use { output ->
                    requireNotNull(output) { "Could not create the imported audio file." }
                    input.copyTo(output)
                }
            }

            val published = ContentValues().apply {
                put(MediaStore.Audio.Media.IS_PENDING, 0)
            }
            contentResolver.update(destinationUri, published, null, null)

            return mapOf(
                "uri" to destinationUri.toString(),
                "displayName" to displayName,
            )
        } catch (error: Exception) {
            contentResolver.delete(destinationUri, null, null)
            throw error
        }
    }

    private fun queryDisplayName(uri: android.net.Uri): String? {
        return contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (!cursor.moveToFirst()) {
                null
            } else {
                cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
            }
        }
    }

    override fun onDestroy() {
        pendingPickerResult?.error(
            "activity_destroyed",
            "The audio picker was closed before it completed.",
            null,
        )
        pendingPickerResult = null
        super.onDestroy()
    }

    companion object {
        private const val REMINDER_SOUND_CHANNEL =
            "com.emirhankeser.flowtask/reminder_sound"
        private const val PICK_AUDIO_REQUEST = 41072
    }
}
