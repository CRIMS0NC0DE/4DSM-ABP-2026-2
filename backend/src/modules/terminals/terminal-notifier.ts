export interface DecisaoTerminal {
  acao: 'ABRIR' | 'NEGAR';
  metodo: 'QR' | 'NFC';
  mensagem: string;
  motivo?: string;
  nome?: string;
  em: string;
}

/** Avisa o terminal da decisão para ele abrir a catraca ou sinalizar a negação. */
export interface TerminalNotifier {
  enviar(terminalId: string, decisao: DecisaoTerminal): void | Promise<void>;
}

/**
 * Guarda as últimas decisões de cada terminal para quem consulta por HTTP
 * (GET /terminal/decisions). O MQTT entra como outro notificador.
 */
export class InMemoryTerminalNotifier implements TerminalNotifier {
  private seq = 0;
  private readonly filas = new Map<string, { seq: number; decisao: DecisaoTerminal }[]>();

  constructor(private readonly maxPorTerminal = 20) {}

  enviar(terminalId: string, decisao: DecisaoTerminal): void {
    const fila = this.filas.get(terminalId) ?? [];
    fila.push({ seq: ++this.seq, decisao });
    this.filas.set(terminalId, fila.slice(-this.maxPorTerminal));
  }

  desde(terminalId: string, aposSeq: number) {
    return (this.filas.get(terminalId) ?? []).filter((item) => item.seq > aposSeq);
  }
}

export class CompositeTerminalNotifier implements TerminalNotifier {
  constructor(private readonly notifiers: TerminalNotifier[]) {}

  async enviar(terminalId: string, decisao: DecisaoTerminal): Promise<void> {
    await Promise.allSettled(this.notifiers.map((n) => n.enviar(terminalId, decisao)));
  }
}
