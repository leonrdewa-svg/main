class_name Story
extends RefCounted
## Data dunia & cerita: area, NPC, musuh yang berkeliaran, bos, dan dialog.

const W := "res://assets/world/"

const AREAS := {
	"dukuh": {"name": "Dukuh Atas", "bg": "res://assets/bg/dukuh_atas.jpg", "music": "bgm_title",
		"floor": [548, 690], "station": Vector2(120, 600), "map": Vector2(655, 390),
		"npcs": [
			{"id": "satpam_da", "who": "satpam", "sprite": W + "npc_target.png", "pos": Vector2(560, 585), "talk": "satpam_da"},
		],
		"enemies": [
			{"id": "da_1", "sprite": W + "d_deadline.png", "pos": Vector2(820, 610), "group": ["deadline"]},
			{"id": "da_2", "sprite": W + "d_revisi.png", "pos": Vector2(1100, 650), "group": ["deadline", "revisi"]},
		]},
	"monas": {"name": "Monas", "bg": W + "bg_monas.jpg", "music": "bgm_title",
		"floor": [520, 690], "station": Vector2(120, 600), "map": Vector2(658, 199),
		"npcs": [
			{"id": "penjual_monas", "who": "karyawati", "sprite": W + "npc_revisi.png", "pos": Vector2(300, 560), "talk": "monas_npc"},
		],
		"enemies": [
			{"id": "mo_1", "sprite": W + "d_revisi.png", "pos": Vector2(560, 620), "group": ["revisi", "revisi"]},
			{"id": "mo_2", "sprite": W + "d_deadline.png", "pos": Vector2(820, 660), "group": ["deadline", "revisi", "deadline"]},
			{"id": "mo_boss", "sprite": W + "d_revisi.png", "pos": Vector2(1090, 580), "group": ["revisi_agung"], "boss": true,
				"card": "kartu_monas", "pre": "monas_boss_pre", "post": "monas_boss_post"},
		]},
	"kotatua": {"name": "Kota Tua", "bg": W + "bg_kotatua.jpg", "music": "bgm_title",
		"floor": [520, 690], "station": Vector2(120, 600), "map": Vector2(689, 77),
		"npcs": [
			{"id": "sepeda", "who": "pekerja", "sprite": W + "npc_deadline.png", "pos": Vector2(930, 560), "talk": "kotatua_npc"},
		],
		"enemies": [
			{"id": "kt_1", "sprite": W + "d_target.png", "pos": Vector2(480, 640), "group": ["target"]},
			{"id": "kt_2", "sprite": W + "d_deadline.png", "pos": Vector2(720, 610), "group": ["deadline", "target"]},
			{"id": "kt_3", "sprite": W + "d_revisi.png", "pos": Vector2(1100, 660), "group": ["revisi", "target", "revisi"]},
			{"id": "kt_boss", "sprite": W + "d_target.png", "pos": Vector2(640, 540), "group": ["target_raksasa"], "boss": true,
				"card": "kartu_kotatua", "pre": "kotatua_boss_pre", "post": "kotatua_boss_post"},
		]},
	"blokm": {"name": "Blok M", "bg": "res://assets/bg/blok_m.jpg", "music": "bgm_title",
		"floor": [560, 690], "station": Vector2(120, 610), "map": Vector2(475, 475),
		"shop": Vector2(700, 585),
		"npcs": [],
		"enemies": [
			{"id": "bm_1", "sprite": W + "d_lembur.png", "pos": Vector2(460, 660), "group": ["lembur"]},
			{"id": "bm_2", "sprite": W + "d_target.png", "pos": Vector2(930, 650), "group": ["target", "deadline", "revisi"]},
			{"id": "bm_boss", "sprite": W + "d_lembur.png", "pos": Vector2(1130, 600), "group": ["lembur_manajer", "deadline"], "boss": true,
				"card": "kartu_blokm", "pre": "blokm_boss_pre", "post": "blokm_boss_post"},
		]},
	"scbd": {"name": "SCBD · Menara Shift", "bg": W + "bg_scbd.jpg", "music": "bgm_boss",
		"floor": [540, 690], "station": Vector2(120, 610), "map": Vector2(980, 459),
		"gate": Vector2(700, 560),
		"npcs": [
			{"id": "satpam_scbd", "who": "satpam", "sprite": W + "npc_target.png", "pos": Vector2(1010, 560), "talk": "scbd_satpam"},
		],
		"enemies": [
			{"id": "sc_1", "sprite": W + "d_lembur.png", "pos": Vector2(420, 650), "group": ["lembur", "target"]},
			{"id": "sc_2", "sprite": W + "d_deadline.png", "pos": Vector2(1150, 660), "group": ["deadline", "lembur", "revisi"]},
		]},
}

