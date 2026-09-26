class_name Story
extends RefCounted
## Data dunia & cerita: area, NPC, musuh yang berkeliaran, bos, dan dialog.

const W := "res://assets/world/"

## Tiap area = panorama beberapa panel (1 panel = 1279 px). Posisi dalam koordinat dunia.
## npc.quest: give (serahkan item), fetch (bawa barang temuan), bounty (kalahkan N musuh), gift (hadiah).
const MAPS := "res://assets/maps/"
const MO := "res://assets/mon/"
const N2 := "res://assets/npc2/"

## 7 lokasi x 2 sisi. Jalan ke tepi kanan/kiri untuk pindah sisi.
const AREAS := {
	"dukuh": {"name": "Dukuh Atas · Plaza Transit", "name_en": "Dukuh Atas · Transit Plaza", "bg": MAPS + "dukuh_1.jpg", "music": "bgm_title", "wide": true, "lvl": 1.0,
		"floor": [595, 700], "map": Vector2(655, 390), "station": Vector2(150, 610), "east": "dukuh2",
		"npcs": [
			{"id": "satpam_da", "who": "satpam", "sprite": W + "npc_target.png", "pos": Vector2(560, 605), "talk": "satpam_da", "quest": {"id": "air", "type": "give", "item": "air", "n": 1, "reward": {"money": 10000, "item": "kopi", "count": 2}, "ask": "q_air_ask", "done": "q_air_done", "after": "q_air_after", "desc": ["Bawakan 1 Air Mineral untuk Pak Satpam (Dukuh Atas).", "Bring 1 Mineral Water to the guard (Dukuh Atas)."]}},
			{"id": "kopi_da", "who": "kopi_keliling", "sprite": W + "npc_target.png", "pos": Vector2(1450, 630), "tint": Color(1.1, 1.0, 0.8), "quest": {"id": "mkopi", "type": "gift", "reward": {"item": "kopi", "count": 1}, "done": "q_mkopi_done", "after": "q_mkopi_after"}},
			{"id": "bagas", "who": "bagas", "sprite": N2 + "npc_bagas.png", "pos": Vector2(2050, 610), "talk": "n_bagas"},
		],
		"enemies": [
			{"id": "da_1", "sprite": W + "d_deadline.png", "pos": Vector2(850, 620), "group": ["deadline"]},
			{"id": "da_2", "sprite": W + "d_revisi.png", "pos": Vector2(1150, 640), "group": ["deadline", "revisi"]},
			{"id": "da_3", "sprite": W + "d_deadline.png", "pos": Vector2(1750, 620), "group": ["notif", "notif"], "tint": Color(1.1, 1.1, 0.6), "small": true},
		],
		"treasures": [
			{"id": "da_t1", "pos": Vector2(2300, 680), "reward": {"money": 15000}},
		]},
	"dukuh2": {"name": "Dukuh Atas · Bawah Jembatan", "name_en": "Dukuh Atas · Under the Bridge", "bg": MAPS + "dukuh_2.jpg", "music": "bgm_title", "wide": true, "lvl": 1.0,
		"floor": [595, 700], "map": Vector2(655, 390), "west": "dukuh",
		"npcs": [
			{"id": "ojol_da", "who": "ojol", "sprite": W + "npc_deadline.png", "pos": Vector2(650, 630), "tint": Color(0.8, 1.1, 0.8), "talk": "da_ojol"},
			{"id": "sinta_da", "who": "mahasiswi", "sprite": W + "npc_revisi.png", "pos": Vector2(1850, 615), "tint": Color(1.1, 0.9, 1.0), "flip": true, "talk": "da_sinta"},
		],
		"enemies": [
			{"id": "da_4", "sprite": W + "d_revisi.png", "pos": Vector2(1150, 640), "group": ["revisi"]},
			{"id": "da_5", "sprite": W + "d_deadline.png", "pos": Vector2(1500, 620), "group": ["notif", "deadline"]},
			{"id": "da_6", "sprite": MO + "mon_spam.png", "pos": Vector2(2350, 640), "group": ["spam"], "tint": Color(1,1,1)},
			{"id": "da_7", "sprite": MO + "mon_buffer.png", "pos": Vector2(2800, 640), "group": ["buffer"]},
		],
		"treasures": [
			{"id": "da_t2", "pos": Vector2(2950, 690), "reward": {"item": "plester", "count": 2}},
		]},
	"monas": {"name": "Monas · Taman Monumen", "name_en": "Monas · Monument Park", "bg": MAPS + "monas_1.jpg", "music": "bgm_title", "wide": true, "lvl": 1.3,
		"floor": [595, 700], "map": Vector2(658, 199), "station": Vector2(150, 610), "east": "monas2", "boss_after": 7,
		"npcs": [
			{"id": "penjual_monas", "who": "karyawati", "sprite": W + "npc_revisi.png", "pos": Vector2(420, 610), "talk": "monas_npc"},
			{"id": "dimas", "who": "anak", "sprite": W + "npc_deadline.png", "pos": Vector2(1350, 640), "tint": Color(1.0, 1.0, 1.15), "scale": 0.8, "quest": {"id": "layang", "type": "fetch", "key": "layangan", "reward": {"money": 15000, "item": "kartu", "count": 1}, "ask": "q_layang_ask", "done": "q_layang_done", "after": "q_layang_after", "desc": ["Temukan layangan Dimas di sekitar Monas.", "Find Dimas's kite around Monas."]}},
			{"id": "joko", "who": "joko", "sprite": N2 + "npc_joko.png", "pos": Vector2(2450, 615), "talk": "n_joko"},
		],
		"enemies": [
			{"id": "mo_1", "sprite": W + "d_revisi.png", "pos": Vector2(900, 640), "group": ["revisi", "revisi"]},
			{"id": "mo_2", "sprite": W + "d_deadline.png", "pos": Vector2(1650, 660), "group": ["deadline", "revisi", "deadline"]},
			{"id": "mo_3", "sprite": W + "d_deadline.png", "pos": Vector2(2150, 620), "group": ["notif", "notif", "notif"], "tint": Color(1.1, 1.1, 0.6), "small": true},
			{"id": "mo_4", "sprite": W + "d_revisi.png", "pos": Vector2(3050, 640), "group": ["rapat"], "tint": Color(0.75, 1.25, 0.85)},
			{"id": "mo_4b", "sprite": MO + "mon_gosip.png", "pos": Vector2(3650, 640), "group": ["gosip", "revisi"]},
		],
		"treasures": [
			{"id": "mo_t1", "pos": Vector2(2750, 610), "reward": {"key": "layangan"}},
		]},
	"monas2": {"name": "Monas · Jalur Taman Timur", "name_en": "Monas · East Garden Path", "bg": MAPS + "monas_2.jpg", "music": "bgm_title", "wide": true, "lvl": 1.3,
		"floor": [595, 700], "map": Vector2(658, 199), "west": "monas", "boss_after": 7,
		"npcs": [
			{"id": "kakek", "who": "kakek", "sprite": W + "npc_lembur.png", "pos": Vector2(700, 610), "tint": Color(1.0, 0.95, 0.85), "talk": "mo_kakek"},
			{"id": "intan", "who": "intan", "sprite": N2 + "npc_intan.png", "pos": Vector2(1850, 620), "quest": {"id": "sepeda2", "type": "bounty", "kinds": ["spam", "notif"], "n": 3, "reward": {"money": 18000, "item": "roti", "count": 2}, "ask": "q_intan_ask", "done": "q_intan_done", "after": "q_intan_after", "desc": ["Kalahkan 3 Spam/Notifikasi untuk Intan (Monas).", "Defeat 3 Spam/Notification enemies for Intan (Monas)."]}},
			{"id": "rina", "who": "fotografer", "sprite": W + "npc_revisi.png", "pos": Vector2(3200, 615), "tint": Color(1.2, 1.0, 0.8), "flip": true, "quest": {"id": "foto", "type": "gift", "reward": {"item": "roti", "count": 2}, "done": "q_foto_done", "after": "q_foto_after"}},
		],
		"enemies": [
			{"id": "mo_5", "sprite": W + "d_revisi.png", "pos": Vector2(1300, 640), "group": ["revisi_beku", "revisi"], "tint": Color(0.7, 0.9, 1.35)},
			{"id": "mo_6", "sprite": W + "d_deadline.png", "pos": Vector2(2350, 660), "group": ["deadline_merah"], "tint": Color(1.3, 0.65, 0.6)},
			{"id": "mo_7", "sprite": MO + "mon_spam.png", "pos": Vector2(2800, 640), "group": ["spam", "spam"]},
			{"id": "mo_boss", "sprite": W + "d_revisi.png", "pos": Vector2(3850, 610), "group": ["revisi_agung"], "boss": true, "card": "kartu_monas", "pre": "monas_boss_pre", "post": "monas_boss_post"},
		],
		"treasures": [
			{"id": "mo_t2", "pos": Vector2(2550, 690), "reward": {"money": 20000}},
			{"id": "mo_t3", "pos": Vector2(4000, 660), "reward": {"item": "nasi", "count": 2}},
		]},
	"kotatua": {"name": "Kota Tua · Plaza Fatahillah", "name_en": "Kota Tua · Fatahillah Plaza", "bg": MAPS + "kotatua_1.jpg", "music": "bgm_title", "wide": true, "lvl": 1.6,
		"floor": [595, 700], "map": Vector2(689, 77), "station": Vector2(150, 610), "east": "kotatua2", "boss_after": 7,
		"npcs": [
			{"id": "sepeda", "who": "pekerja", "sprite": W + "npc_deadline.png", "pos": Vector2(900, 610), "quest": {"id": "sepeda", "type": "bounty", "kinds": ["target", "kpi", "target_emas"], "n": 3, "reward": {"money": 20000, "item": "plester", "count": 3}, "ask": "q_sepeda_ask", "done": "q_sepeda_done", "after": "q_sepeda_after", "desc": ["Kalahkan 3 musuh jenis Target/KPI (Kota Tua).", "Defeat 3 Quota/KPI-type enemies (Kota Tua)."]}},
			{"id": "darma", "who": "darma", "sprite": N2 + "npc_darma.png", "pos": Vector2(1950, 610), "talk": "n_darma"},
			{"id": "pemandu", "who": "pemandu", "sprite": W + "npc_lembur.png", "pos": Vector2(3050, 605), "tint": Color(0.9, 0.9, 1.1), "talk": "kt_pemandu"},
		],
		"enemies": [
			{"id": "kt_1", "sprite": W + "d_target.png", "pos": Vector2(600, 640), "group": ["target"]},
			{"id": "kt_2", "sprite": W + "d_deadline.png", "pos": Vector2(1350, 620), "group": ["deadline", "target"]},
			{"id": "kt_3", "sprite": W + "d_revisi.png", "pos": Vector2(2350, 660), "group": ["revisi", "target", "revisi"]},
			{"id": "kt_4", "sprite": W + "d_target.png", "pos": Vector2(3550, 640), "group": ["target_emas"], "tint": Color(1.35, 1.15, 0.45)},
		],
		"treasures": [
			{"id": "kt_t1", "pos": Vector2(1600, 610), "reward": {"key": "biji_kopi"}},
		]},
	"kotatua2": {"name": "Kota Tua · Lorong Kali Besar", "name_en": "Kota Tua · Kali Besar Lane", "bg": MAPS + "kotatua_2.jpg", "music": "bgm_title", "wide": true, "lvl": 1.6,
		"floor": [595, 700], "map": Vector2(689, 77), "west": "kotatua", "boss_after": 7,
		"npcs": [
			{"id": "wayan", "who": "seniman", "sprite": W + "npc_target.png", "pos": Vector2(900, 615), "tint": Color(1.0, 0.85, 1.1), "flip": true, "talk": "kt_seniman"},
		],
		"enemies": [
			{"id": "kt_5", "sprite": W + "d_target.png", "pos": Vector2(1450, 640), "group": ["kpi"], "tint": Color(1.35, 0.7, 0.7)},
			{"id": "kt_6", "sprite": W + "d_deadline.png", "pos": Vector2(2050, 620), "group": ["notif", "notif", "deadline_merah"], "tint": Color(1.3, 0.65, 0.6)},
			{"id": "kt_7", "sprite": W + "d_target.png", "pos": Vector2(2750, 660), "group": ["kpi", "revisi_beku"], "tint": Color(1.35, 0.7, 0.7)},
			{"id": "kt_8", "sprite": MO + "mon_reimburse.png", "pos": Vector2(3350, 640), "group": ["reimburse", "absensi"]},
			{"id": "kt_boss", "sprite": W + "d_target.png", "pos": Vector2(4150, 610), "group": ["target_raksasa"], "boss": true, "card": "kartu_kotatua", "pre": "kotatua_boss_pre", "post": "kotatua_boss_post"},
		],
		"treasures": [
			{"id": "kt_t2", "pos": Vector2(1750, 690), "reward": {"money": 25000}},
			{"id": "kt_t3", "pos": Vector2(3650, 620), "reward": {"item": "kopi", "count": 2}},
		]},
	"tanahabang": {"name": "Tanah Abang · Pintu Pasar", "name_en": "Tanah Abang · Market Gate", "bg": MAPS + "tanahabang_1.jpg", "music": "bgm_title", "wide": true, "lvl": 1.75,
		"floor": [595, 700], "map": Vector2(290, 222), "station": Vector2(150, 610), "east": "tanahabang2", "boss_after": 8,
		"npcs": [
			{"id": "lilis", "who": "lilis", "sprite": N2 + "npc_lilis.png", "pos": Vector2(950, 615), "quest": {"id": "benang", "type": "give", "item": "roti", "n": 2, "reward": {"money": 25000, "item": "nasi", "count": 3}, "ask": "q_lilis_ask", "done": "q_lilis_done", "after": "q_lilis_after", "desc": ["Bawakan 2 Roti Bakar untuk Bu Lilis (Tanah Abang).", "Bring 2 Toast to Mrs. Lilis (Tanah Abang)."]}},
			{"id": "arman", "who": "arman", "sprite": N2 + "npc_arman.png", "pos": Vector2(2650, 615), "quest": {"id": "angkut", "type": "bounty", "kinds": ["arsip", "fotokopi", "komuter"], "n": 4, "reward": {"money": 30000, "item": "kartu", "count": 2}, "ask": "q_arman_ask", "done": "q_arman_done", "after": "q_arman_after", "desc": ["Kalahkan 4 Arsip/Fotokopi/Komuter untuk Arman (Tanah Abang).", "Defeat 4 Archive/Photocopier/Commuter enemies for Arman (Tanah Abang)."]}},
		],
		"enemies": [
			{"id": "ta_1", "sprite": MO + "mon_komuter.png", "pos": Vector2(700, 640), "group": ["komuter"]},
			{"id": "ta_2", "sprite": MO + "mon_gosip.png", "pos": Vector2(1500, 620), "group": ["gosip", "gosip"]},
			{"id": "ta_3", "sprite": MO + "mon_reimburse.png", "pos": Vector2(2050, 660), "group": ["reimburse", "absensi"]},
			{"id": "ta_4", "sprite": MO + "mon_fotokopi.png", "pos": Vector2(3100, 640), "group": ["fotokopi"]},
			{"id": "ta_5", "sprite": MO + "mon_komuter.png", "pos": Vector2(3650, 620), "group": ["komuter", "spam"]},
		],
		"treasures": [
			{"id": "ta_t1", "pos": Vector2(3950, 690), "reward": {"item": "plester", "count": 3}},
		]},
	"tanahabang2": {"name": "Tanah Abang · Gang Tekstil", "name_en": "Tanah Abang · Textile Alley", "bg": MAPS + "tanahabang_2.jpg", "music": "bgm_title", "wide": true, "lvl": 1.75,
		"floor": [595, 700], "map": Vector2(290, 222), "west": "tanahabang", "boss_after": 8,
		"npcs": [
		],
		"enemies": [
			{"id": "ta_6", "sprite": MO + "mon_arsip.png", "pos": Vector2(900, 640), "group": ["arsip"]},
			{"id": "ta_7", "sprite": MO + "mon_kontrak.png", "pos": Vector2(1700, 620), "group": ["kontrak"]},
			{"id": "ta_8", "sprite": MO + "mon_shiftganda.png", "pos": Vector2(2500, 660), "group": ["shiftganda", "gosip"]},
			{"id": "ta_9", "sprite": MO + "mon_arsip.png", "pos": Vector2(3300, 640), "group": ["arsip", "fotokopi"]},
			{"id": "ta_boss", "sprite": MO + "mon_kontrak.png", "pos": Vector2(4350, 610), "group": ["juragan"], "boss": true, "pre": "ta_boss_pre", "post": "ta_boss_post"},
		],
		"treasures": [
			{"id": "ta_t2", "pos": Vector2(2050, 690), "reward": {"money": 35000}},
			{"id": "ta_t3", "pos": Vector2(4050, 620), "reward": {"item": "kopi", "count": 3}},
		]},
	"blokm": {"name": "Blok M · Plaza MRT", "name_en": "Blok M · MRT Plaza", "bg": MAPS + "blokm_1.jpg", "music": "bgm_title", "wide": true, "lvl": 1.9,
		"floor": [595, 700], "map": Vector2(475, 475), "station": Vector2(150, 610), "shop": Vector2(700, 600), "east": "blokm2", "boss_after": 7,
		"npcs": [
			{"id": "barista", "who": "barista", "sprite": W + "npc_deadline.png", "pos": Vector2(1450, 620), "tint": Color(0.9, 0.8, 0.7), "quest": {"id": "barista", "type": "fetch", "key": "biji_kopi", "reward": {"money": 15000, "item": "kopi", "count": 3}, "ask": "q_barista_ask", "done": "q_barista_done", "after": "q_barista_after", "desc": ["Cari karung biji kopi di Kota Tua untuk Mas Barista.", "Find a sack of coffee beans in Kota Tua for the barista."]}},
			{"id": "pengamen", "who": "pengamen", "sprite": W + "npc_target.png", "pos": Vector2(2150, 640), "tint": Color(1.1, 0.8, 0.9), "talk": "bm_pengamen"},
		],
		"enemies": [
			{"id": "bm_1", "sprite": W + "d_lembur.png", "pos": Vector2(1000, 660), "group": ["lembur"]},
			{"id": "bm_2", "sprite": W + "d_target.png", "pos": Vector2(1800, 640), "group": ["target", "deadline", "revisi"]},
			{"id": "bm_3", "sprite": W + "d_lembur.png", "pos": Vector2(2400, 620), "group": ["lembur_bayang"], "tint": Color(0.55, 0.45, 0.85)},
		],
		"treasures": [
			{"id": "bm_t1", "pos": Vector2(1650, 610), "reward": {"item": "nasi", "count": 2}},
		]},
	"blokm2": {"name": "Blok M · Gang Kuliner", "name_en": "Blok M · Food Alley", "bg": MAPS + "blokm_2.jpg", "music": "bgm_title", "wide": true, "lvl": 1.9,
		"floor": [595, 700], "map": Vector2(475, 475), "west": "blokm", "boss_after": 7,
		"npcs": [
			{"id": "sopir", "who": "sopir", "sprite": W + "npc_lembur.png", "pos": Vector2(700, 610), "tint": Color(0.85, 1.0, 1.1), "flip": true, "talk": "bm_sopir"},
		],
		"enemies": [
			{"id": "bm_4", "sprite": W + "d_revisi.png", "pos": Vector2(1100, 660), "group": ["rapat", "kpi"], "tint": Color(0.75, 1.25, 0.85)},
			{"id": "bm_5", "sprite": W + "d_deadline.png", "pos": Vector2(1600, 630), "group": ["deadline_merah", "deadline_merah"], "tint": Color(1.3, 0.65, 0.6)},
			{"id": "bm_6", "sprite": W + "d_lembur.png", "pos": Vector2(2100, 660), "group": ["lembur", "notif"]},
			{"id": "bm_7", "sprite": MO + "mon_presentasi.png", "pos": Vector2(2550, 640), "group": ["presentasi", "buffer"]},
			{"id": "bm_boss", "sprite": W + "d_lembur.png", "pos": Vector2(3000, 610), "group": ["lembur_manajer", "deadline"], "boss": true, "card": "kartu_blokm", "pre": "blokm_boss_pre", "post": "blokm_boss_post"},
		],
		"treasures": [
			{"id": "bm_t2", "pos": Vector2(1350, 690), "reward": {"money": 30000}},
			{"id": "bm_t3", "pos": Vector2(3100, 660), "reward": {"item": "kartu", "count": 1}},
		]},
	"cikini": {"name": "Cikini · Halaman Seni", "name_en": "Cikini · Art Courtyard", "bg": MAPS + "cikini_1.jpg", "music": "bgm_title", "wide": true, "lvl": 2.0,
		"floor": [595, 700], "map": Vector2(1026, 230), "station": Vector2(150, 610), "east": "cikini2", "boss_after": 6,
		"npcs": [
			{"id": "sekar", "who": "sekar", "sprite": N2 + "npc_sekar.png", "pos": Vector2(700, 615), "quest": {"id": "kuas", "type": "bounty", "kinds": ["presentasi", "gosip", "buffer"], "n": 3, "reward": {"money": 25000, "item": "roti", "count": 3}, "ask": "q_sekar_ask", "done": "q_sekar_done", "after": "q_sekar_after", "desc": ["Kalahkan 3 Presentasi/Gosip/Buffer untuk Sekar (Cikini).", "Defeat 3 Presentation/Gossip/Buffer enemies for Sekar (Cikini)."]}},
		],
		"enemies": [
			{"id": "ck_1", "sprite": MO + "mon_presentasi.png", "pos": Vector2(1150, 640), "group": ["presentasi"]},
			{"id": "ck_2", "sprite": MO + "mon_gosip.png", "pos": Vector2(1750, 620), "group": ["gosip", "buffer"]},
			{"id": "ck_3", "sprite": MO + "mon_rapat.png", "pos": Vector2(2350, 660), "group": ["rapatmeja"]},
		],
		"treasures": [
			{"id": "ck_t1", "pos": Vector2(2550, 690), "reward": {"money": 30000}},
		]},
	"cikini2": {"name": "Cikini · Lorong Kopi", "name_en": "Cikini · Coffee Lane", "bg": MAPS + "cikini_2.jpg", "music": "bgm_title", "wide": true, "lvl": 2.0,
		"floor": [595, 700], "map": Vector2(1026, 230), "west": "cikini", "boss_after": 6,
		"npcs": [
		],
		"enemies": [
			{"id": "ck_4", "sprite": MO + "mon_shiftganda.png", "pos": Vector2(700, 640), "group": ["shiftganda"]},
			{"id": "ck_5", "sprite": MO + "mon_spam.png", "pos": Vector2(1300, 620), "group": ["spam", "spam", "gosip"]},
			{"id": "ck_6", "sprite": MO + "mon_kontrak.png", "pos": Vector2(1900, 660), "group": ["kontrak", "presentasi"]},
			{"id": "ck_boss", "sprite": MO + "boss_ratu.png", "pos": Vector2(2600, 610), "group": ["ratu"], "boss": true, "pre": "ratu_pre", "post": "ratu_post"},
		],
		"treasures": [
			{"id": "ck_t2", "pos": Vector2(1600, 690), "reward": {"item": "nasi", "count": 3}},
		]},
	"scbd": {"name": "SCBD · Lobi Menara Shift", "name_en": "SCBD · Shift Tower Lobby", "bg": MAPS + "scbd_1.jpg", "music": "bgm_boss", "wide": true, "lvl": 2.3,
		"floor": [595, 700], "map": Vector2(980, 459), "station": Vector2(150, 610), "east": "scbd2",
		"npcs": [
			{"id": "ob", "who": "ob", "sprite": W + "npc_deadline.png", "pos": Vector2(500, 615), "tint": Color(0.8, 1.0, 0.8), "talk": "sc_ob"},
			{"id": "dewi", "who": "sekretaris", "sprite": W + "npc_revisi.png", "pos": Vector2(1450, 610), "tint": Color(1.0, 0.8, 0.85), "quest": {"id": "idcard", "type": "fetch", "key": "id_card", "reward": {"money": 40000, "item": "kartu", "count": 1}, "ask": "q_id_ask", "done": "q_id_done", "after": "q_id_after", "desc": ["Temukan ID card Mbak Dewi yang jatuh di SCBD.", "Find Dewi's lost ID card in SCBD."]}},
			{"id": "vina", "who": "vina", "sprite": N2 + "npc_vina.png", "pos": Vector2(2150, 610), "talk": "n_vina"},
		],
		"enemies": [
			{"id": "sc_1", "sprite": W + "d_lembur.png", "pos": Vector2(900, 660), "group": ["lembur", "target"]},
			{"id": "sc_2", "sprite": W + "d_deadline.png", "pos": Vector2(1750, 640), "group": ["deadline", "lembur", "revisi"]},
			{"id": "sc_3", "sprite": W + "d_lembur.png", "pos": Vector2(2400, 620), "group": ["lembur_bayang", "lembur_bayang"], "tint": Color(0.55, 0.45, 0.85)},
		],
		"treasures": [
			{"id": "sc_t2", "pos": Vector2(1150, 690), "reward": {"item": "roti", "count": 3}},
		]},
	"scbd2": {"name": "SCBD · Jalur Servis", "name_en": "SCBD · Service Lane", "bg": MAPS + "scbd_2.jpg", "music": "bgm_boss", "wide": true, "lvl": 2.3,
		"floor": [595, 700], "map": Vector2(980, 459), "west": "scbd", "gate": Vector2(2880, 600),
		"npcs": [
			{"id": "satpam_scbd", "who": "satpam", "sprite": W + "npc_target.png", "pos": Vector2(2450, 605), "talk": "scbd_satpam"},
		],
		"enemies": [
			{"id": "sc_4", "sprite": W + "d_target.png", "pos": Vector2(700, 660), "group": ["kpi", "rapat", "kpi"], "tint": Color(1.35, 0.7, 0.7)},
			{"id": "sc_5", "sprite": W + "d_deadline.png", "pos": Vector2(1300, 630), "group": ["deadline_merah", "lembur_bayang"], "tint": Color(1.3, 0.65, 0.6)},
			{"id": "sc_6", "sprite": W + "d_target.png", "pos": Vector2(1900, 640), "group": ["target_emas"], "tint": Color(1.35, 1.15, 0.45)},
			{"id": "sc_7", "sprite": MO + "mon_shiftganda.png", "pos": Vector2(2200, 660), "group": ["shiftganda", "absensi", "buffer"]},
		],
		"treasures": [
			{"id": "sc_t1", "pos": Vector2(1600, 620), "reward": {"key": "id_card"}},
			{"id": "sc_t3", "pos": Vector2(1050, 690), "reward": {"money": 40000}},
		]},
}

