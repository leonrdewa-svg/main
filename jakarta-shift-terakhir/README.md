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

- **5 area**: Dukuh Atas, Monas, Kota Tua, Blok M, SCBD. Pindah area lewat **papan MRT** (peta), istirahat & simpan di sana.
- **Musuh berkeliaran**: sentuh = diserang duluan; tekan Z dari dekat = **Serangan Pertama** (musuh -15% HP).
- **Battle gaya Expedition 33**
  - Timeline giliran berdasar SPD.
  - Serang = combo pukulan & tendangan, semua pakai Z: TEKAN pas, TAHAN lalu lepas di hijau, atau TEKAN TERUS. PERFECT = damage lebih besar.
  - Musuh menyerang dengan ritme berbeda-beda. Lingkaran yang menyusut ke hero = waktu kena: **PARRY** (Z) atau **DODGE** (X).
    Lingkaran merah = tidak bisa di-parry. Parry semua hit = **COUNTER**.
  - **AP** untuk jurus (Tinju Komuter, Tendangan Putar, Sapuan Kaki, Badai Dokumen, dll).
  - Meter **SEMANGAT** penuh = **Pamungkas** duo.
- **Level & EXP**, uang Rupiah, **Warung Bu Sari** (beli nasi bungkus, kopi susu, dll).
- **4 bos** + fase 2 bos terakhir. Pekerja yang dikalahkan kembali normal dan bisa diajak bicara.

## Struktur

```
scripts/
  game.gd        data karakter/musuh/item, party, simpan/muat, input
  story.gd       area, NPC, musuh, dialog
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
- Suara dibuat dengan Open JTalk: Tara & NPC perempuan pakai HTS voice *tohoku-f01*
  (CC BY 4.0, Tohoku University), Raka & NPC laki-laki pakai *nitech_jp_atr503_m001* (CC BY 3.0).

Kredit: art dari user; font Bangers & Archivo Narrow (OFL); plugin Godot AI (MIT).
