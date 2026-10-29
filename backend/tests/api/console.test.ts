import { describe, expect, it } from 'vitest';
import { montarCenario } from '../support/test-app.js';

describe('Console web de testes (/console)', () => {
  it('serve a página, o script e o estilo', async () => {
    const { api } = await montarCenario();

    const pagina = await api.get('/console/');
    expect(pagina.status).toBe(200);
    expect(pagina.text).toContain('console de testes');

    for (const arquivo of ['app.js', 'style.css']) {
      expect((await api.get(`/console/${arquivo}`)).status, arquivo).toBe(200);
    }
  });

  it('não depende de script inline, que a política de conteúdo bloquearia', async () => {
    const { api } = await montarCenario();
    const pagina = await api.get('/console/');
    expect(pagina.headers['content-security-policy']).toContain("script-src 'self'");
    expect(pagina.text).not.toMatch(/<script(?![^>]*\bsrc=)[^>]*>/);
    expect(pagina.text).not.toMatch(/\son[a-z]+=/);
  });
});
