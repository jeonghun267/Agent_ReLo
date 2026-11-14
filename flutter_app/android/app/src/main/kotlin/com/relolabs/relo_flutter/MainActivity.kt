package com.relolabs.relo_flutter

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.window.SplashScreenView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 앱 화면(Flutter)과 기기 기능을 잇는 곳. 바깥 패키지를 쓰지 않고 안드로이드 기본 기능을 직접 부른다.
 * Dart 쪽 짝은 lib/core/platform/relo_native_channel.dart 이다.
 *
 *  - 영수증 · 사진 고르기, 다른 앱에서 공유받기 → [ReloEvidence]
 *  - 마감 알림 맞추기                          → [ReloReminders]
 *  - 쓴 메시지를 다른 앱으로 넘기기             → 기기의 "공유" 화면
 *  - 시작 화면이 걷히는 때를 앱에 알리기         → 앱 안의 시작 연출이 이어받는다
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var evidence: ReloEvidence? = null
    private var pendingPermission: MethodChannel.Result? = null

    /** 알림을 눌러 앱이 열렸을 때 그 환불 건. 앱이 한 번 읽어 가면 비운다. */
    private var openedClaimId: String? = null

    /** 다른 앱에서 "공유 → ReLo"로 넘어온 파일. 앱이 한 번 읽어 가면 비운다. */
    private var sharedUri: Uri? = null

    /**
     * 시작 화면(가운데 로고)을 앱 안의 시작 연출로 넘겨주기 위한 상태.
     *  - splashExpected: 시작 화면이 떠 있고, 시스템이 아직 넘겨주지 않았다
     *  - heldSplash: 시스템이 넘겨준 시작 화면. 앱이 걷어 달라고 할 때까지 그대로 둔다
     *  - pendingTakeOver: 앱이 먼저 걷어 달라고 했을 때, 넘겨받으면 답하려고 맡아 둔 것
     */
    private var splashExpected = false
    private var heldSplash: View? = null // 안드로이드 12 이상에서만 채워진다 (SplashScreenView)
    private var pendingTakeOver: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // 안드로이드 12부터는 시스템이 시작 화면을 그린다. 보통은 시스템이 알아서 걷지만,
        // 여기서는 걷을 때를 앱이 정한다: 앱이 같은 자리에 로고를 실제로 그린 다음에 걷어야 빈 화면이 끼지 않는다.
        if (Build.VERSION.SDK_INT >= 31 && savedInstanceState == null) splashExpected = true
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 31) {
            splashScreen.setOnExitAnimationListener { splash ->
                splashExpected = false
                heldSplash = splash
                pendingTakeOver?.let(::takeOverSplash)
                // 앱이 끝내 가져가지 않아도 시작 화면에 갇히지 않게 한다
                splash.postDelayed({ if (heldSplash === splash) dropSplash() }, SPLASH_SAFETY_MS)
            }
        }
    }

    /**
     * 앱이 "같은 자리에 로고를 그렸으니 이제 걷어 달라"고 할 때. 로고의 가운데가 앱 화면에서
     * 어디인지(px)를 돌려주고 시작 화면을 걷는다. 시스템이 아직 넘겨주지 않았으면 넘겨줄 때 답한다.
     */
    private fun takeOverSplash(result: MethodChannel.Result) {
        val splash = heldSplash
        if (splash == null) {
            if (splashExpected) pendingTakeOver = result else result.success(null)
            return
        }
        pendingTakeOver = null
        var center: Map<String, Double>? = null
        val icon = if (Build.VERSION.SDK_INT >= 31) (splash as SplashScreenView).iconView else null
        val flutterView = findViewById<View>(FLUTTER_VIEW_ID)
        if (icon != null && flutterView != null && icon.width > 0) {
            val iconAt = IntArray(2).also(icon::getLocationOnScreen)
            val appAt = IntArray(2).also(flutterView::getLocationOnScreen)
            center = mapOf(
                "cx" to (iconAt[0] - appAt[0] + icon.width / 2.0),
                "cy" to (iconAt[1] - appAt[1] + icon.height / 2.0),
            )
        }
        result.success(center)
        // 앱이 로고를 옮겨 그릴 틈을 한두 장면 준 뒤에 걷는다 (깜빡임 없이 이어지게)
        splash.postDelayed(::dropSplash, 50)
    }

    private fun dropSplash() {
        val splash = heldSplash ?: return
        heldSplash = null
        if (Build.VERSION.SDK_INT >= 31) (splash as SplashScreenView).remove()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        evidence = ReloEvidence(this)
        openedClaimId = takeClaimId(intent)
        sharedUri = takeSharedUri(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "relo/native").also {
            it.setMethodCallHandler(::onCall)
        }
    }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickEvidence" -> {
                val source = call.argument<String>("source") ?: "file"
                val maxBytes = call.argument<Int>("maxBytes") ?: ReloEvidence.DEFAULT_MAX_BYTES
                evidence?.start(source, maxBytes, result) ?: result.error("unavailable", null, null)
            }
            "takeSharedEvidence" -> {
                val uri = sharedUri
                sharedUri = null
                val maxBytes = call.argument<Int>("maxBytes") ?: ReloEvidence.DEFAULT_MAX_BYTES
                if (uri == null) result.success(null) else evidence?.readShared(uri, maxBytes, result)
            }
            "shareText" -> result.success(
                shareText(call.argument<String>("text") ?: "", call.argument<String>("subject")),
            )
            "splashState" -> result.success(
                mapOf("showing" to (splashExpected || heldSplash != null), "waitForFirstFrame" to true),
            )
            "takeOverSplash" -> takeOverSplash(result)
            "notificationsAllowed" -> result.success(ReloReminders.allowed(this))
            "requestNotifications" -> requestNotifications(result)
            "replaceReminders" -> {
                val raw = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
                ReloReminders.replaceAll(this, raw.mapNotNull(ReloReminders.Item::from))
                result.success(null)
            }
            "takeOpenedClaim" -> {
                result.success(openedClaimId)
                openedClaimId = null
            }
            else -> result.notImplemented()
        }
    }

    /** 안드로이드 13부터는 알림을 보내려면 사용자에게 물어야 한다. 그 전 버전은 기기 설정만 본다. */
    private fun requestNotifications(result: MethodChannel.Result) {
        val mustAsk = Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        if (!mustAsk) {
            result.success(ReloReminders.allowed(this))
            return
        }
        if (pendingPermission != null) {
            result.success(false)
            return
        }
        pendingPermission = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_NOTIFICATIONS)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return
        pendingPermission?.success(ReloReminders.allowed(this))
        pendingPermission = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (evidence?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    /** 앱이 떠 있는 동안 알림을 누르거나, 다른 앱에서 파일을 공유했을 때 */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        takeSharedUri(intent)?.let {
            sharedUri = it
            channel?.invokeMethod("evidenceShared", null)
        }
        takeClaimId(intent)?.let { channel?.invokeMethod("reminderOpened", it) }
    }

    /**
     * 공유로 넘어온 파일의 주소를 꺼내고 지운다. 다른 앱이 내어 준 주소(content://)만 받는다:
     * 기기 안의 경로를 직접 가리키는 주소나 이 앱 자신의 임시 폴더를 가리키는 주소는 받지 않는다.
     */
    private fun takeSharedUri(intent: Intent?): Uri? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val uri = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        }
        intent.removeExtra(Intent.EXTRA_STREAM)
        if (uri == null || uri.scheme != "content") return null
        if (uri.authority?.startsWith(packageName) == true) return null
        return uri
    }

    /** 쓴 메시지를 기기의 "공유" 화면으로 넘긴다. 어디로 보낼지는 사용자가 고른다. */
    private fun shareText(text: String, subject: String?): Boolean {
        if (text.isBlank()) return false
        val send = Intent(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, text)
        if (!subject.isNullOrBlank()) send.putExtra(Intent.EXTRA_SUBJECT, subject)
        return try {
            startActivity(Intent.createChooser(send, null))
            true
        } catch (e: Exception) {
            false
        }
    }

    /** 알림이 실어 보낸 환불 건 id를 꺼내고 지운다 (최근 앱 목록에서 다시 열 때 또 열리지 않게). */
    private fun takeClaimId(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val claimId = intent.getStringExtra(ReloReminders.EXTRA_CLAIM_ID)
        intent.removeExtra(ReloReminders.EXTRA_CLAIM_ID)
        return claimId
    }

    private companion object {
        const val REQUEST_NOTIFICATIONS = 4182
        const val SPLASH_SAFETY_MS = 5000L
    }
}
