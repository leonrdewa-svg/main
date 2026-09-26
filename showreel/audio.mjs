// Procedural score for the reel: 120 BPM (1 bar = 2 s), anime "royal road" progression (IV–V–iii–vi),
// every hit/whoosh placed on the same timestamps the picture cuts on. Writes reel.wav (44.1 kHz, 16-bit stereo).
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const SR = 44100, DUR = 30, N = SR * DUR, TAU = Math.PI * 2;
const L = new Float32Array(N), R = new Float32Array(N);       // dry bus
const RL = new Float32Array(N), RR = new Float32Array(N);     // reverb send
let seed = 12345; const rnd = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296);
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
const clamp = (x, a, b) => Math.max(a, Math.min(b, x));

function put(i, l, r, send = 0) { if (i < 0 || i >= N) return; L[i] += l; R[i] += r; RL[i] += l * send; RR[i] += r * send; }
function voice(t0, dur, fn, { pan = 0, gain = 1, send = 0.15 } = {}) {
  const s0 = Math.floor(t0 * SR), n = Math.floor(dur * SR), gl = gain * Math.cos((pan + 1) * Math.PI / 4), gr = gain * Math.sin((pan + 1) * Math.PI / 4);
  for (let k = 0; k < n; k++) { const v = fn(k / SR, k); put(s0 + k, v * gl, v * gr, send); }
}
// state-variable filter factory
function svf() { let lo = 0, bp = 0; return (x, fc, q = 0.7) => { const f = 2 * Math.sin(Math.PI * clamp(fc, 20, SR / 6) / SR); const hp = x - lo - bp / q * 0.7; bp += f * hp; lo += f * bp; return { lo, bp, hp }; }; }
const saw = ph => 2 * (ph - Math.floor(ph + 0.5));
const sq = ph => (ph % 1) < 0.5 ? 1 : -1;

/* ---------- drums ---------- */
const sidechain = new Float32Array(N).fill(1);
function kick(t, g = 1) {
  let ph = 0; voice(t, 0.45, (x) => { const f = 45 + 140 * Math.exp(-x * 28); ph += f / SR; return (Math.sin(TAU * ph) * Math.exp(-x * 7) + (x < 0.004 ? (rnd() - .5) * 0.8 : 0)) * g; }, { gain: 0.95, send: 0.02 });
  const s0 = Math.floor(t * SR); for (let k = 0; k < SR * 0.3; k++) if (s0 + k < N) sidechain[s0 + k] = Math.min(sidechain[s0 + k], 1 - 0.7 * Math.exp(-k / SR * 12));
}
function snare(t, g = 1) { const f = svf(); voice(t, 0.3, x => { const n = f(rnd() * 2 - 1, 3500, 0.8).bp; return (n * 1.6 * Math.exp(-x * 16) + Math.sin(TAU * 190 * x) * Math.exp(-x * 30) * 0.6) * g; }, { gain: 0.55, send: 0.25 }); }
function clap(t, g = 1) { const f = svf(); voice(t, 0.25, x => { const env = (x < 0.03 ? (Math.floor(x * 300) % 3 === 0 ? 1 : 0.3) : 1) * Math.exp(-x * 18); return f(rnd() * 2 - 1, 1800, 1.2).bp * env * 2.2 * g; }, { gain: 0.5, send: 0.35 }); }
function hat(t, g = 1, open = false) { const f = svf(); voice(t, open ? 0.25 : 0.06, x => f(rnd() * 2 - 1, 9000, 0.6).hp * Math.exp(-x * (open ? 14 : 70)) * g, { gain: 0.16, pan: (rnd() - .5) * 0.6, send: 0.05 }); }
function crash(t, g = 1) { const f = svf(); voice(t, 2.2, x => f(rnd() * 2 - 1, 7000, 0.5).hp * Math.exp(-x * 2.2) * g, { gain: 0.3, send: 0.3 }); }

