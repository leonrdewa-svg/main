extends Node
## Global state: data karakter/musuh/item, party (level, EXP), uang, tas,
## flag cerita, simpan/muat, input map, theme UI, dan hook autoplay.

signal changed

const INK := Color("17151b")
const CREAM := Color("f6efe1")
const TEAL := Color("1f8a8a")
const ORANGE := Color("e8692c")
const PINK := Color("e6186e")
const YELLOW := Color("ffd23f")

const FONT_TITLE := preload("res://assets/fonts/Bangers.ttf")
const FONT_UI := preload("res://assets/fonts/ArchivoNarrow-Bold.ttf")

const SAVE_PATH := "user://shift_terakhir_save.json"

## Skill: type = combo (1 musuh) / aoe (semua) / random (hit acak) / heal / heal_all / buff / self
## kinds = urutan QTE (tap/hold/mash), elem = fisik/api/listrik/kertas, lvl = level terbuka.
const HEROES := {
	"raka": {
		"name": "Raka", "hp": 60, "atk": 9, "spd": 10, "color": Color("e8692c"), "scale": 0.39,
		"idle": "res://assets/sprites/raka_idle.png",
		"attack": "res://assets/sprites/raka_attack.png",
		"side": "res://assets/world/raka_side.png",
		"faces": {"normal": "datar", "happy": "senyum", "focus": "marah", "hurt": "marah", "tired": "lelah"},
		"skills": [
			{"id": "tinju", "name": "Tinju Komuter", "ap": 2, "target": "enemy", "type": "combo", "kinds": ["tap", "tap", "hold", "tap"], "power": 1.0, "elem": "fisik", "lvl": 1,
				"desc": "Rentetan 4 pukulan ke satu musuh. Combo sempurna = +1 AP."},
			{"id": "teriak", "name": "Teriak Jam Pulang", "ap": 1, "target": "none", "type": "buff", "lvl": 1,
				"desc": "Party ATK +30% selama 2 giliran. Tanpa QTE."},
			{"id": "putar", "name": "Tendangan Putar", "ap": 3, "target": "all_enemies", "type": "aoe", "kinds": ["tap", "mash", "tap"], "power": 0.9, "elem": "fisik", "lvl": 2,
				"desc": "Tendangan berputar ke SEMUA musuh."},
			{"id": "upper", "name": "Uppercut Deadline", "ap": 3, "target": "enemy", "type": "combo", "kinds": ["hold"], "power": 2.6, "elem": "api", "lvl": 3,
				"desc": "Satu uppercut berapi super kuat. TAHAN Z lalu lepas di hijau. Elemen API."},
			{"id": "salto", "name": "Salto Ojol", "ap": 3, "target": "none", "type": "random", "kinds": ["tap", "tap", "tap", "tap", "tap"], "power": 0.75, "elem": "fisik", "lvl": 4,
				"desc": "5 tendangan salto ke musuh acak. Cepat dan beruntun!"},
			{"id": "tubruk", "name": "Kopi Tubruk", "ap": 2, "target": "none", "type": "self", "lvl": 5,
				"desc": "Seruput kopi: Raka pulih 30% HP dan Tara dapat +2 AP."},
			{"id": "rapat", "name": "Tinju Rapat Darurat", "ap": 4, "target": "all_enemies", "type": "aoe", "kinds": ["mash", "tap", "mash"], "power": 1.3, "elem": "listrik", "lvl": 6,
				"desc": "Pukulan bermuatan listrik ke SEMUA musuh. Elemen LISTRIK."},
			{"id": "payung", "name": "Payung Badai", "ap": 5, "target": "all_enemies", "type": "aoe", "kinds": ["hold", "mash", "tap", "tap"], "power": 1.7, "elem": "listrik", "lvl": 8,
				"desc": "Jurus pamungkas Raka: badai petir dari payung komuter!"},
		],
	},
	"tara": {
		"name": "Tara", "hp": 50, "atk": 8, "spd": 12, "color": Color("1f8a8a"), "scale": 0.42,
		"idle": "res://assets/sprites/tara_idle.png",
		"attack": "res://assets/sprites/tara_attack.png",
		"side": "res://assets/world/tara_side.png",
		"faces": {"normal": "skeptis", "happy": "usil", "focus": "fokus", "hurt": "lelah", "tired": "lelah"},
		"skills": [
			{"id": "sapuan", "name": "Sapuan Kaki", "ap": 2, "target": "enemy", "type": "combo", "kinds": ["tap", "tap", "tap"], "power": 1.1, "elem": "fisik", "stun": true, "lvl": 1,
				"desc": "Sapuan kaki rendah. Semua PERFECT = musuh pusing (lewat 1 giliran)."},
			{"id": "semangat", "name": "Semangat Pagi", "ap": 2, "target": "ally", "type": "heal", "kinds": ["tap", "hold"], "power": 0.3, "lvl": 1,
				"desc": "Pulihkan HP satu teman (bisa bangkitkan). QTE bagus = pulih lebih banyak."},
			{"id": "badai", "name": "Badai Dokumen", "ap": 3, "target": "all_enemies", "type": "aoe", "kinds": ["tap", "tap", "mash", "tap"], "power": 0.8, "elem": "kertas", "lvl": 2,
				"desc": "Kipas dokumen ke SEMUA musuh. Elemen KERTAS."},
			{"id": "stempel", "name": "Stempel Merah", "ap": 2, "target": "enemy", "type": "combo", "kinds": ["hold", "tap"], "power": 0.9, "elem": "kertas", "debuff": true, "lvl": 3,
				"desc": "Cap 'DITOLAK'! ATK musuh -30% selama 3 giliran."},
			{"id": "presentasi", "name": "Tendangan Presentasi", "ap": 3, "target": "enemy", "type": "combo", "kinds": ["tap", "tap", "hold"], "power": 1.4, "elem": "fisik", "bonus_stun": true, "lvl": 4,
				"desc": "Tendangan beruntun. Damage x2 ke musuh yang sedang pusing!"},
			{"id": "rehat", "name": "Rehat Kopi", "ap": 3, "target": "party", "type": "heal_all", "kinds": ["mash"], "power": 0.25, "lvl": 5,
				"desc": "Pulihkan HP seluruh party dan hapus panik."},
			{"id": "api", "name": "Kipas Api", "ap": 3, "target": "all_enemies", "type": "aoe", "kinds": ["tap", "hold", "tap"], "power": 1.0, "elem": "api", "burn": true, "lvl": 6,
				"desc": "Kipas berapi ke SEMUA musuh + terbakar 2 giliran. Elemen API."},
			{"id": "cap", "name": "Cap Lembur Balik", "ap": 4, "target": "enemy", "type": "combo", "kinds": ["tap", "tap", "mash", "tap", "hold"], "power": 1.5, "elem": "listrik", "stun": true, "lvl": 7,
				"desc": "5 hit berlistrik. Semua PERFECT = musuh pusing. Elemen LISTRIK."},
		],
	},
}