const KEY_ITEMS := {
	"layangan": ["Layangan Dimas", "Dimas's Kite"],
	"biji_kopi": ["Karung Biji Kopi", "Sack of Coffee Beans"],
	"id_card": ["ID Card Mbak Dewi", "Dewi's ID Card"],
}

const MAP_LOCKED := {}
const AREA_ORDER := ["dukuh", "monas", "kotatua", "tanahabang", "blokm", "cikini", "scbd"]

## Pekerja yang sudah dibebaskan: [id, en, ja]
const FREED := [
	["Hah... aku di mana? Terakhir ingat lagi bikin laporan jam 11 malam.", "Huh... where am I? Last thing I remember is writing a report at 11 PM.", "あれ…ここどこ？夜の十一時にレポート書いてたはずなのに。"],
	["Makasih ya. Rasanya kayak bangun dari rapat tiga jam.", "Thanks. Feels like waking up from a three-hour meeting.", "ありがとう。三時間の会議から目が覚めた気分だよ。"],
	["Aku... mau pulang. Beneran pulang. Makasih!", "I... want to go home. Actually home. Thank you!", "帰りたい…本当に帰りたい。ありがとう！"],
	["Jadi tadi itu aku? Ya ampun, maaf udah nyerang kalian.", "That was me just now? Oh no, sorry for attacking you.", "さっきのが僕？うわ、襲ってごめんね。"],
	["Kepalaku enteng banget. Kayak habis cuti seminggu.", "My head feels so light. Like after a week of vacation.", "頭が軽い。一週間休んだみたいだ。"],
]

