// Deterministic frame renderer: drives index.html's renderFrame(i) in headless Chromium.
//   node render.mjs stills 0.5 2.1 13.2      -> out/stills/*.png  (quick look at given seconds)
//   node render.mjs frames [workers]         -> out/frames/f0000.jpg … f0899.jpg
import { createRequire } from 'module';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const require = createRequire(import.meta.url);
let playwright;
try { playwright = require('playwright'); } catch { playwright = require('/opt/node22/lib/node_modules/playwright'); }

const DIR = path.dirname(fileURLToPath(import.meta.url));
const URL = 'file://' + path.join(DIR, 'index.html') + '?render';
const FPS = 30, TOTAL = 900;
const [mode = 'frames', ...args] = process.argv.slice(2);

async function openPage(browser) {
  const page = await browser.newPage({ viewport: { width: 540, height: 960 } });
  page.on('pageerror', e => console.error('PAGE ERROR', e.message));
  page.on('console', m => { if (m.type() === 'error') console.error('console:', m.text()); });
  await page.goto(URL);
  await page.evaluate(() => window.ready);
  return page;
}
const grab = (page, i, type, q) => page.evaluate(([i, type, q]) => {
  window.renderFrame(i);
  return document.getElementById('c').toDataURL(type, q).split(',')[1];
}, [i, type, q]);

const browser = await playwright.chromium.launch({ args: ['--disable-gpu-vsync'] });
if (mode === 'stills') {
  const out = path.join(DIR, 'out/stills'); fs.mkdirSync(out, { recursive: true });
  const page = await openPage(browser);
  for (const s of args) {
    const i = Math.round(parseFloat(s) * FPS);
    fs.writeFileSync(path.join(out, `f${String(i).padStart(4, '0')}.png`), Buffer.from(await grab(page, i, 'image/png'), 'base64'));
  }
} else {
  const workers = parseInt(args[0] || '4', 10);
  const out = path.join(DIR, 'out/frames'); fs.mkdirSync(out, { recursive: true });
  const t0 = Date.now(); let done = 0;
  await Promise.all(Array.from({ length: workers }, async (_, w) => {
    const page = await openPage(browser);
    for (let i = w; i < TOTAL; i += workers) {
      fs.writeFileSync(path.join(out, `f${String(i).padStart(4, '0')}.jpg`), Buffer.from(await grab(page, i, 'image/jpeg', 0.95), 'base64'));
      if (++done % 60 === 0) console.log(`${done}/${TOTAL} frames  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
    }
  }));
}
await browser.close();