## Serangan musuh: tiap serangan = daftar jeda antar hit (detik) + flag "berat"
## (hit merah: tidak bisa di-parry, harus DODGE).
const ENEMIES := {
	"deadline": {"name": "Deadline", "hp": 60, "atk": 8, "spd": 11, "scale": 0.47, "color": Color("f07a1f"),
		"sprite": "res://assets/sprites/deadline.png", "exp": 14, "money": 7000, "npc": "npc_deadline", "weak": "listrik",
		"quote": "Waktu tidak pernah cukup.",
		"moves": [
			{"name": "Tusuk Jarum Jam", "hits": [0.7], "power": 1.0},
			{"name": "TIK-TAK-TIK", "hits": [0.6, 0.35, 0.35], "power": 0.5},
			{"name": "Waktu Habis!", "hits": [1.1, 0.25], "power": 0.8, "heavy": [false, true]},
		]},
	"revisi": {"name": "Revisi", "hp": 52, "atk": 7, "spd": 13, "scale": 0.46, "color": Color("9a5ad0"),
		"sprite": "res://assets/sprites/revisi.png", "exp": 14, "money": 7000, "npc": "npc_revisi", "weak": "api",
		"quote": "Masih ada yang bisa diperbaiki kok.",
		"moves": [
			{"name": "Coret Merah", "hits": [0.55, 0.45], "power": 0.6},
			{"name": "Revisi Lagi :)", "hits": [0.9, 0.2, 0.2, 0.2], "power": 0.35},
			{"name": "Revisi Final_v7", "hits": [0.5, 0.9], "power": 0.8, "heavy": [false, true]},
		]},
	"target": {"name": "Target", "hp": 80, "atk": 9, "spd": 8, "scale": 0.47, "color": Color("9be02a"),
		"sprite": "res://assets/sprites/target.png", "exp": 18, "money": 10000, "npc": "npc_target", "weak": "kertas",
		"quote": "Angka harus naik.",
		"moves": [
			{"name": "Gigit Kalkulator", "hits": [0.8], "power": 1.2},
			{"name": "Angka Naik Terus", "hits": [0.5, 0.5, 0.3], "power": 0.6},
			{"name": "Grafik Anjlok", "hits": [1.3], "power": 1.6, "heavy": [true]},
		]},
	"lembur": {"name": "Lembur", "hp": 120, "atk": 10, "spd": 9, "scale": 0.58, "color": Color("e6186e"),
		"sprite": "res://assets/sprites/lembur.png", "exp": 32, "money": 16000, "npc": "npc_lembur", "weak": "api",
		"quote": "Kerja masih bisa lebih banyak.",
		"moves": [
			{"name": "Tinju Lembur", "hits": [0.75, 0.4], "power": 0.8},
			{"name": "Struk Tanpa Akhir", "hits": [0.6, 0.25, 0.25, 0.25, 0.25], "power": 0.35, "all": true},
			{"name": "Shift Tambahan", "hits": [1.4, 0.2], "power": 1.2, "heavy": [true, false]},
		]},
}