/* ---------- FX ---------- */
function boom(t, g = 1, len = 2.2) {
  let ph = 0; const f = svf();
  voice(t, len, x => { const fr = 28 + 90 * Math.exp(-x * 5); ph += fr / SR; const sub = Math.sin(TAU * ph) * Math.exp(-x * 1.6);
    const nz = f(rnd() * 2 - 1, 200 + 4000 * Math.exp(-x * 6), 0.6).lo * Math.exp(-x * 3); return Math.tanh((sub * 1.2 + nz * 1.4) * 1.6) * g; }, { gain: 0.9, send: 0.4 });
}
function whoosh(t, dur, g = 1, pan = 0, up = true) {
  const f = svf(); voice(t, dur, x => { const u = x / dur, env = Math.sin(Math.PI * Math.pow(u, up ? 1.6 : 0.6)); const fc = up ? 300 + 5000 * u * u : 5000 - 4600 * u;
    return f(rnd() * 2 - 1, fc, 1.6).bp * env * 1.8 * g; }, { gain: 0.5, pan, send: 0.3 });
}
function riser(t, dur, g = 1) {
  const f = svf(); let ph = 0;
  voice(t, dur, x => { const u = x / dur; ph += (110 + 900 * u * u) / SR; return (f(rnd() * 2 - 1, 400 + 8000 * u * u, 1.2).bp * 1.2 + saw(ph) * 0.25) * u * u * g; }, { gain: 0.45, send: 0.35 });
}
function shing(t, g = 1) { voice(t, 1.6, x => (Math.sin(TAU * 2637 * x) + 0.6 * Math.sin(TAU * 3951 * x) + 0.3 * Math.sin(TAU * 5274 * x)) * Math.exp(-x * 3) * (0.8 + 0.2 * Math.sin(TAU * 18 * x)) * g, { gain: 0.14, send: 0.6 }); }
function zap(t, g = 1) { let ph = 0; voice(t, 0.12, x => { ph += (3000 * (1 - x * 6) + rnd() * 2000) / SR; return sq(ph) * Math.exp(-x * 30) * g; }, { gain: 0.08, pan: rnd() * 1.4 - 0.7, send: 0.2 }); }

/* ---------- tonal ---------- */
const CH = { F: [53, 57, 60, 64], G: [55, 59, 62, 65], Em: [52, 55, 59, 62], Am: [57, 60, 64, 67], E: [52, 56, 59, 62], C: [48, 55, 59, 62, 64], Fm7: [53, 57, 60, 64] };
const ROOT = { F: 41, G: 43, Em: 40, Am: 45, E: 40, C: 36 };
// chord per bar (bar = 2 s): 0 intro … 14 end
const PROG = ['Am', 'F', 'G', 'Em', 'F', 'G', 'Em', 'Am', 'F', 'G', 'Am', 'E', 'F', 'G', 'C'];
function pad(t, dur, notes, g = 1, bright = 1500) {
  notes.forEach((m, j) => { const f = svf(), f2 = svf(); const ph = [0, 0, 0, 0, 0, 0]; const det = [-0.12, -0.05, 0, 0.05, 0.12, 0.2];
    voice(t, dur + 0.6, (x, k) => { let s = 0; for (let d = 0; d < 6; d++) { ph[d] += mtof(m + det[d]) / SR; s += saw(ph[d]); }
      const env = Math.min(1, x / 0.25) * (x > dur ? Math.exp(-(x - dur) * 6) : 1); return f(s / 6, bright + 400 * Math.sin(x * 2), 0.7).lo * env * g; }, { gain: 0.11, pan: (j / (notes.length - 1) - .5) * 0.8, send: 0.45 }); });
}
function bassNote(t, dur, m, g = 1) { const f = svf(); let ph = 0, ph2 = 0; voice(t, dur, x => { ph += mtof(m) / SR; ph2 += mtof(m - 12) / SR; return f(saw(ph) * 0.7 + Math.sin(TAU * ph2) * 0.8, 180 + 1400 * Math.exp(-x * 14), 0.9).lo * Math.min(1, x / 0.005) * Math.exp(-x * 2) * g; }, { gain: 0.5, send: 0.02 }); }
function pluck(t, m, g = 1, pan = 0) { const f = svf(); let ph = 0; voice(t, 0.35, x => { ph += mtof(m) / SR; return f(saw(ph) + 0.5 * sq(ph * 1.003), 300 + 5000 * Math.exp(-x * 22), 0.8).lo * Math.exp(-x * 9) * g; }, { gain: 0.12, pan, send: 0.35 }); }
function lead(t, dur, m, g = 1) { const f = svf(); let ph = 0, ph2 = 0; voice(t, dur + 0.15, x => { const vib = x > 0.12 ? Math.sin(TAU * 6 * x) * 0.25 : 0; ph += mtof(m + vib) / SR; ph2 += mtof(m + vib + 0.08) / SR;
  const env = Math.min(1, x / 0.01) * (x > dur ? Math.exp(-(x - dur) * 25) : 1); return f(saw(ph) * 0.6 + sq(ph2) * 0.4, 3200, 0.8).lo * env * g; }, { gain: 0.13, send: 0.4 }); }
