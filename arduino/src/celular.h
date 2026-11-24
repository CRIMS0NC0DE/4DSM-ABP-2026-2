#pragma once
#include <Arduino.h>
#include <MFRC522.h>

// Celular Android como chave: o app Passe emula um cartão ISO 14443-4 (HCE) e o
// terminal conversa com ele por APDUs, pelo mesmo leitor RC522 das tags.
// Protocolo em backend/src/modules/phones/phone-signature.ts e em
// docs/documentacao-tecnica/celular-nfc.md.
namespace celular {

enum class Leitura {
  OK,           // o celular assinou o desafio
  SEM_APP,      // fala ISO 14443-4, mas não respondeu ao AID do Passe (outro cartão, ou celular sem o app)
  NAO_ATIVADO,  // tem o app, mas o celular ainda não foi ativado como chave
  FALHOU,       // a conversa caiu no meio (celular afastou, tempo esgotado)
};

struct Resposta {
  String celularId;   // UUID, como o backend guarda
  String assinatura;  // 64 bytes (r||s) em base64
};

// O cartão que acabou de ser selecionado fala ISO 14443-4? (SAK bit 6, que é como o Android emula.)
bool ehIsoDep(const MFRC522::Uid& uid);

// Ativa o protocolo (RATS), seleciona o app Passe e pede a assinatura do SHA-256 de `qr`.
// Chame logo depois de PICC_ReadCardSerial(). No fim, o celular fica desligado do leitor
// (DESELECT) e só responde de novo quando for afastado e aproximado.
Leitura autenticar(MFRC522& nfc, const String& qr, Resposta& saida);

}  // namespace celular