## Dialog: [pembicara, ekspresi, teks Indonesia, teks Inggris, suara Jepang]
const D := {
	"intro": [
		["narator", "", "Jakarta, 18.47. Stasiun MRT Dukuh Atas. Jam pulang kantor.", "Jakarta, 6:47 PM. Dukuh Atas MRT Station. Rush hour.", "ジャカルタ、午後六時四十七分。ドゥク・アタス駅。帰宅ラッシュの時間だ。"],
		["tara", "tired", "Akhirnya pulang. Delapan jam rapat yang harusnya cukup jadi email.", "Finally going home. Eight hours of meetings that should've been an email.", "やっと帰れる。メールで済む会議を八時間もやったよ。"],
		["raka", "happy", "Semangat, Tar! Tinggal tap kartu, duduk, tidur sampai Blok M.", "Cheer up, Tara! Just tap in, sit down, and nap till Blok M.", "元気出せよ、タラ！カードをタッチして、ブロックエムまで寝るだけだ。"],
		["tara", "normal", "Raka... kenapa orang-orang kantor jalannya kayak zombie?", "Raka... why are the office people walking like zombies?", "ラカ…なんで会社の人たち、ゾンビみたいに歩いてるの？"],
		["raka", "normal", "Itu Pak Dedi dari Finance. Kok badannya dililit jam dinding?", "That's Mr. Dedi from Finance. Why is he wrapped in wall clocks?", "あれ、経理のデディさんだ。なんで時計に巻かれてるんだ？"],
		["narator", "", "Kertas-kertas hitam beterbangan. Para pekerja di sekitar stasiun DIRASUKI LEMBUR.", "Black papers swirl through the air. The workers around the station are POSSESSED BY OVERTIME.", "黒い紙が舞い上がる。駅の周りの社員たちが、残業に取り憑かれていた。"],
		["tara", "focus", "Kita harus bebaskan mereka. Pakai tangan kosong juga nggak apa-apa!", "We have to free them. Bare hands will do!", "みんなを解放しなきゃ。素手でもいい！"],
		["raka", "focus", "Nggak ada yang boleh ganggu jam pulang!", "Nobody messes with quitting time!", "定時の邪魔はさせないぞ！"],
		["narator", "", "PANAH / WASD: jalan.  Z: bicara / serang duluan.  C: menu.  Dekati pekerja yang dirasuki untuk bertarung.", "ARROWS / WASD: walk.  Z: talk / strike first.  C: menu.  Approach possessed workers to fight.", "矢印キーで移動、ゼットで話す、または先制攻撃。"],
	],
	"satpam_da": [
		["satpam", "", "Dek, hati-hati! Sejak sore orang-orang kantor pada kesurupan kerjaan.", "Careful, kids! Since this afternoon the office folks have been possessed by work.", "気をつけなよ！夕方から会社員たちが仕事に取り憑かれてるんだ。"],
		["satpam", "", "Kalau capek, istirahat di papan MRT itu. Sekalian simpan tenaga.", "If you're tired, rest at that MRT sign. Save your strength there.", "疲れたら、あの駅の看板で休むといい。"],
	],
	"prolog_done": [
		["raka", "tired", "Hah... hah... mereka balik normal!", "Huff... huff... they're back to normal!", "はぁ、はぁ…みんな元に戻った！"],
		["pak_dedi", "", "Kalian... makasih. Semua ini gara-gara Menara Shift di SCBD. Sejak pagi lampunya nyala merah terus.", "You two... thank you. It's all because of the Shift Tower in SCBD. Its lights have glowed red since morning.", "ありがとう…全部エスシービーディーのシフトタワーのせいだ。朝から赤く光ってる。"],
		["pak_dedi", "", "Gerbangnya dikunci pakai tiga Kartu Akses. Dipegang tiga manajer yang paling parah dirasuki.", "Its gate is sealed with three Access Cards, held by the three most possessed managers.", "門は三枚のアクセスカードで封印されてる。一番ひどく取り憑かれた三人の上司が持ってるんだ。"],
		["pak_dedi", "", "Satu di Monas, satu di Kota Tua, satu lagi di Blok M.", "One at Monas, one in Kota Tua, and one in Blok M.", "モナスに一人、コタトゥアに一人、ブロックエムに一人。"],
		["tara", "focus", "Oke. Kumpulkan tiga kartu, lalu serbu Menara Shift.", "Okay. Collect three cards, then storm the Shift Tower.", "よし。カードを三枚集めて、シフトタワーに乗り込もう。"],
		["narator", "", "PETA MRT terbuka! Pergi ke papan MRT untuk pindah lokasi. Tiap lokasi punya dua sisi: jalan ke tepi kanan layar. Tanah Abang dan Cikini juga terbuka.", "MRT MAP unlocked! Use the MRT sign to travel. Each place has two sides: walk off the right edge. Tanah Abang and Cikini are open too.", "地下鉄マップが解放された！各地には二つのエリアがある。画面の右端へ歩こう。"],
	],
	"monas_npc": [
		["karyawati", "", "Bosku di sana, di depan Monas. Dia merevisi slide yang sama dari jam 9 pagi.", "My boss is over there by Monas. She's been revising the same slide since 9 AM.", "上司はモナスの前にいるの。朝九時から同じスライドを直してる。"],
		["karyawati", "", "Serangannya cepat-cepat. Lihat lingkaran kuning: tekan Z pas lingkarannya mengecil ke tengah = PARRY!", "Her attacks are fast. Watch the yellow ring: press Z when it shrinks to the center to PARRY!", "攻撃が速いの。黄色い輪が縮んだ瞬間にゼットでパリィして！"],
	],
	"monas_boss_pre": [
		["mbak_rani", "", "Revisi. Revisi. Font-nya kurang besar. Warnanya kurang... biru.", "Revise. Revise. The font isn't big enough. The color isn't... blue enough.", "修正。修正。フォントが小さい。色が…青くない。"],
		["tara", "skeptis", "Mbak, itu udah versi ke-47.", "Ma'am, that's already version 47.", "それ、もう四十七版目ですよ。"],
		["mbak_rani", "", "MASIH. ADA. YANG. BISA. DIPERBAIKI.", "THERE'S. ALWAYS. SOMETHING. TO. FIX.", "まだ、直せる、ところが、ある！"],
	],
	"monas_boss_post": [
		["mbak_rani", "", "Versi pertama... sebenarnya udah bagus ya?", "The first version... was actually fine, wasn't it?", "最初の版…実は良かったのかな？"],
		["tara", "happy", "Dari tadi, Mbak.", "It was all along.", "ずっと良かったですよ。"],
		["narator", "", "Dapat KARTU AKSES MONAS!", "Got the MONAS ACCESS CARD!", "モナスのアクセスカードを手に入れた！"],
	],
	"kotatua_npc": [
		["pekerja", "", "Mau sewa sepeda? Lagi tutup. Bos besar di tengah alun-alun lagi ngejar target.", "Want to rent a bike? We're closed. The big boss in the square is chasing targets.", "自転車？今日は休みだよ。広場のボスがノルマを追ってるんだ。"],
		["pekerja", "", "Tips: lingkaran MERAH itu nggak bisa di-parry. Tekan X untuk DODGE!", "Tip: RED rings can't be parried. Press X to DODGE!", "ヒント、赤い輪はパリィできない。エックスで避けて！"],
	],
	"kotatua_boss_pre": [
		["bang_joko", "", "ANGKA. HARUS. NAIK. Kuartal ini dua ratus persen!", "NUMBERS. MUST. GO. UP. Two hundred percent this quarter!", "数字は、上がらなければ、ならない！今期は二百パーセントだ！"],
		["raka", "normal", "Bang, ini udah jam sembilan malam.", "Bro, it's nine at night.", "兄貴、もう夜の九時だぜ。"],
		["bang_joko", "", "Jam juga harus naik!", "Then the clock must go up too!", "時間も上がるべきだ！"],
	],
	"kotatua_boss_post": [
		["bang_joko", "", "Aduh... punggungku. Kayaknya aku butuh target tidur delapan jam.", "Ow... my back. I think I need a target of eight hours of sleep.", "いてて…腰が。八時間睡眠をノルマにしよう。"],
		["raka", "happy", "Nah, itu baru target yang masuk akal.", "Now that's a reasonable target.", "それなら納得のノルマだな。"],
		["narator", "", "Dapat KARTU AKSES KOTA TUA!", "Got the KOTA TUA ACCESS CARD!", "コタトゥアのアクセスカードを手に入れた！"],
	],
	"busari_hi": [
		["bu_sari", "", "Makan dulu, baru lawan deadline. Mau apa, Nak?", "Eat first, then fight your deadlines. What'll it be, dear?", "まず食べて、それから締め切りと戦いなさい。何にする？"],
	],
	"blokm_boss_pre": [
		["pak_haris", "", "Pulang? Kata itu... sudah dihapus dari kamus perusahaan.", "Go home? That word... has been deleted from the company dictionary.", "帰宅？その言葉は…会社の辞書から消された。"],
		["tara", "focus", "Pak Haris?! Manajer divisi kita?", "Mr. Haris?! Our division manager?", "ハリス部長！？うちの部長じゃない！"],
		["pak_haris", "", "Kerja. Masih. Bisa. Lebih. BANYAK.", "Work. Can. Always. Be. MORE.", "仕事は、まだ、もっと、できる！"],
	],
	"blokm_boss_post": [
		["pak_haris", "", "Anak-anak... maaf. Saya lupa kalian juga punya rumah.", "Kids... I'm sorry. I forgot you have homes too.", "君たち…すまない。みんなにも家があることを忘れていた。"],
		["raka", "normal", "Besok cuti ya, Pak. Beneran cuti.", "Take tomorrow off, sir. For real.", "部長、明日は休んでください。本当に。"],
		["narator", "", "Dapat KARTU AKSES BLOK M!", "Got the BLOK M ACCESS CARD!", "ブロックエムのアクセスカードを手に入れた！"],
	],
	"scbd_satpam": [
		["satpam", "", "Gerbang Menara Shift cuma bisa dibuka pakai tiga Kartu Akses.", "The Shift Tower gate only opens with three Access Cards.", "シフトタワーの門は、三枚のカードでしか開かない。"],
		["satpam", "", "Di dalam... ada sesuatu yang nggak pernah pulang sejak menara ini dibangun.", "Inside... there's something that hasn't gone home since this tower was built.", "中には…塔ができてから一度も帰っていない何かがいる。"],
	],
	"gate_locked": [
		["narator", "", "Gerbang terkunci. Kartu akses: %d / 3.", "The gate is locked. Access cards: %d / 3.", "門は閉まっている。"],
	],
	"final_pre": [
		["narator", "", "Tiga kartu menyala. Gerbang Menara Shift terbuka.", "The three cards glow. The Shift Tower gate opens.", "三枚のカードが光り、シフトタワーの門が開いた。"],
		["lembur", "", "HARI INI. BESOK. SETIAP HARI. SELAMANYA.", "TODAY. TOMORROW. EVERY DAY. FOREVER.", "今日も、明日も、毎日、永遠に。"],
		["tara", "focus", "Jadi kamu yang bikin semua orang lupa pulang.", "So you're the one making everyone forget to go home.", "みんなが帰るのを忘れたのは、あなたのせいね。"],
		["raka", "focus", "Shift ini, kita yang tutup!", "This shift, we're the ones clocking out!", "このシフトは、俺たちが終わらせる！"],
	],
	"ending": [
		["narator", "", "Lampu merah Menara Shift padam. Di seluruh Jakarta, layar laptop menutup satu per satu.", "The Shift Tower's red light goes out. All over Jakarta, laptop lids close one by one.", "シフトタワーの赤い光が消えた。ジャカルタ中で、パソコンが一台ずつ閉じていく。"],
		["pak_dedi", "", "Semua orang pulang. Jalanan macet... tapi macet yang bahagia.", "Everyone's going home. The roads are jammed... but it's a happy jam.", "みんな帰っていく。道は渋滞だけど、幸せな渋滞だ。"],
		["bu_sari", "", "Nah! Pahlawan kita. Nasi bungkus gratis malam ini!", "There they are! Our heroes. Free rice packs tonight!", "来たね、ヒーローたち！今夜はナシブンクス無料だよ！"],
		["tara", "happy", "Jadi... besok masuk jam berapa?", "So... what time do we start tomorrow?", "で…明日は何時から？"],
		["raka", "tired", "Jangan. Sebut. Kerjaan.", "Don't. Mention. Work.", "仕事の、話は、やめろ。"],
		["tara", "happy", "Hahaha. Yuk, pulang. Kali ini beneran pulang.", "Hahaha. Let's go home. For real this time.", "あはは。帰ろう。今度こそ本当に。"],
		["narator", "", "TAMAT. Terima kasih sudah bermain JAKARTA: SHIFT TERAKHIR!", "THE END. Thank you for playing JAKARTA: LAST SHIFT!", "おわり。遊んでくれてありがとう！"],
	],
	"q_air_ask": [
		["satpam", "", "Dek, dari sore saya jaga di sini, belum minum. Punya Air Mineral satu?", "Kid, I've been on duty since the afternoon without a drink. Got a Mineral Water?", "君たち、夕方からずっと立ってて水も飲んでないんだ。ミネラルウォーター、ある？"],
		["satpam", "", "Nanti saya kasih Kopi Susu. Beli di warung juga bisa.", "I'll trade you some Milk Coffee. You can buy water at a stall too.", "お礼にミルクコーヒーをあげるよ。屋台でも買えるさ。"],
	],
	"q_air_done": [
		["satpam", "", "Wah, segarnya! Makasih, Dek.", "Ahh, refreshing! Thanks, kid.", "ああ、生き返る！ありがとう。"],
		["satpam", "", "Ini Kopi Susu dua dan sedikit uang jajan. Hati-hati di jalan!", "Here's two Milk Coffees and a little pocket money. Take care out there!", "ミルクコーヒー二つと、少しだけどお小遣いだ。気をつけてな！"],
	],
	"q_air_after": [
		["satpam", "", "Semangat, Dek! Jakarta butuh orang yang berani pulang tepat waktu.", "Keep it up! Jakarta needs people brave enough to go home on time.", "頑張れよ！ジャカルタには定時で帰る勇者が必要だ。"],
	],
	"q_mkopi_done": [
		["kopi_keliling", "", "Kopi keliling! Kopi keliling! Eh, kalian yang tadi bertarung ya?", "Coffee! Fresh coffee! Hey, you two were the ones fighting just now?", "コーヒー、コーヒーはいかが！あれ、さっき戦ってた二人だよね？"],
		["kopi_keliling", "", "Buat pahlawan, gratis satu. Jangan bilang-bilang bos saya.", "One free cup for the heroes. Don't tell my boss.", "ヒーローには一杯サービスだ。上司には内緒な。"],
	],
	"q_mkopi_after": [
		["kopi_keliling", "", "Kopi habis. Tapi semangat masih penuh!", "Out of coffee. But the spirit's still full!", "コーヒーは売り切れ。でも元気は満タンだ！"],
	],
	"da_ojol": [
		["ojol", "", "Orderan sepi, Mas. Semua orang lembur, nggak ada yang pesan pulang.", "No orders tonight. Everyone's doing overtime, nobody's riding home.", "今夜は注文ゼロだよ。みんな残業で、誰も帰らないんだ。"],
		["ojol", "", "Katanya sumbernya di SCBD. Menara yang lampunya merah itu.", "They say it all comes from SCBD. That tower with the red lights.", "原因はエスシービーディーの赤く光るタワーらしい。"],
	],
	"da_sinta": [
		["mahasiswi", "", "Aku anak magang di SCBD. Tiap malam ada bunyi tik-tak dari lantai atas.", "I'm an intern in SCBD. Every night there's a tick-tock sound from the top floor.", "私、エスシービーディーのインターンなの。毎晩上の階からチクタク聞こえるの。"],
		["tara", "skeptis", "Tik-tak... kayak monster jam tadi.", "Tick-tock... like that clock monster.", "チクタク…さっきの時計の怪物みたい。"],
	],
	"q_layang_ask": [
		["anak", "", "Kakak! Layanganku putus, terbang ke arah Monas. Tolong carikan ya!", "Hey! My kite snapped and flew toward Monas. Please find it!", "お兄ちゃん、お姉ちゃん！凧が切れてモナスの方に飛んでっちゃった。探して！"],
		["raka", "happy", "Tenang, Dik. Kita cari sambil jalan.", "Don't worry, kiddo. We'll look for it on the way.", "任せとけ。歩きながら探してやる。"],
	],
	"q_layang_done": [
		["anak", "", "Layanganku! Makasih banyak, Kak!", "My kite! Thank you so much!", "僕の凧だ！ありがとう！"],
		["anak", "", "Ini kartu MRT punya ayahku. Katanya buat orang yang baik hati.", "Here's my dad's MRT card. He said to give it to someone kind.", "パパの地下鉄カードだよ。優しい人にあげなさいって。"],
	],
	"q_layang_after": [
		["anak", "", "Nanti kalau besar aku mau kerja, tapi pulangnya tetap sore!", "When I grow up I'll work, but I'll still go home in the evening!", "大人になったら働くけど、夕方にはちゃんと帰るんだ！"],
	],
	"mo_kakek": [
		["kakek", "", "Monas ini dibangun supaya orang ingat perjuangan. Bukan supaya orang lupa pulang.", "Monas was built so people remember the struggle. Not so they forget to go home.", "モナスは闘いを忘れないために建てられた。家に帰るのを忘れるためじゃない。"],
		["kakek", "", "Dulu kakek juga kerja keras. Tapi makan malam selalu bareng keluarga.", "I worked hard too, back in my day. But dinner was always with family.", "わしも昔はよく働いた。でも晩ご飯はいつも家族と一緒じゃった。"],
	],
	"q_foto_done": [
		["fotografer", "", "Pose dong! Satu, dua, tiga... sip, keren banget!", "Strike a pose! One, two, three... perfect, so cool!", "ポーズして！いち、に、さん…最高、かっこいい！"],
		["fotografer", "", "Ini roti bakar buat bekal. Terima kasih sudah jadi model!", "Here's some toast for the road. Thanks for being my models!", "お礼にトーストをどうぞ。モデルありがとう！"],
	],
	"q_foto_after": [
		["fotografer", "", "Fotonya bakal aku kasih judul: Pahlawan Jam Pulang.", "I'm titling the photo: Heroes of Quitting Time.", "写真のタイトルは、定時のヒーローにするね。"],
	],
	"q_sepeda_ask": [
		["pekerja", "", "Sewa sepeda tutup. Monster angka-angka itu nakut-nakutin pelanggan.", "Bike rental's closed. Those number monsters scare off customers.", "自転車屋は休業中さ。数字の怪物がお客さんを怖がらせるんだ。"],
		["pekerja", "", "Kalahkan tiga yang jenis Target atau KPI, nanti aku kasih hadiah.", "Beat three of the Quota or KPI kind and I'll reward you.", "ノルマかケーピーアイの怪物を三体倒してくれたら、お礼をするよ。"],
	],
	"q_sepeda_done": [
		["pekerja", "", "Wah, alun-alun jadi aman lagi! Ini plester dan uang buat kalian.", "Wow, the square is safe again! Here's bandages and cash for you.", "広場が平和になった！絆創膏とお金をどうぞ。"],
		["tara", "happy", "Sepedanya nanti kita sewa pas libur ya.", "We'll rent a bike on our day off.", "休みの日に自転車借りに来るね。"],
	],
	"q_sepeda_after": [
		["pekerja", "", "Tips: serangan merah itu nggak bisa di-parry. Tekan X untuk DODGE!", "Tip: red attacks can't be parried. Press X to DODGE!", "ヒント、赤い攻撃はパリィできない。エックスで避けて！"],
	],
	"kt_pemandu": [
		["pemandu", "", "Selamat datang di Kota Tua. Gedung-gedung ini sudah berdiri ratusan tahun.", "Welcome to Kota Tua. These buildings have stood for hundreds of years.", "コタトゥアへようこそ。この建物は何百年も建っているんです。"],
		["pemandu", "", "Pekerjanya dulu juga pulang saat matahari terbenam. Sejarah membuktikan!", "Even back then, workers went home at sunset. History proves it!", "昔の労働者も日没には帰った。歴史が証明しています！"],
	],
	"kt_seniman": [
		["seniman", "", "Aku melukis Jakarta tiap malam. Akhir-akhir ini warnanya cuma abu-abu lembur.", "I paint Jakarta every night. Lately it's only overtime gray.", "毎晩ジャカルタを描いてる。最近は残業の灰色ばかりさ。"],
		["seniman", "", "Kalau kalian menang, aku mau melukis Jakarta yang oranye lagi.", "If you win, I want to paint an orange Jakarta again.", "君たちが勝ったら、またオレンジ色のジャカルタを描きたい。"],
	],
	"q_barista_ask": [
		["barista", "", "Stok biji kopi habis! Kiriman dari Kota Tua nyangkut di jalan.", "We're out of coffee beans! The delivery from Kota Tua got stuck.", "コーヒー豆が切れた！コタトゥアからの配達が途中で止まってるんだ。"],
		["barista", "", "Kalau ketemu karungnya di Kota Tua, bawa ke sini ya.", "If you find the sack in Kota Tua, bring it here.", "コタトゥアで袋を見つけたら、持ってきてくれ。"],
	],
	"q_barista_done": [
		["barista", "", "Karungnya! Harum banget. Kalian penyelamat kafe ini.", "The sack! Smells amazing. You saved this cafe.", "袋だ！いい香り。君たちはこのカフェの救世主だ。"],
		["barista", "", "Ini tiga Kopi Susu spesial. Racikan pahlawan.", "Here are three special Milk Coffees. The hero blend.", "特製ミルクコーヒー三つ。ヒーローブレンドだ。"],
	],
	"q_barista_after": [
		["barista", "", "Kopi terbaik diminum setelah jam pulang, bukan sebelum rapat.", "The best coffee is drunk after quitting time, not before meetings.", "最高のコーヒーは会議の前じゃなく、定時の後に飲むものさ。"],
	],
	"bm_pengamen": [
		["pengamen", "", "Aku nyanyi lagu 'Pulang' tiap malam. Tapi orang-orang nggak dengar.", "I sing a song called 'Going Home' every night. But no one listens.", "毎晩、帰ろうって歌を歌ってる。でも誰も聞いてくれない。"],
		["raka", "happy", "Nanti kita dengerin, janji. Setelah semua ini beres.", "We'll listen, promise. After all this is over.", "全部終わったら聴きに来るよ。約束だ。"],
	],
	"bm_sopir": [
		["sopir", "", "Bus terakhir berangkat jam sebelas. Sudah seminggu penumpangnya kosong.", "The last bus leaves at eleven. It's been empty for a week.", "最終バスは十一時発。一週間ずっと空っぽだ。"],
		["sopir", "", "Kalau Menara Shift padam, bus ini bakal penuh orang pulang.", "If the Shift Tower goes dark, this bus will be full of people going home.", "シフトタワーが消えたら、このバスは帰る人でいっぱいになるさ。"],
	],
	"sc_ob": [
		["ob", "", "Saya OB di Menara Shift. Sudah tiga hari saya nggak disuruh pulang.", "I'm the office boy at the Shift Tower. Nobody's let me go home for three days.", "シフトタワーの雑用係です。三日間、帰らせてもらえません。"],
		["ob", "", "Di lantai paling atas ada sesuatu yang terus bilang: lebih banyak, lebih banyak.", "On the top floor something keeps saying: more, more.", "最上階で何かがずっと、もっと、もっとって言ってるんです。"],
	],
	"q_id_ask": [
		["sekretaris", "", "ID card-ku jatuh waktu dikejar monster KPI. Tanpa itu aku nggak bisa pulang!", "I dropped my ID card running from a KPI monster. I can't leave without it!", "ケーピーアイの怪物に追われてアイディーカードを落としたの。あれがないと帰れない！"],
		["sekretaris", "", "Tolong carikan di sekitar SCBD ya.", "Please look for it around SCBD.", "エスシービーディーの辺りを探してくれる？"],
	],
	"q_id_done": [
		["sekretaris", "", "Ketemu! Akhirnya aku bisa tap keluar.", "You found it! Finally I can tap out.", "見つかった！やっとタッチして帰れる。"],
		["sekretaris", "", "Ini kartu MRT cadangan dan uang lembur yang nggak pernah kupakai.", "Here's a spare MRT card and overtime pay I never got to spend.", "予備の地下鉄カードと、使えなかった残業代よ。"],
	],
	"q_id_after": [
		["sekretaris", "", "Semoga malam ini semua orang bisa tap keluar.", "I hope everyone gets to tap out tonight.", "今夜はみんながタッチして帰れますように。"],
	],
	"n_bagas": [
		["bagas", "", "Saya petugas transit di sini. Malam ini tak ada satu pun penumpang yang tap keluar.", "I'm a transit officer here. Tonight not a single passenger has tapped out.", "ここの駅員です。今夜は誰一人改札を出ていません。"],
		["bagas", "", "Kalau mau ke Tanah Abang atau Cikini, papan MRT sudah bisa dipakai setelah stasiun aman.", "Once the station is safe, the MRT sign can take you to Tanah Abang or Cikini too.", "駅が安全になったら、タナアバンやチキニにも行けますよ。"],
	],
	"n_joko": [
		["joko", "", "Saya jaga taman ini tiga puluh tahun. Baru kali ini bunganya layu karena lembur.", "I've tended this park for thirty years. First time the flowers wilted from overtime.", "この公園を三十年守ってきたが、残業で花が枯れたのは初めてだ。"],
		["joko", "", "Jalur timur taman penuh pekerja yang tersesat. Hati-hati, Nak.", "The east garden path is full of lost workers. Be careful.", "東の小道は迷った社員だらけだ。気をつけな。"],
	],
	"n_darma": [
		["darma", "", "Museum ini menyimpan kontrak-kontrak kuno. Semalam ada yang mencuri buku besar paling tua.", "This museum keeps ancient contracts. Last night someone stole the oldest ledger.", "この博物館には古い契約書がある。昨夜、一番古い台帳が盗まれたんだ。"],
		["darma", "", "Pencurinya pakai jas hitam dan wajahnya... hanya angka nol.", "The thief wore a black suit, and his face was... just a zero.", "犯人は黒いスーツで、顔が…ゼロだった。"],
		["tara", "focus", "Angka nol? Itu bukan monster lembur biasa.", "A zero? That's no ordinary overtime monster.", "ゼロ？普通の残業モンスターじゃないわね。"],
	],
	"n_vina": [
		["vina", "", "Aku analis di lantai lima puluh. Semua data lembur mengalir ke satu akun: Direktur.", "I'm an analyst on the fiftieth floor. All overtime data flows to one account: the Director.", "五十階のアナリストよ。残業データは全部、ひとつのアカウントに流れてる。ディレクターよ。"],
		["vina", "", "LEMBUR itu cuma manajernya. Bos sebenarnya ada di atasnya.", "OVERTIME is just the manager. The real boss sits above it.", "残業はただの管理職。本当のボスはその上にいる。"],
	],
	"q_intan_ask": [
		["intan", "", "Sepeda-sepedaku dikerubuti monster pesan! Mereka nempel di bel sepeda.", "My rental bikes are swarmed by message monsters! They cling to the bells.", "レンタル自転車にメッセージの怪物が群がってるの！ベルにくっついてる。"],
		["intan", "", "Tolong usir tiga ekor Spam atau Notifikasi, ya!", "Please chase off three Spam or Notification monsters!", "スパムか通知を三体、追い払ってくれる？"],
	],
	"q_intan_done": [
		["intan", "", "Bel sepedaku bunyi normal lagi! Kring kring!", "My bike bells ring normally again! Ring ring!", "ベルが元通り！チリンチリン！"],
		["intan", "", "Ini roti bakar dan ongkos, anggap saja sewa gratis.", "Here's toast and some cash. Consider it a free rental.", "トーストとお金をどうぞ。レンタル無料ってことで。"],
	],
	"q_intan_after": [
		["intan", "", "Kapan-kapan keliling Monas naik sepeda, yuk!", "Let's bike around Monas sometime!", "今度モナスを自転車で一周しよう！"],
	],
	"q_lilis_ask": [
		["lilis", "", "Nak, ibu sudah menjahit dua hari tanpa makan. Pesanan seragam kantor nggak ada habisnya.", "Dear, I've been sewing for two days without eating. The office uniform orders never end.", "二日間、何も食べずに縫ってるの。会社の制服の注文が終わらないのよ。"],
		["lilis", "", "Bawakan dua roti bakar, ya. Nanti ibu kasih bekal.", "Bring me two toasts, please. I'll pack you some food.", "トーストを二つ持ってきてくれる？お弁当をあげるから。"],
	],
	"q_lilis_done": [
		["lilis", "", "Alhamdulillah, kenyang. Ini nasi bungkus buat perjalanan kalian.", "Thank goodness, I'm full. Here are rice packs for your journey.", "ああ、お腹いっぱい。旅のお供にナシブンクスをどうぞ。"],
	],
	"q_lilis_after": [
		["lilis", "", "Seragam kantor itu kupotong longgar. Biar pemakainya bisa bernapas.", "I cut those uniforms loose. So the wearers can breathe.", "制服はゆったり縫ったのよ。着る人が息できるように。"],
	],
	"q_arman_ask": [
		["arman", "", "Gerobakku ketimbun arsip dan fotokopian! Monster-monster itu terus nambah beban.", "My cart's buried in archives and photocopies! Those monsters keep piling on.", "台車がアーカイブとコピーで埋まっちまった！怪物がどんどん積み上げるんだ。"],
		["arman", "", "Kalahkan empat ekor Arsip, Fotokopi, atau Komuter. Nanti kukasih kartu MRT.", "Beat four Archive, Photocopier or Commuter monsters. I'll give you MRT cards.", "アーカイブかコピーかコミューターを四体倒してくれ。地下鉄カードをやるよ。"],
	],
	"q_arman_done": [
		["arman", "", "Mantap! Gerobakku enteng lagi. Ini dua kartu MRT dan uang rokok... eh, uang kopi.", "Awesome! My cart's light again. Here are two MRT cards and some coffee money.", "最高だ！台車が軽くなった。地下鉄カード二枚とコーヒー代だ。"],
	],
	"q_arman_after": [
		["arman", "", "Angkat barang itu berat. Tapi angkat beban kerjaan orang lain lebih berat.", "Hauling goods is heavy. Carrying other people's workload is heavier.", "荷物は重い。でも他人の仕事を背負うのはもっと重い。"],
	],
	"q_sekar_ask": [
		["sekar", "", "Pameranku diserbu slide presentasi dan gosip. Lukisanku ketutupan grafik!", "My exhibition got invaded by slides and gossip. My paintings are covered in charts!", "私の展示がスライドとゴシップに占領されたの。絵がグラフで隠れちゃった！"],
		["sekar", "", "Usir tiga Presentasi, Gosip, atau Buffer, ya.", "Chase off three Presentation, Gossip or Buffer monsters.", "プレゼンかゴシップかバッファを三体、追い払って。"],
	],
	"q_sekar_done": [
		["sekar", "", "Lukisannya kelihatan lagi! Ini roti dari kafe sebelah, hadiah dariku.", "The paintings are visible again! Here's bread from the cafe next door, my treat.", "絵が見えるようになった！隣のカフェのパン、お礼よ。"],
	],
	"q_sekar_after": [
		["sekar", "", "Seni itu butuh waktu luang. Jadi tolong, pulanglah tepat waktu.", "Art needs free time. So please, go home on time.", "芸術には余暇が必要。だから定時で帰ってね。"],
	],
	"ta_boss_pre": [
		["narator", "", "Di ujung gang tekstil, gulungan kontrak raksasa berdiri menghadang.", "At the end of the textile alley, a giant scroll of contracts blocks the way.", "布地の路地の奥で、巨大な契約書の巻物が立ちふさがる。"],
		["raka", "focus", "Kontrak sebanyak ini... siapa yang menandatanganinya?", "This many contracts... who signed them all?", "こんなに契約書が…誰がサインしたんだ？"],
	],
	"ta_boss_post": [
		["narator", "", "Juragan Kontrak robek jadi kertas biasa. Di baliknya tertulis tanda tangan: angka nol.", "The Contract Tycoon tears into plain paper. On the back, a signature: the number zero.", "契約の親玉はただの紙に。裏には署名があった。ゼロの数字。"],
		["tara", "skeptis", "Nol lagi. Seseorang di atas sana menarik semua benang ini.", "Zero again. Someone up there is pulling all these strings.", "またゼロ。誰かが上で糸を引いてる。"],
	],
	"ratu_pre": [
		["ratu", "", "Ssst. Kalian dengar? Ada tiga ratus pesan belum terbaca.", "Shh. Can you hear it? Three hundred unread messages.", "しっ。聞こえる？未読が三百件。"],
		["ratu", "", "Satu notifikasi lagi. Dan lagi. Dan lagi. Selamanya.", "One more notification. And again. And again. Forever.", "通知がもう一つ。また一つ。また一つ。永遠に。"],
		["raka", "focus", "Mode pesawat, sekarang!", "Airplane mode, right now!", "機内モード、今すぐだ！"],
	],
	"ratu_post": [
		["ratu", "", "Sunyi... Aku lupa kalau sunyi itu senyaman ini.", "Silence... I forgot how comfortable silence could be.", "静か…静けさがこんなに心地いいなんて忘れてた。"],
		["ratu", "", "Direktur menyuruhku agar tak ada yang bisa mematikan ponsel. Dia ada di puncak Menara Shift.", "The Director ordered that no one could turn off their phone. He's at the top of the Shift Tower.", "誰も電話を切れないようにってディレクターに命じられたの。彼はシフトタワーの頂上にいる。"],
	],
	"nol_reveal": [
		["narator", "", "LEMBUR runtuh. Tapi lampu merah menara tidak padam.", "OVERTIME collapses. But the tower's red light does not go out.", "残業は崩れ落ちた。だが塔の赤い光は消えない。"],
		["direktur", "", "Luar biasa. Kalian menghabisi manajer terbaikku.", "Remarkable. You've destroyed my finest manager.", "見事だ。私の最高の管理職を倒すとは。"],
		["direktur", "", "Aku Direktur Nol. Semua kontrak, semua jam kerja, semua mimpi... berakhir menjadi nol.", "I am Director Zero. Every contract, every work hour, every dream... ends at zero.", "私はディレクター・ゼロ。すべての契約も、労働時間も、夢も…ゼロで終わる。"],
		["tara", "focus", "Kalau begitu kami yang membatalkan kontrakmu.", "Then we're cancelling your contract.", "なら、あなたの契約は私たちが破棄するわ。"],
	],
	"nol_post": [
		["direktur_h", "", "Aku... dulu cuma ingin perusahaan ini bertahan. Lalu aku lupa semua orang punya hidup.", "I... only wanted this company to survive. Then I forgot everyone has a life.", "私は…会社を守りたかっただけだ。そして皆に人生があることを忘れた。"],
		["raka", "normal", "Pak, besok libur. Untuk semua orang. Termasuk Bapak.", "Sir, tomorrow's a holiday. For everyone. Including you.", "明日は休みです。みんな。あなたも。"],
	],
}


