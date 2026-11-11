# Arquitetura Geral do Sistema

| Campo | Valor |
|---|---|
| Projeto | 4DSM-ABP-2026-2 |
| Revisão | 11/11/2026 |

> **Nota:** documento preliminar baseado nos achados de uma análise anterior. O acesso atual ao GitHub não foi confirmado nesta sessão. Nomes de serviços, versões, rotas, tabelas e configurações precisam ser validados no repositório antes da aprovação.

## 1. Objetivo

Apresentar a visão de alto nível do sistema, seus principais componentes e suas interações no gerenciamento e execução de operações de controle de acesso.

## 2. Visão geral

Foram identificados anteriormente: aplicativo Flutter, backend/API, persistência gerenciada por Prisma, terminais ESP32, leitor NFC RC522, comunicação MQTT, mecanismos de QR Code e NFC, Docker e pipelines de CI/CD.

A composição exata dos ambientes e a topologia de implantação precisam ser confirmadas nos arquivos atuais.

## 3. Componentes e responsabilidades

### Aplicativo móvel
Aplicativo Flutter que oferece a interface aos usuários. A análise anterior identificou autenticação, interação com autorizações e fluxos de apresentação/leitura de QR Code. A disponibilidade de cada tela deve ser conferida na versão atual.

### Backend/API
Concentra regras de negócio e disponibiliza serviços. Foram identificadas responsabilidades relacionadas a autenticação, perfis, hierarquia de locais, autorizações, validação de credenciais e registro de eventos. Rotas e módulos serão detalhados na documentação técnica.

### Persistência
Foi identificado uso de Prisma e dez modelos no schema, conforme análise anterior. Entidades, campos e relacionamentos devem ser extraídos do schema atual; não são presumidos neste documento.

### Terminal embarcado
Firmware ESP32 integrado ao leitor NFC RC522, acionamento de relé, sinalização de resultado e comunicação com os serviços. O comportamento seguro em falhas de rede deve ser conferido no código e testado em hardware.

### Comunicação MQTT
Mecanismo de comunicação envolvendo os terminais. Tópicos, payloads, QoS, autenticação e ACLs precisam ser confirmados nas configurações atuais.

### QR Code e NFC
O sistema contempla fluxos de identificação por QR Code e NFC. A análise anterior registrou QR rotativo a cada 10 segundos e validade observada de 30 segundos; confirmar no código atual e alinhar diagramas. NFC foi associado ao leitor RC522.

## 4. Fluxo conceitual de acesso

1. O usuário apresenta uma credencial pelo aplicativo ou por cartão/tag NFC.
2. O componente responsável recebe a credencial.
3. A validação considera as regras implementadas no backend e/ou no terminal.
4. O resultado é comunicado ao terminal pelo mecanismo implementado.
5. Em caso de autorização, o terminal pode acionar o mecanismo físico.
6. O resultado é registrado conforme as regras de auditoria e persistência.

> Fluxo conceitual, não contrato técnico. Confirmar sequência real nos handlers, serviços, publicadores/consumidores MQTT e firmware.

## 5. Segurança e confiabilidade

Documentar autenticação de usuários e dispositivos, autorização por perfil/escopo, validade e prevenção de reutilização de credenciais, proteção de secrets, ACL MQTT, TLS, perda de conexão e prevenção de abertura por decisões antigas.

A análise anterior apontou fallback TLS inseguro no firmware e risco de decisão offline antiga permanecer em fila em memória. Tratar como pontos de revisão, não como problemas necessariamente ainda presentes.

## 6. Infraestrutura

Foram identificados Docker, workflows CI/CD e publicação de imagens de contêiner. Ambientes, serviços externos, secrets, deploy e rollback devem ser confirmados nos arquivos atuais.

## 7. Pendências de validação

- Confirmar limites entre aplicativo, backend, broker e firmware.
- Confirmar fluxo QR e janela de validade.
- Confirmar tópicos e payloads MQTT.
- Extrair modelo de dados do schema Prisma.
- Documentar deploy e ambientes reais.
- Validar tratamento de perda de rede e modo offline.
- Corrigir divergências entre diagramas e implementação.
- Classificar funcionalidades como implementadas, parciais ou planejadas.