## Varian = musuh dasar + pengali + warna + gerakan/kelemahan sendiri.
const VARIANTS := {
	"notif": {"base": "deadline", "name": "Notifikasi", "hp_mul": 0.45, "atk_mul": 0.75, "scale_mul": 0.72, "tint": Color(1.1, 1.1, 0.6),
		"exp": 8, "money": 3500, "spd": 16, "weak": "listrik", "quote": "PING! PING! Ada pesan baru!",
		"moves": [{"name": "Ping!", "hits": [0.45], "power": 0.9}, {"name": "Ping Ping Ping", "hits": [0.5, 0.18, 0.18, 0.18], "power": 0.35}]},
	"deadline_merah": {"base": "deadline", "name": "Deadline Mendesak", "hp_mul": 1.2, "atk_mul": 1.2, "scale_mul": 1.05, "tint": Color(1.3, 0.65, 0.6),
		"exp": 20, "money": 9000, "spd": 14, "weak": "listrik", "resist": "api", "quote": "SEKARANG! BUKAN BESOK!",
		"moves": [{"name": "Jarum Kilat", "hits": [0.5, 0.2, 0.2], "power": 0.6}, {"name": "ASAP!!", "hits": [0.35, 0.35, 0.35, 0.8], "power": 0.45, "heavy": [false, false, false, true]}]},
	"revisi_beku": {"base": "revisi", "name": "Revisi Beku", "hp_mul": 1.2, "atk_mul": 1.1, "scale_mul": 1.0, "tint": Color(0.7, 0.9, 1.35),
		"exp": 18, "money": 8000, "weak": "api", "resist": "kertas", "panic": 0.6, "quote": "Revisinya... dibekukan dulu.",
		"moves": [{"name": "Komentar Dingin", "hits": [0.9, 0.3], "power": 0.7}, {"name": "Track Changes", "hits": [0.4, 0.4, 0.4, 0.4], "power": 0.4}]},
	"rapat": {"base": "revisi", "name": "Rapat Zoom", "hp_mul": 1.0, "atk_mul": 0.9, "scale_mul": 1.0, "tint": Color(0.75, 1.25, 0.85),
		"exp": 18, "money": 8000, "weak": "listrik", "heals": true, "quote": "Bisa dengar saya? Kamu di-mute.",
		"moves": [{"name": "Kamu Di-mute", "hits": [0.8], "power": 1.0}, {"name": "Share Screen", "hits": [0.6, 0.6], "power": 0.6}]},
	"target_emas": {"base": "target", "name": "Target Emas", "hp_mul": 0.8, "atk_mul": 0.8, "scale_mul": 0.95, "tint": Color(1.35, 1.15, 0.45),
		"exp": 40, "money": 45000, "weak": "kertas", "flee": 3, "quote": "Bonus tahunan! Tangkap kalau bisa!",
		"moves": [{"name": "Lempar Koin", "hits": [0.5, 0.3], "power": 0.6}]},
	"kpi": {"base": "target", "name": "KPI Merah", "hp_mul": 1.25, "atk_mul": 1.3, "scale_mul": 1.05, "tint": Color(1.35, 0.7, 0.7),
		"exp": 26, "money": 12000, "weak": "kertas", "resist": "fisik", "quote": "Rapor merah untukmu.",
		"moves": [{"name": "Nilai Merah", "hits": [1.0], "power": 1.4, "heavy": [true]}, {"name": "Evaluasi Bulanan", "hits": [0.7, 0.3, 0.3], "power": 0.6}]},
	"lembur_bayang": {"base": "lembur", "name": "Lembur Bayangan", "hp_mul": 0.8, "atk_mul": 1.0, "scale_mul": 0.95, "tint": Color(0.55, 0.45, 0.85),
		"exp": 28, "money": 13000, "weak": "api", "resist": "listrik", "quote": "Aku ada di setiap notifikasi malammu.",
		"moves": [{"name": "Cakar Bayangan", "hits": [0.55, 0.2, 0.2, 0.2, 0.2], "power": 0.35}, {"name": "Lampu Kantor", "hits": [1.2], "power": 1.4, "heavy": [true]}]},
	"revisi_agung": {"base": "revisi", "name": "Revisi Agung", "hp_mul": 1.6, "atk_mul": 1.1, "scale_mul": 1.25,
		"tint": Color(1.0, 0.8, 1.1), "boss": true, "exp": 60, "money": 30000},
	"target_raksasa": {"base": "target", "name": "Target Raksasa", "hp_mul": 1.5, "atk_mul": 1.1, "scale_mul": 1.3,
		"tint": Color(0.9, 1.1, 0.8), "boss": true, "exp": 70, "money": 30000},
	"lembur_manajer": {"base": "lembur", "name": "Manajer Lembur", "hp_mul": 1.0, "atk_mul": 1.0, "scale_mul": 1.1,
		"tint": Color(1.1, 0.85, 0.95), "boss": true, "exp": 80, "money": 35000},
	"lembur_abadi": {"base": "lembur", "name": "LEMBUR ABADI", "hp_mul": 1.45, "atk_mul": 1.1, "scale_mul": 1.35,
		"tint": Color(0.75, 0.6, 0.9), "boss": true, "exp": 0, "money": 0, "final": true},
}