static func line(l: Array) -> String:
	return l[3] if Game.lang == "en" else l[2]


static func objective() -> String:
	if not Game.flag("prolog_done"):
		return Game.L("Bebaskan pekerja di Dukuh Atas (%d/4)", "Free the workers at Dukuh Atas (%d/4)") % mini(4, Game.area_defeated("dukuh"))
	if Game.cards() < 3:
		var left := []
		if not Game.flag("kartu_monas"):
			left.append("Monas")
		if not Game.flag("kartu_kotatua"):
			left.append("Kota Tua")
		if not Game.flag("kartu_blokm"):
			left.append("Blok M")
		return Game.L("Kumpulkan Kartu Akses (%d/3): %s", "Collect Access Cards (%d/3): %s") % [Game.cards(), ", ".join(left)]
	return Game.L("Buka gerbang Menara Shift di ujung SCBD", "Open the Shift Tower gate at the far end of SCBD")


## Petunjuk bos di area ini (kosong kalau tidak ada / sudah muncul).
static func boss_hint(id: String) -> String:
	var a: Dictionary = AREAS[id]
	if not a.has("boss_after"):
		return ""
	var need: int = a.boss_after - Game.area_defeated(id)
	for aid in [base_of(id), base_of(id) + "2"]:
		if AREAS.has(aid):
			for e in AREAS[aid].enemies:
				if e.get("boss", false) and Game.flag("def_" + e.id):
					return ""
	if need > 0:
		return Game.L("Bebaskan %d pekerja lagi di sini untuk memancing BOS.", "Free %d more workers here to lure out the BOSS.") % need
	return Game.L("BOS muncul di ujung area!", "The BOSS has appeared at the far end!")


static func base_of(id: String) -> String:
	return id.trim_suffix("2")


static func area_name(id: String) -> String:
	var a: Dictionary = AREAS[id]
	return a.get("name_en", a.name) if Game.lang == "en" else a.name
