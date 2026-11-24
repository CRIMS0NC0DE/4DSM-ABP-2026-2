package com.example.public_app

import android.content.Context
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.ByteBuffer
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.UUID

/**
 * Chave do "celular como chave": um par EC P-256 no Android Keystore.
 * A privada nunca sai do aparelho; a pública vai para a API em POST /me/phones.
 * O protocolo está em backend/src/modules/phones/phone-signature.ts.
 */
object ChaveCelular {
    private const val ALIAS = "passe-celular-nfc"
    private const val PREFS = "passe_celular_nfc"
    private const val CHAVE_ID = "celularId"
    private val PREFIXO = "PASSE-CEL1".toByteArray(Charsets.US_ASCII)

    private fun keyStore(): KeyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    private fun prefs(contexto: Context) = contexto.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Cria o par, se ainda não existe, e devolve a chave pública em SPKI DER (base64). */
    fun prepararChave(): String {
        val ks = keyStore()
        if (!ks.containsAlias(ALIAS)) {
            val spec = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
                .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
            // Com o celular bloqueado, a chave não assina (o apduservice.xml também exige desbloqueio).
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) spec.setUnlockedDeviceRequired(true)
            KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore").run {
                initialize(spec.build())
                generateKeyPair()
            }
        }
        // O certificado do Keystore traz a pública no formato X.509 SubjectPublicKeyInfo.
        return Base64.encodeToString(ks.getCertificate(ALIAS).publicKey.encoded, Base64.NO_WRAP)
    }

    /** A API respondeu ao cadastro: guarda o id que o celular manda para o terminal. */
    fun salvarId(contexto: Context, id: String) {
        UUID.fromString(id) // recusa id fora do formato antes de guardar
        prefs(contexto).edit().putString(CHAVE_ID, id).apply()
    }

    /** Id do celular no Passe, ou null se ele ainda não foi ativado (ou a chave sumiu). */
    fun idAtivo(contexto: Context): String? {
        val id = prefs(contexto).getString(CHAVE_ID, null) ?: return null
        return if (keyStore().containsAlias(ALIAS)) id else null
    }

    fun apagar(contexto: Context) {
        prefs(contexto).edit().remove(CHAVE_ID).apply()
        val ks = keyStore()
        if (ks.containsAlias(ALIAS)) ks.deleteEntry(ALIAS)
    }

    /**
     * Resposta ao desafio do terminal: id (16 bytes) + assinatura r||s (64 bytes)
     * de PREFIXO || desafio. Null se o celular não está ativado.
     */
    fun responderDesafio(contexto: Context, desafio: ByteArray): ByteArray? {
        val id = idAtivo(contexto) ?: return null
        val privada = keyStore().getKey(ALIAS, null) as? PrivateKey ?: return null
        val der = Signature.getInstance("SHA256withECDSA").run {
            initSign(privada)
            update(PREFIXO)
            update(desafio)
            sign()
        }
        return uuidEmBytes(id) + derParaRs(der)
    }

    private fun uuidEmBytes(id: String): ByteArray {
        val u = UUID.fromString(id)
        return ByteBuffer.allocate(16).putLong(u.mostSignificantBits).putLong(u.leastSignificantBits).array()
    }

    /** O Keystore assina em DER (SEQUENCE { r, s }); o protocolo usa r||s, 32 bytes cada. */
    internal fun derParaRs(der: ByteArray): ByteArray {
        require(der.size >= 8 && der[0] == 0x30.toByte()) { "assinatura fora do formato DER" }
        var i = if ((der[1].toInt() and 0x80) != 0) 2 + (der[1].toInt() and 0x7F) else 2
        fun inteiro(): ByteArray {
            require(der[i] == 0x02.toByte()) { "assinatura fora do formato DER" }
            val tamanho = der[i + 1].toInt()
            val valor = der.copyOfRange(i + 2, i + 2 + tamanho)
            i += 2 + tamanho
            // Tira o zero de sinal do DER e completa à esquerda até 32 bytes.
            val semZeros = valor.dropWhile { it == 0.toByte() }.toByteArray()
            require(semZeros.size <= 32) { "inteiro maior que 32 bytes" }
            return ByteArray(32 - semZeros.size) + semZeros
        }
        val r = inteiro()
        val s = inteiro()
        return r + s
    }
}
