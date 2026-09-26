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
	"scbd": {"name": "SCBD · Menara Shift", "name_en": "SCBD · Shift Tower", "bg": W + "bg_scbd.jpg", "music": "bgm_boss",
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
		["narator", "", "PETA MRT terbuka! Pergi ke papan MRT di kiri layar untuk pindah area. Urutan bebas.", "MRT MAP unlocked! Go to the MRT sign on the left to travel. Any order you like.", "地下鉄マップが解放された！好きな順番で旅立とう。"],
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
}


static func line(l: Array) -> String:
	return l[3] if Game.lang == "en" else l[2]


static func objective() -> String:
	if not Game.flag("prolog_done"):
		return Game.L("Bebaskan pekerja yang dirasuki di Dukuh Atas", "Free the possessed workers at Dukuh Atas")
	if Game.cards() < 3:
		var left := []
		if not Game.flag("kartu_monas"):
			left.append("Monas")
		if not Game.flag("kartu_kotatua"):
			left.append("Kota Tua")
		if not Game.flag("kartu_blokm"):
			left.append("Blok M")
		return Game.L("Kumpulkan Kartu Akses (%d/3): %s", "Collect Access Cards (%d/3): %s") % [Game.cards(), ", ".join(left)]
	return Game.L("Buka gerbang Menara Shift di SCBD", "Open the Shift Tower gate in SCBD")


static func area_name(id: String) -> String:
	var a: Dictionary = AREAS[id]
	return a.get("name_en", a.name) if Game.lang == "en" else a.name
