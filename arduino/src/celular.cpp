// Conversa ISO 14443-4 (T=CL) com o celular, direto nos registradores do RC522.
//
// Por que não usar o MFRC522Extended da biblioteca: o PCD_CommunicateWithPICC desiste
// depois de 36 ms fixos, e o celular pode demorar mais que isso para assinar (a chave
// fica no Keystore). Ele também não atende o pedido de mais tempo do celular (S(WTX))
// e o laço de respostas encadeadas não termina. Aqui o tempo de espera vem do ATS do
// celular, o WTX é atendido e a resposta de 82 bytes, que chega em dois quadros, é juntada.
#include "celular.h"

#include <mbedtls/base64.h>
#include <mbedtls/sha256.h>
#include <mbedtls/version.h>

namespace celular {
namespace {

// AID proprietário do Passe: F0 + "PASSE" + versão 01. O mesmo do apduservice.xml do app.
const byte AID[] = {0xF0, 0x50, 0x41, 0x53, 0x53, 0x45, 0x01};
const byte VERSAO_PROTOCOLO = 0x01;
const byte INS_ASSINAR = 0x10;
const size_t BYTES_ID = 16;
const size_t BYTES_ASSINATURA = 64;

const uint32_t ESPERA_MINIMA_MS = 100;  // alguns celulares respondem perto do limite do FWT
const uint32_t ESPERA_MAXIMA_MS = 1500;
const uint16_t RECARGA_PADRAO = 0x03E8;  // 25 ms, o mesmo do PCD_Init()

struct Sessao {
  MFRC522& nfc;
  byte bloco;        // número do bloco (regras A e B da ISO 14443-4)
  uint32_t fwtMs;    // tempo que o celular tem para responder
};

void definirTimer(MFRC522& nfc, uint32_t ms) {
  // Timer de 40 kHz (25 µs por passo), configurado no PCD_Init().
  const uint32_t passos = min<uint32_t>(ms * 40, 0xFFFF);
  nfc.PCD_WriteRegister(MFRC522::TReloadRegH, passos >> 8);
  nfc.PCD_WriteRegister(MFRC522::TReloadRegL, passos & 0xFF);
}

// Manda um quadro (com CRC_A) e espera a resposta por até `esperaMs`.
// Devolve em `volta` a resposta sem o CRC. Quadros de até 62 bytes + CRC (FSD = 64).
bool quadro(MFRC522& nfc, const byte* envio, byte n, byte* volta, byte& tam, uint32_t esperaMs) {
  byte buf[64];
  if (n > sizeof(buf) - 2) return false;
  memcpy(buf, envio, n);
  if (nfc.PCD_CalculateCRC(buf, n, &buf[n]) != MFRC522::STATUS_OK) return false;
  n += 2;

  definirTimer(nfc, esperaMs);
  nfc.PCD_WriteRegister(MFRC522::CommandReg, MFRC522::PCD_Idle);
  nfc.PCD_WriteRegister(MFRC522::ComIrqReg, 0x7F);
  nfc.PCD_WriteRegister(MFRC522::FIFOLevelReg, 0x80);
  nfc.PCD_WriteRegister(MFRC522::FIFODataReg, n, buf);
  nfc.PCD_WriteRegister(MFRC522::BitFramingReg, 0x00);
  nfc.PCD_WriteRegister(MFRC522::CommandReg, MFRC522::PCD_Transceive);
  nfc.PCD_SetRegisterBitMask(MFRC522::BitFramingReg, 0x80);  // StartSend

  bool recebeu = false;
  const uint32_t limite = millis() + esperaMs + 20;
  while ((int32_t)(millis() - limite) < 0) {
    const byte irq = nfc.PCD_ReadRegister(MFRC522::ComIrqReg);
    if (irq & 0x30) {  // RxIRq ou IdleIRq
      recebeu = true;
      break;
    }
    if (irq & 0x01) break;  // TimerIRq: o celular não respondeu a tempo
    yield();
  }
  // Volta ao tempo padrão, que é o que o PICC_IsNewCardPresent() da biblioteca espera.
  nfc.PCD_WriteRegister(MFRC522::TReloadRegH, RECARGA_PADRAO >> 8);
  nfc.PCD_WriteRegister(MFRC522::TReloadRegL, RECARGA_PADRAO & 0xFF);
  if (!recebeu) return false;
  if (nfc.PCD_ReadRegister(MFRC522::ErrorReg) & 0x13) return false;  // BufferOvfl, Parity, Protocol

  const byte recebidos = nfc.PCD_ReadRegister(MFRC522::FIFOLevelReg);
  if (recebidos < 3 || recebidos > tam) return false;
  nfc.PCD_ReadRegister(MFRC522::FIFODataReg, recebidos, volta, 0);
  // O CRC usa a FIFO: só depois de copiar a resposta.
  byte crc[2];
  if (nfc.PCD_CalculateCRC(volta, recebidos - 2, crc) != MFRC522::STATUS_OK) return false;
  if (crc[0] != volta[recebidos - 2] || crc[1] != volta[recebidos - 1]) return false;
  tam = recebidos - 2;
  return true;
}

// RATS com FSD = 64 e CID = 0. Lê o FWI do ATS para saber quanto esperar.
bool ativar(Sessao& s) {
  const byte rats[] = {0xE0, 0x50};
  byte ats[64];
  byte tam = sizeof(ats);
  if (!quadro(s.nfc, rats, sizeof(rats), ats, tam, ESPERA_MINIMA_MS) || tam < 1) return false;

  byte fwi = 4;  // padrão da norma quando o TB1 não vem
  if (tam >= 2) {
    const byte t0 = ats[1];
    byte i = 2;
    if (t0 & 0x10) i++;                          // TA1
    if ((t0 & 0x20) && i < tam) fwi = ats[i] >> 4;  // TB1: FWI no nibble de cima
  }
  if (fwi > 14) fwi = 4;
  // FWT = 302 µs × 2^FWI
  const uint32_t fwt = (302UL << fwi) / 1000 + 1;
  s.fwtMs = constrain(fwt * 2, ESPERA_MINIMA_MS, ESPERA_MAXIMA_MS);
  s.bloco = 0;
  return true;
}

// Manda uma APDU num I-block e junta a resposta. Atende S(WTX) e respostas encadeadas.
bool apdu(Sessao& s, const byte* comando, byte n, byte* resposta, size_t& tam) {
  byte envio[64];
  if (n + 1 > sizeof(envio)) return false;
  envio[0] = 0x02 | s.bloco;  // I-block, sem CID e sem NAD
  memcpy(&envio[1], comando, n);
  byte tamEnvio = n + 1;

  size_t juntou = 0;
  uint32_t espera = s.fwtMs;
  for (int voltas = 0; voltas < 16; voltas++) {
    byte volta[64];
    byte tamVolta = sizeof(volta);
    if (!quadro(s.nfc, envio, tamEnvio, volta, tamVolta, espera)) return false;
    espera = s.fwtMs;

    const byte pcb = volta[0];
    byte i = 1;
    if (pcb & 0x08) i++;  // CID

    if ((pcb & 0xF7) == 0xF2) {
      // S(WTX): o celular pede mais tempo. Devolve o mesmo multiplicador.
      if (i >= tamVolta) return false;
      const byte wtxm = volta[i] & 0x3F;
      if (wtxm == 0) return false;
      envio[0] = 0xF2;
      envio[1] = wtxm;
      tamEnvio = 2;
      espera = min<uint32_t>(s.fwtMs * wtxm, ESPERA_MAXIMA_MS);
      continue;
    }

    if ((pcb & 0xE2) != 0x02) return false;  // esperava um I-block
    if (pcb & 0x04) i++;                     // NAD
    s.bloco ^= 1;                            // regra B: recebeu o I-block com o nosso número
    const size_t dados = tamVolta > i ? tamVolta - i : 0;
    if (juntou + dados > tam) return false;
    memcpy(&resposta[juntou], &volta[i], dados);
    juntou += dados;

    if (!(pcb & 0x10)) {  // último pedaço
      tam = juntou;
      return true;
    }
    envio[0] = 0xA2 | s.bloco;  // R(ACK): manda o próximo pedaço
    tamEnvio = 1;
  }
  return false;
}

void desligar(Sessao& s) {
  const byte deselect[] = {0xC2};
  byte volta[8];
  byte tam = sizeof(volta);
  quadro(s.nfc, deselect, sizeof(deselect), volta, tam, s.fwtMs);
}

bool terminaCom(const byte* r, size_t tam, byte sw1, byte sw2) {
  return tam >= 2 && r[tam - 2] == sw1 && r[tam - 1] == sw2;
}

void sha256(const String& texto, byte* saida) {
#if MBEDTLS_VERSION_MAJOR >= 3
  mbedtls_sha256(reinterpret_cast<const unsigned char*>(texto.c_str()), texto.length(), saida, 0);
#else
  mbedtls_sha256_ret(reinterpret_cast<const unsigned char*>(texto.c_str()), texto.length(), saida, 0);
#endif
}

String uuid(const byte* b) {
  char s[37];
  snprintf(s, sizeof(s), "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
           b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]);
  return String(s);
}

String base64(const byte* dados, size_t n) {
  unsigned char s[96];
  size_t usados = 0;
  if (mbedtls_base64_encode(s, sizeof(s) - 1, &usados, dados, n) != 0) return String();
  s[usados] = '\0';
  return String(reinterpret_cast<char*>(s));
}

}  // namespace

