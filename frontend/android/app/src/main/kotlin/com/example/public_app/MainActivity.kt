package com.example.public_app

import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Canal do "celular como chave" (lib/services/celular_nfc_plataforma.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "passe/celular_nfc")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "estado" -> result.success(
                            mapOf(
                                "suportado" to packageManager.hasSystemFeature(
                                    PackageManager.FEATURE_NFC_HOST_CARD_EMULATION,
                                ),
                                "nfcLigado" to (NfcAdapter.getDefaultAdapter(this)?.isEnabled == true),
                                "celularId" to ChaveCelular.idAtivo(this),
                                "modelo" to Build.MODEL,
                            ),
                        )
                        // Gerar o par no Keystore pode levar meio segundo: fora da thread da tela.
                        "prepararChave" -> Thread {
                            val chave = runCatching { ChaveCelular.prepararChave() }
                            runOnUiThread {
                                chave.fold(
                                    { result.success(it) },
                                    { result.error("CHAVE", it.message, null) },
                                )
                            }
                        }.start()
                        "ativar" -> {
                            ChaveCelular.salvarId(this, call.argument<String>("celularId")!!)
                            result.success(null)
                        }
                        "desativar" -> {
                            ChaveCelular.apagar(this)
                            result.success(null)
                        }
                        "abrirAjustesNfc" -> {
                            startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("CELULAR_NFC", e.message, null)
                }
            }
    }
}
