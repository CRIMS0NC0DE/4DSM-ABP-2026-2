export interface Coordenadas {
  latitude: number;
  longitude: number;
}

const RAIO_TERRA_METROS = 6_371_000;
const rad = (graus: number) => (graus * Math.PI) / 180;

/** Distância em metros entre dois pontos (fórmula de Haversine). */
export function distanciaEmMetros(a: Coordenadas, b: Coordenadas): number {
  const dLat = rad(b.latitude - a.latitude);
  const dLon = rad(b.longitude - a.longitude);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * RAIO_TERRA_METROS * Math.asin(Math.sqrt(h));
}
