export interface Clock {
  now(): Date;
}

export const systemClock: Clock = { now: () => new Date() };

/** Data e hora "de parede" no fuso do prédio. */
export interface LocalDateTime {
  /** YYYY-MM-DD */
  date: string;
  /** HH:MM */
  time: string;
  /** minutos desde a meia-noite */
  minutes: number;
}

export function toLocal(instant: Date, timeZone: string): LocalDateTime {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(instant);
  const get = (type: Intl.DateTimeFormatPartTypes) => parts.find((p) => p.type === type)?.value ?? '00';
  const hour = get('hour');
  const minute = get('minute');
  return {
    date: `${get('year')}-${get('month')}-${get('day')}`,
    time: `${hour}:${minute}`,
    minutes: Number(hour) * 60 + Number(minute),
  };
}

export function timeToMinutes(hhmm: string): number {
  const [h = '0', m = '0'] = hhmm.split(':');
  return Number(h) * 60 + Number(m);
}

/** Converte YYYY-MM-DD em Date (meia-noite UTC), como o Postgres guarda colunas DATE. */
export const dateOnlyToDate = (value: string) => new Date(`${value}T00:00:00.000Z`);
export const dateToDateOnly = (value: Date) => value.toISOString().slice(0, 10);

/** Soma (ou subtrai) dias a uma data YYYY-MM-DD. */
export const somarDias = (data: string, dias: number) =>
  dateToDateOnly(new Date(dateOnlyToDate(data).getTime() + dias * 86_400_000));

/** Quanto o relógio do fuso está à frente do UTC naquele instante, em ms (Brasília: -3 h). */
function diferencaDoFuso(instante: Date, timeZone: string): number {
  const local = toLocal(instante, timeZone);
  return Date.parse(`${local.date}T${local.time}:00.000Z`) - Math.floor(instante.getTime() / 60_000) * 60_000;
}

/** Instante em que começa o dia YYYY-MM-DD (00:00) no fuso do prédio. */
export function inicioDoDiaLocal(data: string, timeZone: string): Date {
  const meiaNoite = dateOnlyToDate(data).getTime();
  // Duas passadas, porque a diferença pode mudar perto da meia-noite (horário de verão).
  // Se naquele dia o relógio pulou de 23:59 para 01:00, o dia começa na 01:00 (o palpite).
  const palpite = new Date(meiaNoite - diferencaDoFuso(new Date(meiaNoite), timeZone));
  const ajustado = new Date(meiaNoite - diferencaDoFuso(palpite, timeZone));
  return toLocal(ajustado, timeZone).date === data ? ajustado : palpite;
}

/** Último milissegundo do dia YYYY-MM-DD (23:59:59.999) no fuso do prédio. */
export const fimDoDiaLocal = (data: string, timeZone: string) =>
  new Date(inicioDoDiaLocal(somarDias(data, 1), timeZone).getTime() - 1);
