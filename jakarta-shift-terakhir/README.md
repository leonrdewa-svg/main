# JAKARTA: SHIFT TERAKHIR — Demo

Demo RPG turn-based bergaya *paper* (terinspirasi Paper Mario) di Godot 4.
Tara & Raka pulang kantor, tapi rekan-rekan kerjanya **Dirasuki Lembur**.

## Cara main

1. Install **Godot 4.5+** (dites di **4.7 stable**).
2. Buka Godot → *Import* → pilih `jakarta-shift-terakhir/project.godot`.
3. Tekan **F5**.

| Tombol | Fungsi |
|---|---|
| `Z` / `Spasi` / `Enter` / klik kiri | pilih menu, lanjut dialog, **action command** |
| `X` / `Esc` / klik kanan | batal / kembali |
| Panah / mouse | navigasi menu & target |

## Isi demo

- **Judul → cerita → Babak 1 (Dukuh Atas) → cerita → Babak 2 / Boss (Blok M) → ending**
- **Turn-based bergantian**: Raka & Tara memilih aksi, lalu musuh menyerang.
- **Action command ala Paper Mario**
  - *Lompat Payung* (Raka): tekan Z pas mendarat untuk lompat lagi (maks. 3 hit).
  - *Tampar Kipas* (Tara): tekan Z saat lingkaran menyusut pas di target.
  - *Badai Kertas*: tekan Z berulang-ulang (serang semua musuh).
  - *Tusukan Payung*: tahan Z, lepas di zona hijau.
  - **GUARD**: tekan Z tepat sebelum serangan musuh kena (damage -1).
- **Jurus** pakai Semangat (SP), **Item** (Kopi Susu, Es Teh Manis, Nasi Goreng, Kartu MRT → kereta lewat!), **Bertahan**.
- **Musuh**: Deadline (serang 2x tiap 3 giliran), Revisi (heal teman / turunkan ATK),
  Target (buff ATK), **LEMBUR** (boss: serang semua + charge serangan besar).
- **Efek**: tirai panggung, flip kertas, squash & stretch, angka damage starburst,
  partikel kertas/struk/confetti, cut-in jurus, speed lines, screen shake, ekspresi wajah HUD.
- **Audio**: BGM (judul, battle, boss), jingle menang/kalah, ±30 SFX — semua dibuat prosedural.

## Struktur

```
scripts/
  game.gd            autoload: data karakter/musuh/item, state party, input, theme
  sfx.gd             autoload: SFX pool + musik crossfade
  main.gd            alur scene (judul, cerita, battle, ending, game over)
  battle.gd          loop turn-based, aksi hero, AI musuh
  battler.gd         unit kertas (animasi idle, lompat, flip, hit, tumbang)
  action_command.gd  timing / mash / hold / guard
  fx.gd              efek visual (starburst, partikel, cut-in, kereta MRT)
  command_menu.gd, hud.gd, dialogue.gd, stage.gd, title_screen.gd
assets/  bg/ sprites/ ui/ audio/ fonts/
addons/godot_ai/     plugin Godot AI (MCP) — sudah di-enable
```

Semua scene dibangun lewat kode (`scenes/main.tscn` hanya root), jadi mudah dimodifikasi.
Data stat/jurus/item ada di `scripts/game.gd`.

## Tes otomatis

```
godot --path . -- --autoplay --shots=/tmp/shots
```
Game dimainkan otomatis dari judul sampai ending, screenshot disimpan tiap 0.8 detik.

## Kredit

- Art karakter & latar: dari user (character sheet Tara, Raka, Dirasuki Lembur; latar Dukuh Atas & Blok M).
- Font: Bangers, Archivo Narrow (SIL Open Font License).
- Plugin: Godot AI (MIT).