const ITEMS := {
	"nasi": {"name": "Nasi Bungkus", "icon": "res://assets/world/it_nasi.png", "price": 15000, "target": "ally", "hp": 60,
		"desc": "+60 HP satu teman. Bisa membangunkan yang tumbang."},
	"kopi": {"name": "Kopi Susu", "icon": "res://assets/world/it_kopi.png", "price": 18000, "target": "ally", "ap": 3,
		"desc": "+3 AP. Melek lagi."},
	"air": {"name": "Air Mineral", "icon": "res://assets/world/it_air.png", "price": 5000, "target": "ally", "hp": 20,
		"desc": "+20 HP."},
	"roti": {"name": "Roti Bakar", "icon": "res://assets/world/it_roti.png", "price": 12000, "target": "ally", "hp": 40,
		"desc": "+40 HP."},
	"permen": {"name": "Permen Jahe", "icon": "res://assets/world/it_permen.png", "price": 8000, "target": "ally", "cure": true,
		"desc": "Hapus panik (efek buruk) + 10 HP."},
	"plester": {"name": "Plester", "icon": "res://assets/world/it_plester.png", "price": 10000, "target": "ally", "hp": 30,
		"desc": "+30 HP."},
	"kartu": {"name": "Kartu MRT", "icon": "res://assets/sprites/item_kartu.png", "price": 25000, "target": "all_enemies", "dmg": 45,
		"desc": "Tap! Kereta MRT lewat: 45 damage ke semua musuh."},
}