const MAP_LOCKED := {"Tanah Abang": Vector2(290, 222), "Cikini": Vector2(1026, 230)}
const AREA_ORDER := ["dukuh", "monas", "kotatua", "blokm", "scbd"]

## Pekerja yang sudah dibebaskan mengucapkan salah satu baris ini.
const FREED := [
	"Hah... aku di mana? Terakhir ingat lagi bikin laporan jam 11 malam.",
	"Makasih ya. Rasanya kayak bangun dari rapat tiga jam.",
	"Aku... mau pulang. Beneran pulang. Makasih!",
	"Jadi tadi itu aku? Ya ampun, maaf udah nyerang kalian.",
	"Kepalaku enteng banget. Kayak habis cuti seminggu.",
]

const D := {
	"intro": [
		["narator", "", "Jakarta, 18.47. Stasiun MRT Dukuh Atas. Jam pulang kantor."],
		["tara", "tired", "Akhirnya pulang. Delapan jam rapat yang harusnya cukup jadi email."],
		["raka", "happy", "Semangat, Tar! Tinggal tap kartu, duduk, tidur sampai Blok M."],
		["tara", "normal", "Raka... kenapa orang-orang kantor jalannya kayak zombie?"],
		["raka", "normal", "Itu Pak Dedi dari Finance. Kok badannya dililit jam dinding?"],
		["narator", "", "Kertas-kertas hitam beterbangan. Para pekerja di sekitar stasiun DIRASUKI LEMBUR."],
		["tara", "focus", "Kita harus bebaskan mereka. Pakai tangan kosong juga nggak apa-apa!"],
		["raka", "focus", "Nggak ada yang boleh ganggu jam pulang!"],
		["narator", "", "PANAH / WASD: jalan.  Z: bicara / serang duluan.  C: menu.  Dekati pekerja yang dirasuki untuk bertarung."],
	],
	"satpam_da": [
		["satpam", "", "Dek, hati-hati! Sejak sore orang-orang kantor pada kesurupan kerjaan."],
		["satpam", "", "Kalau capek, istirahat di papan MRT itu. Sekalian simpan tenaga."],
	],
	"prolog_done": [
		["raka", "tired", "Hah... hah... mereka balik normal!"],
		["pak_dedi", "", "Kalian... makasih. Semua ini gara-gara Menara Shift di SCBD. Sejak pagi lampunya nyala merah terus."],
		["pak_dedi", "", "Gerbangnya dikunci pakai tiga Kartu Akses. Dipegang tiga manajer yang paling parah dirasuki."],
		["pak_dedi", "", "Satu di Monas, satu di Kota Tua, satu lagi di Blok M."],
		["tara", "focus", "Oke. Kumpulkan tiga kartu, lalu serbu Menara Shift."],
		["narator", "", "PETA MRT terbuka! Pergi ke papan MRT di kiri layar untuk pindah area. Urutan bebas."],
	],
	"monas_npc": [
		["karyawati", "", "Bosku di sana, di depan Monas. Dia merevisi slide yang sama dari jam 9 pagi."],
		["karyawati", "", "Serangannya cepat-cepat. Coba PARRY pakai Z pas coretan pulpennya mau kena!"],
	],
	"monas_boss_pre": [
		["mbak_rani", "", "Revisi. Revisi. Font-nya kurang besar. Warnanya kurang... biru."],
		["tara", "skeptis", "Mbak, itu udah versi ke-47."],
		["mbak_rani", "", "MASIH. ADA. YANG. BISA. DIPERBAIKI."],
	],
	"monas_boss_post": [
		["mbak_rani", "", "Versi pertama... sebenarnya udah bagus ya?"],
		["tara", "happy", "Dari tadi, Mbak."],
		["narator", "", "Dapat KARTU AKSES MONAS!"],
	],
	"kotatua_npc": [
		["pekerja", "", "Mau sewa sepeda? Lagi tutup, Mas. Bos besar di tengah alun-alun lagi ngejar target."],
		["pekerja", "", "Tips: serangan merah itu nggak bisa di-parry. Harus DODGE pakai X!"],
	],
	"kotatua_boss_pre": [
		["bang_joko", "", "ANGKA. HARUS. NAIK. Kuartal ini dua ratus persen!"],
		["raka", "normal", "Bang, ini udah jam sembilan malam."],
		["bang_joko", "", "Jam juga harus naik!"],
	],
	"kotatua_boss_post": [
		["bang_joko", "", "Aduh... punggungku. Kayaknya aku butuh target tidur delapan jam."],
		["raka", "happy", "Nah, itu baru target yang masuk akal."],
		["narator", "", "Dapat KARTU AKSES KOTA TUA!"],
	],
	"busari_hi": [
		["bu_sari", "", "Makan dulu, baru lawan deadline. Mau apa, Nak?"],
	],
	"blokm_boss_pre": [
		["pak_haris", "", "Pulang? Kata itu... sudah dihapus dari kamus perusahaan."],
		["tara", "focus", "Pak Haris?! Manajer divisi kita?"],
		["pak_haris", "", "Kerja. Masih. Bisa. Lebih. BANYAK."],
	],
	"blokm_boss_post": [
		["pak_haris", "", "Anak-anak... maaf. Saya lupa kalian juga punya rumah."],
		["raka", "normal", "Besok cuti ya, Pak. Beneran cuti."],
		["narator", "", "Dapat KARTU AKSES BLOK M!"],
	],
	"scbd_satpam": [
		["satpam", "", "Gerbang Menara Shift cuma bisa dibuka pakai tiga Kartu Akses."],
		["satpam", "", "Di dalam... ada sesuatu yang nggak pernah pulang sejak menara ini dibangun."],
	],
	"gate_locked": [
		["narator", "", "Gerbang terkunci. Kartu akses: %d / 3."],
	],
	"final_pre": [
		["narator", "", "Tiga kartu menyala. Gerbang Menara Shift terbuka."],
		["lembur", "", "HARI INI. BESOK. SETIAP HARI. SELAMANYA."],
		["tara", "focus", "Jadi kamu yang bikin semua orang lupa pulang."],
		["raka", "focus", "Shift ini, kita yang tutup!"],
	],
	"ending": [
		["narator", "", "Lampu merah Menara Shift padam. Di seluruh Jakarta, layar laptop menutup satu per satu."],
		["pak_dedi", "", "Semua orang pulang. Jalanan macet... tapi macet yang bahagia."],
		["bu_sari", "", "Nah! Pahlawan kita. Nasi bungkus gratis malam ini!"],
		["tara", "happy", "Jadi... besok masuk jam berapa?"],
		["raka", "tired", "Jangan. Sebut. Kerjaan."],
		["tara", "happy", "Hahaha. Yuk, pulang. Kali ini beneran pulang."],
		["narator", "", "TAMAT. Terima kasih sudah bermain JAKARTA: SHIFT TERAKHIR!"],
	],
	"station": [
		["narator", "", "Papan MRT."],
	],
}


static func objective() -> String:
	if not Game.flag("prolog_done"):
		return "Bebaskan pekerja yang dirasuki di Dukuh Atas"
	if Game.cards() < 3:
		var left := []
		if not Game.flag("kartu_monas"):
			left.append("Monas")
		if not Game.flag("kartu_kotatua"):
			left.append("Kota Tua")
		if not Game.flag("kartu_blokm"):
			left.append("Blok M")
		return "Kumpulkan Kartu Akses (%d/3): %s" % [Game.cards(), ", ".join(left)]
	return "Buka gerbang Menara Shift di SCBD"