function bell(t, m, g = 1, pan = 0) { voice(t, 2.5, x => (Math.sin(TAU * mtof(m) * x) + 0.4 * Math.sin(TAU * mtof(m) * 2.76 * x) * Math.exp(-x * 4) + 0.2 * Math.sin(TAU * mtof(m) * 5.4 * x) * Math.exp(-x * 8)) * Math.exp(-x * 1.8) * g, { gain: 0.12, pan, send: 0.6 }); }

/* =================== ARRANGEMENT =================== */
const b = (bar, beat = 0) => bar * 2 + beat * 0.5;           // time of bar/beat
// 0–2  AWAKENING: drone, slit shing, heartbeat on pupil contraction, reverse swell
pad(0, 2, [45, 52, 57], 0.8, 500);
{ let ph = 0; voice(0, 2.1, x => { ph += 55 / SR; return Math.sin(TAU * ph) * Math.min(1, x) * 0.5; }, { gain: 0.5, send: 0.1 }); }
shing(0.3, 1); kick(1.15, 0.9); boom(1.17, 0.35, 1); riser(1.0, 1.0, 0.9); whoosh(1.6, 0.4, 1.2);
// 2–4  TITLE SLAM
boom(2, 1); kick(2); crash(2, 1.2); clap(2, 0.8); pad(2, 1.9, CH.F, 1.1, 2200); bassNote(2, 1, ROOT.F);
[2.5, 3, 3.5].forEach((t, i) => { kick(t, 0.8); hat(t + 0.25); }); clap(3, 0.9); bassNote(3, 1, ROOT.F);
[2.35, 2.45, 2.55].forEach(t => hat(t, 0.8)); whoosh(3.55, 0.45, 1.3, -0.3);
// 4–8  DIRECTION: half-time groove, pads, wind
for (let bar = 2; bar < 4; bar++) {
  const ch = PROG[bar]; pad(b(bar), 2, CH[ch], 1, 1700);
  kick(b(bar, 0)); kick(b(bar, 1.5), 0.7); snare(b(bar, 2)); if (bar === 3) kick(b(bar, 2.75), 0.6);
  for (let e = 0; e < 8; e++) hat(b(bar) + e * 0.25, e % 2 ? 0.6 : 1, e === 7);
  bassNote(b(bar), 1, ROOT[ch]); bassNote(b(bar, 2), 0.5, ROOT[ch]); bassNote(b(bar, 3), 0.5, ROOT[ch] + 12);
  [0, 1, 2, 3, 2, 1, 0, 1].forEach((n, e) => pluck(b(bar) + e * 0.25, CH[ch][n] + 12, 0.7, e % 2 ? 0.4 : -0.4));
}
{ const f = svf(); voice(4, 4, x => f(rnd() * 2 - 1, 500 + 300 * Math.sin(x * 1.3), 0.8).bp * 0.6, { gain: 0.35, pan: -0.3, send: 0.2 }); }
riser(7.2, 0.8, 1.2); snare(7.625, 0.6); snare(7.75, 0.8); snare(7.875, 1);
// 8–12  SAKUGA: full band + hook
const HOOK = [[76, 0, 1], [77, 1, 1], [79, 1.5, 0.5], [81, 2, 1], [79, 3, 0.5], [77, 3.5, 0.5],
  [79, 4, 1.5], [74, 5.5, 0.5], [79, 6, 0.5], [81, 6.5, 0.5], [83, 7, 1],
  [84, 8, 1], [83, 9, 0.5], [79, 9.5, 0.5], [76, 10, 1], [79, 11, 0.5], [83, 11.5, 0.5],
  [81, 12, 2], [76, 14, 0.5], [79, 14.5, 0.5], [81, 15, 0.5], [84, 15.5, 0.5]];
