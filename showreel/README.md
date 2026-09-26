# Motion Reel 2026 — 2D anime showreel (9:16)

**Watch:** [`motion-reel-2026.mp4`](motion-reel-2026.mp4) — 1080×1920, 30 fps, 30 s, H.264 + AAC.

Every frame and every sound is generated from code, with no stock footage or samples.
It's cel-shaded 2D in the Studio Bones tradition: animated on 2s, impact frames, focus lines, smears, and cel smoke.

| Time | Scene | Techniques |
|---|---|---|
| 0–2s | 覚醒 Awakening | eye-open overshoot, pupil contraction, iris power ring, push into the pupil |
| 2–4s | Title slam | 3-frame inverted impact frames, chromatic split, shard burst, staggered type, bar wipe |
| 4–8s | 演出 Direction | dusk rooftop, parallax city, cel clouds, god rays, cloth/scarf sim, anticipation crouch then launch |
| 8–12s | 作画 Sakuga | vertical city dash, afterimages, wall-kick "ドンッ", flip smear, hero punches through camera |
| 12–16s | 衝撃 Impact | blade clash, 10-frame impact-frame sequence, cel explosion to smoke, debris, sparks |
| 16–20s | 原理 Principles | manga panels (graph editor, squash & stretch, weight, rhythm), then 4 kinetic-type slams |
| 20–24s | 力 Effects | layered cel aura, lightning, ground cracks, floating rocks, energy charge |
| 24–26.5s | 解放 Release | beam with inverted impact frames, rings, white-out |
| 26.5–30s | End card | brush ensō, name slam, hanko seal, skills, "available for hire" |

## Rebuild
```sh
node audio.mjs                 # -> reel.wav   (procedural score, 120 BPM, synced to cuts)
node render.mjs frames 4       # -> out/frames (headless Chromium, deterministic render(t))
ffmpeg -framerate 30 -i out/frames/f%04d.jpg -i reel.wav -c:v libx264 -preset slow -crf 20 \
  -maxrate 11M -bufsize 22M -tune animation -pix_fmt yuv420p -c:a aac -b:a 256k -shortest \
  -movflags +faststart motion-reel-2026.mp4
```
Open `index.html` in a browser for a live, scrubbable preview with sound.
Use `./sheet.sh 1.0 5.5 …` to get a contact sheet of any timestamps.
