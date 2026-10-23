// Gera a linha do arquivo de senhas do Mosquitto (docker/mosquitto/passwd), no
// mesmo formato do mosquitto_passwd (PBKDF2-SHA512, "$7$"), sem precisar do Docker.
//
//   node scripts/mqtt-senha.mjs <usuario> <senha>            imprime a linha
//   node scripts/mqtt-senha.mjs <usuario> <senha> <arquivo>  grava/troca no arquivo
//
// Terminal: usuário = Id do terminal, senha = chave do terminal.
// Depois de mudar o arquivo, reinicie o broker:
//   docker compose -f docker-compose.dev.yml restart mqtt
import { pbkdf2Sync, randomBytes } from 'node:crypto';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const ITERACOES = 101;

export function linhaSenha(usuario, senha) {
  const sal = randomBytes(12);
  const hash = pbkdf2Sync(senha, sal, ITERACOES, 64, 'sha512');
  return `${usuario}:$7$${ITERACOES}$${sal.toString('base64')}$${hash.toString('base64')}`;
}

/** Grava o usuário no arquivo de senhas, trocando a linha dele se já existir. */
export function gravarSenha(arquivo, usuario, senha) {
  const outras = existsSync(arquivo)
    ? readFileSync(arquivo, 'utf8')
        .split('\n')
        .filter((l) => l.trim() && !l.startsWith(`${usuario}:`))
    : [];
  writeFileSync(arquivo, [...outras, linhaSenha(usuario, senha)].join('\n') + '\n');
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [usuario, senha, arquivo] = process.argv.slice(2);
  if (!usuario || !senha || usuario.includes(':')) {
    console.error('Uso: node scripts/mqtt-senha.mjs <usuario> <senha> [arquivo]');
    process.exit(1);
  }
  if (arquivo) {
    gravarSenha(arquivo, usuario, senha);
    console.info(`Usuário "${usuario}" gravado em ${arquivo}.`);
  } else {
    console.info(linhaSenha(usuario, senha));
  }
}