function band(bar0, bars, { hook = true, drums = true, g = 1 } = {}) {
  for (let bar = bar0; bar < bar0 + bars; bar++) {
    const ch = PROG[bar]; pad(b(bar), 2, CH[ch], g, 2400);
    if (drums) { kick(b(bar, 0)); kick(b(bar, 1.5), 0.8); kick(b(bar, 2)); snare(b(bar, 1)); snare(b(bar, 3)); if (bar % 2) snare(b(bar, 3.75), 0.5);
      for (let s = 0; s < 16; s++) hat(b(bar) + s * 0.125, s % 4 === 2 ? 1 : 0.45); }
    for (let e = 0; e < 8; e++) bassNote(b(bar) + e * 0.25, 0.24, ROOT[ch] + (e % 4 === 3 ? 12 : 0), 0.9);
    [0, 1, 2, 3, 2, 3, 1, 2].forEach((n, e) => pluck(b(bar) + e * 0.25, CH[ch][n % CH[ch].length] + 24, 0.55, e % 2 ? 0.5 : -0.5));
  }
  if (hook) HOOK.forEach(([m, beat, d]) => { const t = b(bar0) + beat * 0.5; if (t < b(bar0 + bars)) lead(t, d * 0.5 * 0.92, m, g); });
}
crash(8, 1); boom(8, 0.5, 1.2); band(4, 2);
kick(9.5, 1); boom(9.5, 0.55, 1.2); clap(9.5, 1);                  // wall kick "ドンッ"
whoosh(9.9, 0.7, 1.4, 0.5, false); whoosh(10.3, 0.45, 1.2, -0.5);  // flip smear
riser(10.8, 1.2, 1.3); whoosh(11.5, 0.5, 1.5);
// 12–16  IMPACT: tension → clash at 13.0 → full band
pad(12, 1, [45, 52, 57, 60], 1, 900); { let ph = 0; voice(12, 1, x => { ph += (50 + 30 * x) / SR; return saw(ph) * x; }, { gain: 0.25, send: 0.1 }); }
whoosh(12.2, 0.8, 1.6, -0.7); whoosh(12.25, 0.75, 1.6, 0.7); riser(12.2, 0.8, 1.2);
boom(13, 1.4, 3); kick(13, 1.2); crash(13, 1.5); clap(13, 1); for (let k = 0; k < 10; k++) zap(13 + k * 0.033, 2);
{ const f = svf(); voice(13, 1.5, x => f(rnd() * 2 - 1, 2000, 0.5).lo * Math.exp(-x * 2.5), { gain: 0.5, send: 0.4 }); }
band(7, 1, { hook: false }); HOOK.slice(0, 11).forEach(([m, beat, d]) => { const t = 14 + beat * 0.5; if (t < 16) lead(t, d * 0.46, m); });
kick(13.5, 0.9); snare(13.5, 0.8);
// 16–20  PRINCIPLES: panel clacks on 8ths, then four word slams
[16, 16.25, 16.5, 16.75].forEach((t, i) => { clap(t, 0.8); kick(t, 0.7); pluck(t, 72 + [0, 3, 7, 12][i], 1); });
for (let bar = 8; bar < 10; bar++) { pad(b(bar), 2, CH[PROG[bar]], 0.8, 2000); for (let e = 0; e < 8; e++) bassNote(b(bar) + e * 0.25, 0.22, ROOT[PROG[bar]], 0.8); }
[17, 17.5].forEach(t => { kick(t); hat(t + 0.25, 1, true); }); snare(17.5);
[18, 18.5, 19, 19.5].forEach((t, i) => { kick(t, 1.1); clap(t, 1); boom(t, 0.4, 0.6); crash(t, 0.5); pad(t, 0.4, CH[PROG[9]].map(n => n + 12), 0.9, 4000);
  if (i === 1) whoosh(t, 0.3, 1, 0.6); if (i === 2) { boom(t + 0.1, 0.6, 1); } if (i === 3) for (let k = 0; k < 8; k++) hat(t + k * 0.0625, 1); });
// 20–24  POWER UP: rumble, crackle, accelerating build
{ const f = svf(); let ph = 0; voice(20, 4, x => { ph += 38 / SR; return (Math.sin(TAU * ph) * 0.8 + f(rnd() * 2 - 1, 120 + 60 * x, 0.7).lo * 1.5) * Math.min(1, x / 0.5) * (0.6 + x * 0.12); }, { gain: 0.6, send: 0.1 }); }
pad(20, 2, CH.Am, 1, 1200); pad(22, 2, CH.E, 1.1, 2600);
bassNote(20, 2, ROOT.Am); bassNote(22, 2, ROOT.E);
for (let k = 0; k < 8; k++) kick(20 + k * 0.5, 0.9);
for (let k = 0; k < 8; k++) snare(22 + k * 0.25, 0.4 + k * 0.05);
for (let k = 0; k < 8; k++) snare(23 + k * 0.125, 0.6 + k * 0.05);
for (let k = 0; k < 60; k++) if (rnd() < 0.5) zap(20 + k * 0.066, 1 + (k / 60) * 2);
riser(21.2, 2.8, 1.6); shing(22.5, 0.8);
{ let ph = 0; voice(22.5, 1.5, x => { ph += (200 + 600 * x * x) / SR; return Math.sin(TAU * ph) * (x / 1.5) * 0.5; }, { gain: 0.35, send: 0.5 }); }
// 24–26.5  RELEASE: the beam
boom(24, 1.5, 2.5); kick(24, 1.3); crash(24, 1.6); clap(24, 1.2);
{ const f = svf(), f2 = svf(); let ph = 0; voice(24, 2.5, x => { ph += 42 / SR; const u = x / 2.5; const n = rnd() * 2 - 1;
  return Math.tanh((f(n, 900 + 600 * Math.sin(x * 20), 0.6).bp * 2 + f2(n, 5000, 0.5).hp * 0.5 + Math.sin(TAU * ph) * 0.9) * 1.5) * (1 - Math.pow(u, 3)); }, { gain: 0.55, send: 0.25 }); }
