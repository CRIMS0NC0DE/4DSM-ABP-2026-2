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