## NPC (potret + nama) untuk dialog.
const NPCS := {
	"bu_sari": {"name": "Bu Sari", "color": Color("c0392b"), "tex": "res://assets/world/face_busari.png"},
	"pak_dedi": {"name": "Pak Dedi", "color": Color("f07a1f"), "tex": "res://assets/world/npc_deadline.png"},
	"mbak_rani": {"name": "Mbak Rani", "color": Color("9a5ad0"), "tex": "res://assets/world/npc_revisi.png"},
	"bang_joko": {"name": "Bang Joko", "color": Color("6a9a2a"), "tex": "res://assets/world/npc_target.png"},
	"pak_haris": {"name": "Pak Haris", "color": Color("b0104e"), "tex": "res://assets/world/npc_lembur.png"},
	"pekerja": {"name": "Pekerja", "color": Color("5a5068"), "tex": "res://assets/world/npc_deadline.png"},
	"karyawati": {"name": "Karyawati", "color": Color("5a5068"), "tex": "res://assets/world/npc_revisi.png"},
	"satpam": {"name": "Satpam", "color": Color("2c4a7a"), "tex": "res://assets/world/npc_target.png"},
	"ojol": {"name": "Bang Ojol", "color": Color("2f8a3c"), "tex": "res://assets/world/npc_deadline.png"},
	"mahasiswi": {"name": "Sinta", "color": Color("d0588a"), "tex": "res://assets/world/npc_revisi.png"},
	"kopi_keliling": {"name": "Mas Kopi", "color": Color("7a4a2a"), "tex": "res://assets/world/npc_target.png"},
	"anak": {"name": "Dimas", "color": Color("3a7ad0"), "tex": "res://assets/world/npc_deadline.png"},
	"kakek": {"name": "Kakek Harjo", "color": Color("8a7a5a"), "tex": "res://assets/world/npc_lembur.png"},
	"fotografer": {"name": "Rina", "color": Color("c07a2a"), "tex": "res://assets/world/npc_revisi.png"},
	"pemandu": {"name": "Pak Pemandu", "color": Color("5a3a8a"), "tex": "res://assets/world/npc_lembur.png"},
	"seniman": {"name": "Bli Wayan", "color": Color("2a8a8a"), "tex": "res://assets/world/npc_target.png"},
	"barista": {"name": "Mas Barista", "color": Color("6a4a3a"), "tex": "res://assets/world/npc_deadline.png"},
	"pengamen": {"name": "Pengamen", "color": Color("8a2a5a"), "tex": "res://assets/world/npc_target.png"},
	"sopir": {"name": "Pak Sopir", "color": Color("2a5a8a"), "tex": "res://assets/world/npc_lembur.png"},
	"ob": {"name": "Mas OB", "color": Color("4a6a2a"), "tex": "res://assets/world/npc_deadline.png"},
	"sekretaris": {"name": "Mbak Dewi", "color": Color("a02a4a"), "tex": "res://assets/world/npc_revisi.png"},
}