band(12, 1, { hook: false, g: 1.1 });
HOOK.slice(0, 6).forEach(([m, beat, d]) => lead(24 + beat * 0.5, d * 0.46, m + 12, 1.1));
pad(26, 0.5, CH.G, 1.1, 3000); kick(26); snare(26.25, 0.7); snare(26.375, 0.8);
// 26.5–30  END CARD: resolve to C, bell arpeggio, long tail
boom(26.5, 0.9, 2.5); crash(26.5, 1.2); kick(26.5, 1.1);
pad(26.5, 3.0, [48, 55, 59, 62, 64, 67], 1.0, 1800); bassNote(26.5, 3, 36, 1);
[72, 76, 79, 83, 86, 88, 91].forEach((m, i) => bell(26.9 + i * 0.16, m, 1, (i / 6 - .5) * 1.2));
bell(28.6, 84, 0.8, 0); bell(28.6, 91, 0.5, 0.3);
{ let ph = 0; voice(27.0, 0.12, x => { ph += 1200 / SR; return sq(ph) * Math.exp(-x * 40); }, { gain: 0.06, send: 0.3 }); } // stamp tick

/* ---------- reverb (Schroeder) + mix ---------- */
function reverb(inp, combs, aps) {
  const out = new Float32Array(N);
  for (const [d, fb] of combs) { const buf = new Float32Array(d); let idx = 0, lp = 0; for (let i = 0; i < N; i++) { const y = buf[idx]; lp = y * 0.7 + lp * 0.3; buf[idx] = inp[i] + lp * fb; idx = (idx + 1) % d; out[i] += y / combs.length; } }
  for (const [d, g] of aps) { const buf = new Float32Array(d); let idx = 0; for (let i = 0; i < N; i++) { const bv = buf[idx], x = out[i]; const y = -g * x + bv; buf[idx] = x + g * y; idx = (idx + 1) % d; out[i] = y; } }
  return out;
}
const wetL = reverb(RL, [[1557, 0.84], [1617, 0.84], [1491, 0.84], [1422, 0.84]], [[225, 0.5], [556, 0.5]]);
const wetR = reverb(RR, [[1277, 0.84], [1356, 0.84], [1188, 0.84], [1116, 0.84]], [[248, 0.5], [579, 0.5]]);
const out = Buffer.alloc(44 + N * 4);
let peak = 0; const mixL = new Float32Array(N), mixR = new Float32Array(N);
for (let i = 0; i < N; i++) { const sc = sidechain[i]; mixL[i] = L[i] * (0.55 + 0.45 * sc) + wetL[i] * 0.9; mixR[i] = R[i] * (0.55 + 0.45 * sc) + wetR[i] * 0.9; peak = Math.max(peak, Math.abs(mixL[i]), Math.abs(mixR[i])); }
const pre = 1.6 / peak;
for (let i = 0; i < N; i++) {
  const t = i / SR, fade = Math.min(1, t / 0.02) * (t > 29.2 ? Math.max(0, (30 - t) / 0.8) : 1);
  out.writeInt16LE(Math.round(Math.tanh(mixL[i] * pre) * 0.92 * fade * 32767), 44 + i * 4);
  out.writeInt16LE(Math.round(Math.tanh(mixR[i] * pre) * 0.92 * fade * 32767), 46 + i * 4);
}
out.write('RIFF', 0); out.writeUInt32LE(36 + N * 4, 4); out.write('WAVE', 8); out.write('fmt ', 12); out.writeUInt32LE(16, 16);
out.writeUInt16LE(1, 20); out.writeUInt16LE(2, 22); out.writeUInt32LE(SR, 24); out.writeUInt32LE(SR * 4, 28); out.writeUInt16LE(4, 32); out.writeUInt16LE(16, 34);
out.write('data', 36); out.writeUInt32LE(N * 4, 40);
const dest = path.join(path.dirname(fileURLToPath(import.meta.url)), 'reel.wav');
fs.writeFileSync(dest, out); console.log('wrote', dest, 'peak', peak.toFixed(2));