bool ehIsoDep(const MFRC522::Uid& uid) { return (uid.sak & 0x24) == 0x20; }

Leitura autenticar(MFRC522& nfc, const String& qr, Resposta& saida) {
  Sessao s{nfc, 0, ESPERA_MINIMA_MS};
  if (!ativar(s)) return Leitura::FALHOU;

  // SELECT pelo AID do Passe
  byte select[5 + sizeof(AID) + 1] = {0x00, 0xA4, 0x04, 0x00, sizeof(AID)};
  memcpy(&select[5], AID, sizeof(AID));
  select[sizeof(select) - 1] = 0x00;
  byte r[128];
  size_t tam = sizeof(r);
  if (!apdu(s, select, sizeof(select), r, tam)) {
    desligar(s);
    return Leitura::FALHOU;
  }
  if (!terminaCom(r, tam, 0x90, 0x00) || tam < 3 || r[0] != VERSAO_PROTOCOLO) {
    desligar(s);
    return Leitura::SEM_APP;
  }

  // ASSINAR: o desafio é o SHA-256 do QR que está na tela agora.
  byte assinar[5 + 32 + 1] = {0x80, INS_ASSINAR, 0x00, 0x00, 32};
  sha256(qr, &assinar[5]);
  assinar[sizeof(assinar) - 1] = 0x00;
  tam = sizeof(r);
  const bool respondeu = apdu(s, assinar, sizeof(assinar), r, tam);
  desligar(s);
  if (!respondeu) return Leitura::FALHOU;
  if (terminaCom(r, tam, 0x69, 0x85)) return Leitura::NAO_ATIVADO;  // app sem chave ativada
  if (!terminaCom(r, tam, 0x90, 0x00) || tam != BYTES_ID + BYTES_ASSINATURA + 2) return Leitura::FALHOU;

  saida.celularId = uuid(r);
  saida.assinatura = base64(&r[BYTES_ID], BYTES_ASSINATURA);
  return saida.assinatura.length() ? Leitura::OK : Leitura::FALHOU;
}

}  // namespace celular