## Terjemahan Inggris untuk teks data (nama jurus, musuh, item...).
const EN := {
	"Tinju Komuter": "Commuter Punch", "Tendangan Putar": "Spinning Kick", "Teriak Jam Pulang": "Quitting Time Shout",
	"Uppercut Deadline": "Deadline Uppercut", "Salto Ojol": "Ojol Somersault", "Kopi Tubruk": "Tubruk Coffee",
	"Tinju Rapat Darurat": "Emergency Meeting Punch", "Payung Badai": "Storm Umbrella",
	"Sapuan Kaki": "Leg Sweep", "Badai Dokumen": "Document Storm", "Semangat Pagi": "Morning Spirit",
	"Stempel Merah": "Red Stamp", "Tendangan Presentasi": "Presentation Kick", "Rehat Kopi": "Coffee Break",
	"Kipas Api": "Fire Fan", "Cap Lembur Balik": "Overtime Reversal Stamp",
	"Rentetan 4 pukulan ke satu musuh. Combo sempurna = +1 AP.": "A 4-hit punch barrage on one enemy. Perfect combo = +1 AP.",
	"Tendangan berputar ke SEMUA musuh.": "A spinning kick that hits ALL enemies.",
	"Party ATK +30% selama 2 giliran. Tanpa QTE.": "Party ATK +30% for 2 turns. No QTE.",
	"Satu uppercut berapi super kuat. TAHAN Z lalu lepas di hijau. Elemen API.": "One mighty flaming uppercut. HOLD Z, release on green. FIRE element.",
	"5 tendangan salto ke musuh acak. Cepat dan beruntun!": "5 somersault kicks on random enemies. Fast and furious!",
	"Seruput kopi: Raka pulih 30% HP dan Tara dapat +2 AP.": "Sip of coffee: Raka heals 30% HP and Tara gains +2 AP.",
	"Pukulan bermuatan listrik ke SEMUA musuh. Elemen LISTRIK.": "Electrified punches on ALL enemies. SHOCK element.",
	"Jurus pamungkas Raka: badai petir dari payung komuter!": "Raka's finisher: a lightning storm from his commuter umbrella!",
	"Sapuan kaki rendah. Semua PERFECT = musuh pusing (lewat 1 giliran).": "A low leg sweep. All PERFECT = enemy is dizzy (skips a turn).",
	"Kipas dokumen ke SEMUA musuh. Elemen KERTAS.": "Fan a storm of documents at ALL enemies. PAPER element.",
	"Pulihkan HP satu teman (bisa bangkitkan). QTE bagus = pulih lebih banyak.": "Heal one ally (can revive). Better QTE = more healing.",
	"Cap 'DITOLAK'! ATK musuh -30% selama 3 giliran.": "'REJECTED' stamp! Enemy ATK -30% for 3 turns.",
	"Tendangan beruntun. Damage x2 ke musuh yang sedang pusing!": "A kick chain. Double damage on dizzy enemies!",
	"Pulihkan HP seluruh party dan hapus panik.": "Heal the whole party and cure panic.",
	"Kipas berapi ke SEMUA musuh + terbakar 2 giliran. Elemen API.": "Flaming fan on ALL enemies + burn for 2 turns. FIRE element.",
	"5 hit berlistrik. Semua PERFECT = musuh pusing. Elemen LISTRIK.": "5 electric hits. All PERFECT = enemy dizzy. SHOCK element.",
	"Deadline": "Deadline", "Revisi": "Revision", "Target": "Quota", "Lembur": "Overtime",
	"Notifikasi": "Notification", "Deadline Mendesak": "Urgent Deadline", "Revisi Beku": "Frozen Revision", "Rapat Zoom": "Zoom Meeting",
	"Target Emas": "Golden Quota", "KPI Merah": "Red KPI", "Lembur Bayangan": "Shadow Overtime",
	"Revisi Agung": "Grand Revision", "Target Raksasa": "Giant Quota", "Manajer Lembur": "Overtime Manager", "LEMBUR ABADI": "ETERNAL OVERTIME",
	"Waktu tidak pernah cukup.": "There is never enough time.", "Masih ada yang bisa diperbaiki kok.": "There's always something to fix.",
	"Angka harus naik.": "The numbers must go up.", "Kerja masih bisa lebih banyak.": "You can always work more.",
	"PING! PING! Ada pesan baru!": "PING! PING! New message!", "SEKARANG! BUKAN BESOK!": "NOW! NOT TOMORROW!",
	"Revisinya... dibekukan dulu.": "The revision... is frozen for now.", "Bisa dengar saya? Kamu di-mute.": "Can you hear me? You're on mute.",
	"Bonus tahunan! Tangkap kalau bisa!": "Annual bonus! Catch me if you can!", "Rapor merah untukmu.": "A red report card for you.",
	"Aku ada di setiap notifikasi malammu.": "I'm in every late-night notification.",
	"Tusuk Jarum Jam": "Clock Hand Stab", "TIK-TAK-TIK": "TICK-TOCK-TICK", "Waktu Habis!": "Time's Up!",
	"Coret Merah": "Red Ink Slash", "Revisi Lagi :)": "Revise Again :)", "Revisi Final_v7": "Final_Final_v7",
	"Gigit Kalkulator": "Calculator Bite", "Angka Naik Terus": "Numbers Keep Rising", "Grafik Anjlok": "Graph Crash",
	"Tinju Lembur": "Overtime Punch", "Struk Tanpa Akhir": "Endless Receipts", "Shift Tambahan": "Extra Shift",
	"Ping!": "Ping!", "Ping Ping Ping": "Ping Ping Ping", "Jarum Kilat": "Lightning Hands", "ASAP!!": "ASAP!!",
	"Komentar Dingin": "Cold Comment", "Track Changes": "Track Changes", "Kamu Di-mute": "You're Muted", "Share Screen": "Share Screen",
	"Lempar Koin": "Coin Toss", "Nilai Merah": "Failing Grade", "Evaluasi Bulanan": "Monthly Review",
	"Cakar Bayangan": "Shadow Claws", "Lampu Kantor": "Office Lights",
	"Nasi Bungkus": "Rice Pack", "Kopi Susu": "Milk Coffee", "Air Mineral": "Mineral Water", "Roti Bakar": "Toast",
	"Permen Jahe": "Ginger Candy", "Plester": "Bandage", "Kartu MRT": "MRT Card",
	"+60 HP satu teman. Bisa membangunkan yang tumbang.": "+60 HP to one ally. Can revive.",
	"+3 AP. Melek lagi.": "+3 AP. Wide awake again.", "+20 HP.": "+20 HP.", "+40 HP.": "+40 HP.",
	"Hapus panik (efek buruk) + 10 HP.": "Cures panic (debuffs) + 10 HP.", "+30 HP.": "+30 HP.",
	"Tap! Kereta MRT lewat: 45 damage ke semua musuh.": "Tap! The MRT train rushes past: 45 damage to all enemies.",
	"Pekerja": "Worker", "Karyawati": "Office Worker", "Satpam": "Security Guard", "Bang Ojol": "Ojol Driver",
	"Mas Kopi": "Coffee Guy", "Kakek Harjo": "Grandpa Harjo", "Pak Pemandu": "Tour Guide", "Mas Barista": "Barista",
	"Pengamen": "Busker", "Pak Sopir": "Bus Driver", "Mas OB": "Office Boy",
}

