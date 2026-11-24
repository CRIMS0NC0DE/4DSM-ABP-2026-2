package com.example.public_app

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.util.concurrent.Executors

/**
 * Faz o celular responder como um cartão quando encosta no leitor do terminal (HCE).
 * O Android só chama este serviço depois do SELECT do AID do Passe (res/xml/apduservice.xml)
 * e com o celular desbloqueado. Funciona com o app fechado e sem internet no celular.
 *
 *   SELECT  00 A4 04 00 07 F0 50 41 53 53 45 01 00  →  01 90 00
 *   ASSINAR 80 10 00 00 20 <desafio, 32 bytes> 00   →  <id, 16> <assinatura, 64> 90 00
 *                                                      69 85 se o celular não foi ativado
 */
class PasseHceService : HostApduService() {
    // O processCommandApdu roda na thread principal; a assinatura no Keystore pode
    // levar dezenas de milissegundos, então vai para outra thread (o chip NFC pede
    // mais tempo ao terminal enquanto isso).
    private val trabalho = Executors.newSingleThreadExecutor()

    override fun processCommandApdu(apdu: ByteArray, extras: Bundle?): ByteArray? {
        if (ehSelect(apdu)) return byteArrayOf(VERSAO_PROTOCOLO) + SW_OK
        if (!ehAssinar(apdu)) return SW_INS_DESCONHECIDA

        val desafio = apdu.copyOfRange(5, 5 + TAMANHO_DESAFIO)
        trabalho.execute {
            val resposta = try {
                ChaveCelular.responderDesafio(this, desafio)?.plus(SW_OK) ?: SW_NAO_ATIVADO
            } catch (e: Exception) {
                Log.w(TAG, "Não assinou o desafio", e)
                SW_ERRO
            }
            sendResponseApdu(resposta)
        }
        return null
    }

    override fun onDeactivated(reason: Int) {
        // O terminal manda DESELECT no fim, ou o celular saiu do campo. Nada a guardar.
    }

    override fun onDestroy() {
        trabalho.shutdown()
        super.onDestroy()
    }

    private fun ehSelect(apdu: ByteArray) =
        apdu.size >= 5 + AID.size &&
            apdu[0] == 0x00.toByte() && apdu[1] == 0xA4.toByte() && apdu[2] == 0x04.toByte() &&
            apdu[4].toInt() == AID.size &&
            apdu.copyOfRange(5, 5 + AID.size).contentEquals(AID)

    private fun ehAssinar(apdu: ByteArray) =
        apdu.size >= 5 + TAMANHO_DESAFIO &&
            apdu[0] == 0x80.toByte() && apdu[1] == INS_ASSINAR &&
            apdu[4].toInt() == TAMANHO_DESAFIO

    companion object {
        private const val TAG = "PasseHce"
        private const val VERSAO_PROTOCOLO: Byte = 0x01
        private const val INS_ASSINAR: Byte = 0x10
        private const val TAMANHO_DESAFIO = 32

        // F0 + "PASSE" + 01. O mesmo do apduservice.xml e do firmware (arduino/src/celular.cpp).
        private val AID = byteArrayOf(0xF0.toByte(), 0x50, 0x41, 0x53, 0x53, 0x45, 0x01)

        private val SW_OK = byteArrayOf(0x90.toByte(), 0x00)
        private val SW_NAO_ATIVADO = byteArrayOf(0x69, 0x85.toByte())
        private val SW_INS_DESCONHECIDA = byteArrayOf(0x6D, 0x00)
        private val SW_ERRO = byteArrayOf(0x6F, 0x00)
    }
}
