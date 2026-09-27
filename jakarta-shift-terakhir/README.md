# JAKARTA: SHIFT TERAKHIR

RPG jelajah Jakarta (±1 jam) di Godot 4. Tara & Raka membebaskan pekerja yang
**Dirasuki Lembur**, mengumpulkan 3 Kartu Akses, lalu menyerbu Menara Shift di SCBD.

## Cara main

Godot **4.5+** (dites 4.7) → Import `project.godot` → **F5**. Progres tersimpan otomatis.

| Tombol | Eksplorasi | Battle |
|---|---|---|
| Panah / WASD / klik | jalan | pilih menu, tombol QTE |
| `Z` / Spasi / klik kiri | bicara, **serang duluan** | pilih, **PARRY** |
| `X` / klik kanan | menu | **DODGE**, batal |
| `C` / Tab | menu (Tas, Status, Simpan) | - |

## Isi

- **Prolog sinematik** (±5 menit): SCBD 17.58 → pukul 18.00 aplikasi SHIFT+ merasuki semua pekerja
  → kabur lewat Jalur Servis → tiba di Dukuh Atas, bertemu Bu Sari. Tahan X / ketuk LEWATI untuk melompati.

- **7 lokasi × 2 sisi = 14 area panorama**: Dukuh Atas, Monas, Kota Tua, Tanah Abang, Blok M, Cikini, SCBD.
  Jalan ke tepi layar untuk pindah sisi; papan MRT untuk pindah lokasi, istirahat & simpan.
- **24 NPC + 10 misi sampingan** (tanda ! kuning), **20 harta tersembunyi**, 55 grup musuh + 7 bos
  (termasuk **Ratu Notifikasi** di Cikini dan bos sejati **Direktur Nol**).
  Bos tiap area muncul setelah cukup pekerja dibebaskan.
- **Musuh berkeliaran**: sentuh = diserang duluan; tekan Z dari dekat = **Serangan Pertama** (musuh -15% HP).
- **Battle gaya Expedition 33**
  - Timeline giliran berdasar SPD.
  - Serang = combo pukulan & tendangan, semua pakai Z: TEKAN pas, TAHAN lalu lepas di hijau, atau TEKAN TERUS. PERFECT = damage lebih besar.
  - Musuh menyerang dengan ritme berbeda-beda. Lingkaran yang menyusut ke hero = waktu kena: **PARRY** (Z) atau **DODGE** (X).
    Lingkaran merah = tidak bisa di-parry. Parry semua hit = **COUNTER**.
  - **16 jurus** (8 per hero, terbuka tiap naik level) dengan **elemen** API / LISTRIK / KERTAS.
    Tiap musuh punya kelemahan (LEMAH! x1.5) dan ketahanan. Efek: pusing, ATK turun, terbakar, heal party.
  - **23 jenis musuh** (12 baru: Absensi, Spam, Fotokopi, Rapat Meja, Arsip, Reimburse, Buffer, Presentasi,
    Shift Ganda, Komuter, Kontrak, Gosip). Jurus hero, musuh, dan bos memakai animasi 5 tahap dari motion sheet.
  - Lama: Deadline, Notifikasi, Deadline Mendesak, Revisi, Revisi Beku, Rapat Zoom,
    Target, Target Emas (bisa kabur), KPI Merah, Lembur, Lembur Bayangan.
  - Gerakan halus (easing + bayangan jejak) dan kamera sinematik yang zoom ke aksi.
  - Meter **SEMANGAT** penuh = **Pamungkas** duo.
- **Level & EXP**, uang Rupiah, **Warung Bu Sari** (beli nasi bungkus, kopi susu, dll).
- **4 bos** + fase 2 bos terakhir. Pekerja yang dikalahkan kembali normal dan bisa diajak bicara.

## Struktur

```
scripts/
  game.gd        data karakter/musuh/item, party, simpan/muat, input
  story.gd       area, NPC, musuh, prolog, dialog
  prologue.gd    adegan pembuka sinematik
  main.gd        alur: judul, dunia, battle, peta, warung, ending
  world.gd       eksplorasi (pemain, Tara, NPC, musuh berkeliaran)
  walker.gd      animasi jalan 8 frame
  battle.gd      battle QTE + parry/dodge/counter
  battle_hud.gd  HP, AP, Semangat, timeline
  qte.gd         prompt tombol + jendela parry/dodge
  map_screen.gd, shop.gd, dialogue.gd, command_menu.gd, fx.gd, battler.gd
```

Tes otomatis: `godot --path . -- --autoplay --shots=/tmp/shots`.

## Bahasa & suara

- Teks: Indonesia / English (ganti di menu judul atau menu C). Suara: bahasa Jepang.
- Suara dibuat dengan **VOICEVOX** (TTS neural, gaya emosi):
  VOICEVOX:もち子さん (Tara), VOICEVOX:青山龍星 (Raka), VOICEVOX:No.7 (narator),
  VOICEVOX:東北イタコ, 四国めたん, 玄野武宏, 剣崎雌雄, 麒ヶ島宗麟, 雀松朱司, 白上虎太郎, 後鬼.
- Mode kontrol: **PC** (keyboard/mouse) atau **Sentuh** (joystick & tombol layar untuk HP),
  terdeteksi otomatis, bisa diganti di menu judul / menu C. Di HP main dalam mode landscape.

Kredit: art dari user; font Bangers & Archivo Narrow (OFL); plugin Godot AI (MIT).