const ELEM_NAME := {"fisik": ["FISIK", "PHYSICAL"], "api": ["API", "FIRE"], "listrik": ["LISTRIK", "SHOCK"], "kertas": ["KERTAS", "PAPER"]}
const AREA_LVL := {"dukuh": 1.0, "monas": 1.3, "kotatua": 1.6, "blokm": 1.9, "scbd": 2.3}


var lang := "id"
var touch_mode := false


## Pilih teks sesuai bahasa: L("indonesia", "english").
func L(id_text: String, en_text: String) -> String:
	return en_text if lang == "en" else id_text


## Terjemahkan teks data.
func T(s: String) -> String:
	return EN.get(s, s) if lang == "en" else s


func set_touch(v: bool) -> void:
	touch_mode = v
	set_lang(lang)


func set_lang(l: String) -> void:
	lang = l
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"lang": lang, "touch": touch_mode}))
	changed.emit()


func _load_settings() -> void:
	touch_mode = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")
	if FileAccess.file_exists("user://settings.json"):
		var f := FileAccess.open("user://settings.json", FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if typeof(d) == TYPE_DICTIONARY:
			lang = d.get("lang", "id")
			touch_mode = d.get("touch", touch_mode)


var party := {}
var bag := {}
var money := 60000
var flags := {}
var area := "dukuh"
var pos := Vector2(300, 600)
var stats := {"parry": 0, "perfect": 0, "battles": 0, "chests": 0}
var play_time := 0.0

var ui_theme: Theme
var autoplay := false
var shot_dir := ""
var _shot_i := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_settings()
	ui_theme = _make_theme()
	get_tree().root.theme = ui_theme
	for a in OS.get_cmdline_user_args():
		if a == "--autoplay":
			autoplay = true
		elif a.begins_with("--shots="):
			shot_dir = a.substr(8)
	new_run()
	if autoplay and shot_dir != "":
		_auto_shots()


func _process(delta: float) -> void:
	play_time += delta


func _auto_shots() -> void:
	while true:
		await get_tree().create_timer(1.0).timeout
		shot("auto")


func new_run() -> void:
	party.clear()
	for id in HEROES:
		var d: Dictionary = HEROES[id]
		party[id] = {"hp": d.hp, "max_hp": d.hp, "atk": d.atk, "spd": d.spd, "level": 1, "exp": 0}
	bag = {"nasi": 2, "air": 3, "kopi": 1, "plester": 1}
	money = 60000
	flags = {}
	area = "dukuh"
	pos = Vector2(260, 610)
	stats = {"parry": 0, "perfect": 0, "battles": 0, "chests": 0}
	play_time = 0.0
	changed.emit()


func full_heal() -> void:
	for id in party:
		party[id].hp = party[id].max_hp
	changed.emit()


func flag(k: String) -> bool:
	return flags.get(k, false)


func set_flag(k: String, v := true) -> void:
	flags[k] = v
	changed.emit()


func cards() -> int:
	var n := 0
	for k in ["kartu_monas", "kartu_kotatua", "kartu_blokm"]:
		if flag(k):
			n += 1
	return n


func add_item(id: String, n := 1) -> void:
	bag[id] = bag.get(id, 0) + n
	changed.emit()


func use_item(id: String) -> void:
	bag[id] = max(0, bag.get(id, 0) - 1)
	if bag[id] == 0:
		bag.erase(id)
	changed.emit()


func bag_total() -> int:
	var n := 0
	for id in bag:
		n += bag[id]
	return n


func exp_next(level: int) -> int:
	return 30 + level * 20


## Tambah EXP ke semua hero. Kembalikan daftar teks level up.
func gain_exp(n: int) -> Array:
	var ups := []
	for id in party:
		var p: Dictionary = party[id]
		p.exp += n
		while p.exp >= exp_next(p.level):
			p.exp -= exp_next(p.level)
			p.level += 1
			p.max_hp += 8
			p.atk += 2
			p.hp = p.max_hp
			ups.append(L("%s naik ke Lv %d!  HP +8  ATK +2", "%s reached Lv %d!  HP +8  ATK +2") % [HEROES[id].name, p.level])
	changed.emit()
	return ups


## Data musuh untuk battle. lvl = pengali kekuatan area.
func enemy_data(id: String, lvl := 1.0) -> Dictionary:
	var d: Dictionary
	if ENEMIES.has(id):
		d = ENEMIES[id].duplicate(true)
		d["kind"] = id
	else:
		var v: Dictionary = VARIANTS[id]
		d = ENEMIES[v.base].duplicate(true)
		d["kind"] = v.base
		d.name = v.name
		d.hp = int(d.hp * v.hp_mul)
		d.atk = int(round(d.atk * v.atk_mul))
		d.scale = d.scale * v.scale_mul
		d["tint"] = v.tint
		d.exp = v.exp
		d.money = v.money
		for k in ["boss", "final", "weak", "resist", "spd", "quote", "moves", "heals", "flee", "panic"]:
			if v.has(k):
				d[k] = v[k]
	d["variant"] = id
	d.hp = int(d.hp * lvl)
	d.atk = int(round(d.atk * (0.5 + 0.5 * lvl)))
	d.exp = int(d.exp * lvl)
	d.money = int(d.money * (0.6 + 0.4 * lvl))
	return d


func area_defeated(area_id: String) -> int:
	var n := 0
	for e in Story.AREAS[area_id].enemies:
		if flag("def_" + e.id) and not e.get("boss", false):
			n += 1
	return n


func add_kill(kind: String) -> void:
	stats["kill_" + kind] = int(stats.get("kill_" + kind, 0)) + 1


func rp(n: int) -> String:
	var s := str(n)
	var out := ""
	var c := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "." + out
	return "Rp " + out


# ---------------------------------------------------------------- simpan

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var d := {"party": party, "bag": bag, "money": money, "flags": flags, "area": area,
		"pos": [pos.x, pos.y], "stats": stats, "time": play_time}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d))


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return false
	new_run()
	for id in d.party:
		for k in d.party[id]:
			party[id][k] = int(d.party[id][k])
	bag = {}
	for k in d.bag:
		bag[k] = int(d.bag[k])
	money = int(d.money)
	flags = d.flags
	area = d.area
	pos = Vector2(d.pos[0], d.pos[1])
	for k in d.stats:
		stats[k] = int(d.stats[k])
	play_time = float(d.get("time", 0.0))
	changed.emit()
	return true


