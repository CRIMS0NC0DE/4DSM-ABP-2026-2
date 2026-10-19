// Dados fixos da demonstração, usados pelo seed e pelo simulador do terminal.

export const DEMO_SENHA = 'passe123';

export const DEMO_IDS = {
  edificio: '00000000-0000-4000-8000-000000000001',
  portaria: '00000000-0000-4000-8000-000000000002',
  porta: '00000000-0000-4000-8000-000000000003',
  catraca: '00000000-0000-4000-8000-000000000004',
  terminal: '00000000-0000-4000-8000-000000000005',
  autorizacaoMorador: '00000000-0000-4000-8000-000000000006',
  autorizacaoVisitante: '00000000-0000-4000-8000-000000000007',
};

// Chave fixa só para desenvolvimento; em produção cadastre o terminal pela API.
export const demoChaveTerminal = (env: NodeJS.ProcessEnv = process.env) => env.TERMINAL_DEMO_KEY ?? 'chave-demo-terminal-catraca-1';

// Coordenada aproximada: ajuste pela tela "Locais" com o ponto real da catraca.
export const DEMO_CATRACA_POS = { latitude: -23.3053, longitude: -45.9658 };

export const DEMO_TAG_UID = '04A1B2C3';
