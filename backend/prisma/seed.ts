// Dados de demonstração. Pode rodar várias vezes: atualiza em vez de duplicar.
// npm run db:seed
import 'dotenv/config';
import { DEMO_CATRACA_POS, DEMO_IDS, DEMO_SENHA, DEMO_TAG_UID, demoChaveTerminal } from '../src/database/demo.js';
import { createPrisma } from '../src/database/prisma.js';
import { hashChave, hashSenha } from '../src/shared/security.js';

const db = createPrisma(process.env.DATABASE_URL ?? 'postgresql://app:app@localhost:5432/app');

// Mesmas contas do frontend/Contas.MD (senha passe123).
const SENHA = DEMO_SENHA;
const CHAVE_TERMINAL_DEMO = demoChaveTerminal();
const IDS = DEMO_IDS;

async function main() {
  const senhaHash = await hashSenha(SENHA);
  const pessoas = [
    { nome: 'Carlos Lima', email: 'admin@passe.com', cpf: '11111111111', perfil: 'ADMIN' },
    { nome: 'Paula Rocha', email: 'portaria@passe.com', cpf: '22222222222', perfil: 'CONTROLADOR_ACESSO' },
    { nome: 'Maria Souza', email: 'morador@passe.com', cpf: '33333333333', perfil: 'CONDOMINO' },
    { nome: 'Ana Lima', email: 'visitante@passe.com', cpf: '44444444444', perfil: 'VISITANTE' },
  ] as const;

  const users = [];
  for (const p of pessoas) {
    users.push(await db.user.upsert({ where: { email: p.email }, update: {}, create: { ...p, senhaHash } }));
  }
  const [, , maria, ana] = users;

  await db.building.upsert({
    where: { id: IDS.edificio },
    update: {},
    create: { id: IDS.edificio, nome: 'FATEC Jacareí', endereco: 'Av. Faria Lima, 155 - Jacareí/SP' },
  });
  await db.gate.upsert({ where: { id: IDS.portaria }, update: {}, create: { id: IDS.portaria, nome: 'Portaria Principal', buildingId: IDS.edificio } });
  await db.door.upsert({ where: { id: IDS.porta }, update: {}, create: { id: IDS.porta, nome: 'Porta A', gateId: IDS.portaria } });
  await db.accessPoint.upsert({
    where: { id: IDS.catraca },
    update: {},
    create: { id: IDS.catraca, nome: 'Catraca 1', doorId: IDS.porta, ...DEMO_CATRACA_POS, raioMetros: 100 },
  });
  await db.terminal.upsert({
    where: { id: IDS.terminal },
    update: { chaveHash: hashChave(CHAVE_TERMINAL_DEMO) },
    create: { id: IDS.terminal, nome: 'Terminal Catraca 1', accessPointId: IDS.catraca, chaveHash: hashChave(CHAVE_TERMINAL_DEMO) },
  });
  await db.nfcTag.upsert({ where: { uid: DEMO_TAG_UID }, update: {}, create: { uid: DEMO_TAG_UID, userId: maria!.id } });

  const hoje = new Date();
  const dia = (deslocamento: number) => new Date(Date.UTC(hoje.getUTCFullYear(), hoje.getUTCMonth(), hoje.getUTCDate() + deslocamento));
  await db.authorization.upsert({
    where: { id: IDS.autorizacaoMorador },
    update: {},
    create: {
      id: IDS.autorizacaoMorador,
      userId: maria!.id,
      accessPointId: IDS.catraca,
      dataInicio: dia(-1),
      dataFim: dia(180),
      horaInicio: '06:00',
      horaFim: '23:00',
      maxUsos: 1000,
    },
  });
  await db.authorization.upsert({
    where: { id: IDS.autorizacaoVisitante },
    update: {},
    create: {
      id: IDS.autorizacaoVisitante,
      userId: ana!.id,
      accessPointId: IDS.catraca,
      dataInicio: dia(0),
      dataFim: dia(0),
      horaInicio: '14:00',
      horaFim: '16:00',
      maxUsos: 1,
    },
  });

  console.info('Seed concluído.');
  console.info(`  Contas: admin@, portaria@, morador@, visitante@passe.com (senha ${SENHA})`);
  console.info(`  Terminal: X-Terminal-Id=${IDS.terminal}  X-Terminal-Key=${CHAVE_TERMINAL_DEMO}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => db.$disconnect());