# ---------------------------------------------------------------- input

func is_act(e: InputEvent) -> bool:
	if e.is_action_pressed("act"):
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false


func auto_chance(p: float) -> bool:
	return randf() < p


func shot(tag: String) -> void:
	if shot_dir == "":
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_shot_i += 1
	img.save_png("%s/%03d_%s.png" % [shot_dir, _shot_i, tag])


func _setup_input() -> void:
	_add_keys("act", [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_J])
	_add_keys("back", [KEY_X, KEY_ESCAPE, KEY_BACKSPACE, KEY_K])
	_add_keys("menu", [KEY_C, KEY_TAB, KEY_I])
	_add_keys("parry", [KEY_Z, KEY_J])
	_add_keys("dodge", [KEY_X, KEY_K])
	_add_keys("move_left", [KEY_LEFT, KEY_A])
	_add_keys("move_right", [KEY_RIGHT, KEY_D])
	_add_keys("move_up", [KEY_UP, KEY_W])
	_add_keys("move_down", [KEY_DOWN, KEY_S])
	_add_keys("ui_accept", [KEY_Z, KEY_J])
	_add_keys("ui_cancel", [KEY_X, KEY_K])
	for pair in [["act", JOY_BUTTON_A], ["back", JOY_BUTTON_B], ["parry", JOY_BUTTON_RIGHT_SHOULDER], ["dodge", JOY_BUTTON_B], ["menu", JOY_BUTTON_Y]]:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pair[1]
		InputMap.action_add_event(pair[0], jb)


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.keycode = k
		InputMap.action_add_event(action, e)


static func paper_box(bg: Color = CREAM, border: Color = INK, radius := 8, shadow := 5) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 1 if shadow > 0 else 0
	s.shadow_offset = Vector2(shadow, shadow)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_UI
	t.default_font_size = 22
	t.set_stylebox("normal", "Button", paper_box())
	t.set_stylebox("hover", "Button", paper_box(Color("fff4cf")))
	t.set_stylebox("focus", "Button", paper_box(YELLOW, INK, 8, 7))
	t.set_stylebox("pressed", "Button", paper_box(Color("ffb830"), INK, 8, 2))
	t.set_stylebox("disabled", "Button", paper_box(Color("bdb6a8"), Color("5a5560"), 8, 3))
	for c in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("6b6570"))
	t.set_constant("h_separation", "Button", 12)
	t.set_constant("icon_max_width", "Button", 44)
	t.set_stylebox("panel", "PanelContainer", paper_box())
	t.set_stylebox("panel", "Panel", paper_box())
	t.set_color("font_color", "Label", INK)
	return t
