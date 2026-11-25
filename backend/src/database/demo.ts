// Dados fixos da demonstração, usados pelo seed e pelo simulador do terminal.
import { existsSync, readFileSync } from 'node:fs';

export const DEMO_SENHA = 'passe123';

export const DEMO_IDS = {
  edificio: '00000000-0000-4000-8000-000000000001',
  portaria: '00000000-0000-4000-8000-000000000002',
  porta: '00000000-0000-4000-8000-000000000003',
  catraca: '00000000-0000-4000-8000-000000000004',
  terminal: '00000000-0000-4000-8000-000000000005',
  autorizacaoMorador: '00000000-0000-4000-8000-000000000006',
  autorizacaoVisitante: '00000000-0000-4000-8000-000000000007',
  comunicadoBoasVindas: '00000000-0000-4000-8000-000000000008',
};

/**
 * TERMINAL_DEMO_KEY do .env da raiz do repositório (o do docker compose), onde o
 * provisionar-terminal.mjs guarda a chave trocada do terminal de demonstração. No Docker o
 * compose já passa a variável; isto cobre o seed e a API rodando direto no Node, que só
 * leem o backend/.env. Sem isso, um "npm run db:seed" fora do Docker voltava a chave do
 * banco para a padrão e o ESP32 levava 401.
 */
function chaveDoEnvDaRaiz(): string | undefined {
  const arquivo = new URL('../../../.env', import.meta.url);
  if (!existsSync(arquivo)) return undefined;
  return readFileSync(arquivo, 'utf8').match(/^TERMINAL_DEMO_KEY=(.+)$/m)?.[1]?.trim() || undefined;
}

// Chave fixa só para desenvolvimento; em produção cadastre o terminal pela API.
export const demoChaveTerminal = (env: NodeJS.ProcessEnv = process.env) =>
  env.TERMINAL_DEMO_KEY ?? chaveDoEnvDaRaiz() ?? 'chave-demo-terminal-catraca-1';

// Coordenada aproximada: ajuste pela tela "Locais" com o ponto real da catraca.
export const DEMO_CATRACA_POS = { latitude: -23.3053, longitude: -45.9658 };

export const DEMO_TAG_UID = '04A1B2C3';
