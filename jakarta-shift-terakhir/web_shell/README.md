# Halaman web (versi browser)

`shell_template.html` adalah halaman pembungkus untuk build Web Godot (export preset "Web", tanpa thread).
Fitur: loader wasm/pck ter-gzip, audio worklet via blob, dan di HP: MAIN langsung layar penuh + kunci
landscape, sentuhan pertama setelah HP diputar masuk layar penuh, game selalu mengisi seluruh layar.

Cara build:
1. Export preset "Web" ke `WORK/web/index.html`.
2. `gzip -9 -c WORK/web/index.wasm > WORK/site/engine.gz.wasm` dan `gzip -9 -c WORK/web/index.pck > WORK/site/gamedata.gz.wasm`.
3. Salin `shell_template.html` ke `WORK/`, lalu `python3 build_page.py WORK/` → `WORK/site/play.html`.
