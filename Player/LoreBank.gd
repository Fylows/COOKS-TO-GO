extends RefCounted
class_name LoreBank

## Tag-matched barangay feed. Specific combos beat vague fallbacks via `prio`.
## Voice: kapitbahay chismis, Taglish, short, witty. Not LinkedIn. Not Discord.


static func entries() -> Array:
	return [
		# --- Day 1 / opening ---
		{"need": ["day1", "vendor_proper"], "prio": 12, "bucket": "barangay", "line": "Tita Rosa: 'Uy %s, bago pa lang yang cart mo. Ingat sa unang araw ha.'" % _name()},
		{"need": ["day1", "cash_rich"], "prio": 14, "bucket": "money", "line": "Day 1 pa lang may laman na wallet. Sino ka ba, pre?"},
		{"need": ["day1", "stall_fishball"], "prio": 11, "bucket": "stall", "line": "Unang customer: 'Pabili fishball.' Kabog agad dibdib."},
		{"need": ["day1", "app_unpaid"], "prio": 16, "bucket": "online", "line": "Tindahan App: 'Subscribe muna. Libre ang chismis, hindi ang orders.'"},
		{"need": ["day1", "no_sauce"], "prio": 13, "bucket": "stall", "line": "Kapitbahay: 'Walang sauce?' Tradition starts today, teh."},

		# --- Early grind ---
		{"need": ["day2_3", "cash_tight"], "prio": 18, "bucket": "family", "line": "Asawa: 'Kumusta?' Ikaw: 'Buhay. Yun na yun.'"},
		{"need": ["day2_3", "paid_all"], "prio": 20, "bucket": "family", "line": "Bayad lahat ng bills. Rare yan, pre. Screenshot mo."},
		{"need": ["day2_3", "bill_gap"], "prio": 17, "bucket": "money", "line": "Meralco / Maynilad energy: 'Friendly reminder' pero feeling threat."},
		{"need": ["day2_3", "stall_empty"], "prio": 19, "bucket": "stall", "line": "Bukas ang cart, wala namang stock. Concept store ba toh?"},
		{"need": ["day2_3", "kikiam_unlocked"], "prio": 21, "bucket": "stall", "line": "May kikiam na. Barangay tier list, updated."},
		{"need": ["day2_3", "earn_hot"], "prio": 22, "bucket": "stall", "line": "Ang init ng benta kanina. Bills: 'Kami din nandito.'"},

		# --- Mid run ---
		{"need": ["day4_7", "cash_broke"], "prio": 28, "bucket": "money", "line": "Wallet on diet. Cart on prayers."},
		{"need": ["day4_7", "rent_late1"], "prio": 30, "bucket": "family", "line": "Landlord: 'Pre, ano na rent?' Seen. Typing... tapos stop."},
		{"need": ["day4_7", "loan_active"], "prio": 32, "bucket": "money", "line": "JuanAngat: 'Utang is a lifestyle, hindi phase.'"},
		{"need": ["day4_7", "up_palamig"], "prio": 26, "bucket": "stall", "line": "May palamig machine ka na. Main product mo: stress pa rin."},
		{"need": ["day4_7", "night_theft"], "prio": 31, "bucket": "barangay", "line": "Tanod log: 'Nanakawan ulit. CCTV? Wala pa rin, sir.'"},
		{"need": ["day4_7", "anting_owned"], "prio": 27, "bucket": "stall", "line": "Bumili ka ng anting. Suwerte? Hindi pa kita."},
		{"need": ["day4_7", "skipped_food"], "prio": 29, "bucket": "family", "line": "Kanin sa bahay: later. Dinner mo: fishball scraps."},

		# --- Late survival ---
		{"need": ["day8_14", "cash_broke"], "prio": 40, "bucket": "barangay", "line": "Day %d ka na. Hero, pero broke hero." % _day()},
		{"need": ["day8_14", "peak_crash"], "prio": 42, "bucket": "money", "line": "Yung peak money mo? Feeling previous life na."},
		{"need": ["day8_14", "theft_repeat"], "prio": 44, "bucket": "barangay", "line": "Barangay GC: 'Si %s na naman? Kawawa naman / sus.'" % _name()},
		{"need": ["day8_14", "paid_all", "cash_tight"], "prio": 41, "bucket": "money", "line": "Bayad bills. Wallet: hingal hingal."},
		{"need": ["day8_14", "up_stacked"], "prio": 38, "bucket": "stall", "line": "Cart upgraded. Bank account? Downgraded."},
		{"need": ["day15_plus"], "prio": 50, "bucket": "barangay", "line": "Day %d vendor. Local legend ka na, pre. Respect." % _day()},

		# --- Money tiers ---
		{"need": ["cash_rich", "loan_none"], "prio": 24, "bucket": "money", "line": "May pera, walang utang. Suspiciously okay ka."},
		{"need": ["cash_rich", "loan_active"], "prio": 35, "bucket": "money", "line": "May pera ka pa may utang. Accountant ka ba?"},
		{"need": ["cash_broke", "loan_active"], "prio": 48, "bucket": "money", "line": "JuanAngat: 'Payment received.' Ikaw: spirit crushed."},
		{"need": ["cash_broke", "loan_none"], "prio": 33, "bucket": "money", "line": "Broke pero dignified. Walang utang... for now."},
		{"need": ["cash_tight", "skipped_rent"], "prio": 36, "bucket": "family", "line": "Hindi nabayaran rent. Sleep quality: negotiable."},
		{"need": ["cash_tight", "app_unpaid"], "prio": 34, "bucket": "online", "line": "Di afford mag-subscribe. Irony noted, app."},

		# --- Rent / homeless ---
		{"need": ["rent_late2", "cash_broke"], "prio": 55, "bucket": "family", "line": "Dalawang gabi no rent. Kids: 'Camping ba toh, Ma?'"},
		{"need": ["rent_late2", "loan_active"], "prio": 58, "bucket": "money", "line": "Late rent + utang. Landlord at JuanAngat: same mood."},
		{"need": ["homeless"], "prio": 90, "bucket": "family", "line": "Tatlong gabi. Alam na ng barangay hall pangalan mo."},
		{"need": ["rent_ok", "cash_broke"], "prio": 25, "bucket": "family", "line": "Rent bayad. Ibang bayarin: imagination."},
		{"need": ["skipped_rent", "cash_ok"], "prio": 37, "bucket": "money", "line": "May pera ka, rent hindi. Priorities debate, pre."},

		# --- Family / sick ---
		{"need": ["fam_sick", "medicine_needed"], "prio": 52, "bucket": "family", "line": "Anak may lagnat. Medicine tab: staring contest."},
		{"need": ["fam_sick", "medicine_paid"], "prio": 46, "bucket": "family", "line": "Bumili ng gamot. Parent points +1. Pesos −300."},
		{"need": ["fam_sick", "skipped_food"], "prio": 54, "bucket": "family", "line": "May sakit, hindi pa nabayaran food. Grabe araw mo."},
		{"need": ["fam_healthy", "risk_high"], "prio": 30, "bucket": "family", "line": "Healthy pa sila, pero risk meter red na. Babala."},
		{"need": ["fam_healthy", "paid_all"], "prio": 20, "bucket": "family", "line": "Okay pa ang pamilya. For now. *katok sa kahoy*"},
		{"need": ["night_sick"], "prio": 45, "bucket": "family", "line": "Kagabi: lagnat. Ngayon: pharmacy speedrun."},
		{"need": ["risk_high", "bill_gap"], "prio": 43, "bucket": "family", "line": "Pinagsama-sama bills. Immune system taking notes."},

		# --- JuanAngat / loan ---
		{"need": ["loan_active", "rent_late1"], "prio": 57, "bucket": "money", "line": "JuanAngat DM: 'Pre, delayed din daw rent mo.' Chismoso."},
		{"need": ["loan_active", "cash_rich"], "prio": 39, "bucket": "money", "line": "May utang ka pero mukhang okay ka. Turuan mo kami."},
		{"need": ["loan_none", "cash_broke"], "prio": 31, "bucket": "money", "line": "JuanAngat waving sa Misc. Tempting, teh."},
		{"need": ["loan_active", "earn_hot"], "prio": 40, "bucket": "money", "line": "Maganda benta. Collector ng utang: mas mabilis pa."},

		# --- Sbatter ---
		{"need": ["sbatter_name", "sbatter_loss"], "prio": 62, "bucket": "online", "line": "Sbatter took your name. Brand identity: deleted."},
		{"need": ["sbatter_name", "sbatter_win"], "prio": 65, "bucket": "online", "line": "Sbatter W! Name mo? Wala pa rin. Classic."},
		{"need": ["sbatter_name", "cash_broke"], "prio": 60, "bucket": "online", "line": "Sbatter User ka na. Promos: 52. Pera: 0."},
		{"need": ["sbatter_loss", "loan_active"], "prio": 63, "bucket": "online", "line": "Natalo sa Sbatter, may utang pa. Combo meal."},
		{"need": ["vendor_proper", "cash_tight"], "prio": 15, "bucket": "online", "line": "Sbatter: %d%% win chance. Gabi-gabi yang temptation." % _sbatter_odds()},
		{"need": ["sbatter_name", "day8_14"], "prio": 61, "bucket": "online", "line": "Day %d ka pa, Sbatter User %s energy pa rin." % [_day(), _short_name()]},

		# --- Anting / weather misc ---
		{"need": ["anting_owned", "night_theft"], "prio": 56, "bucket": "stall", "line": "Anting busy raw. Nanakawan ka pa rin. Hmm."},
		{"need": ["anting_owned", "night_luck"], "prio": 47, "bucket": "stall", "line": "May naiwan sa mesa. Anting? O kindness ng kalye?"},
		{"need": ["anting_owned", "cash_broke"], "prio": 49, "bucket": "money", "line": "Charm bought. Wallet still haunted."},
		{"need": ["weather_app", "rain_day"], "prio": 44, "bucket": "online", "line": "Weather app: ulan. Customers: konti. Worth it ba?"},
		{"need": ["weather_app", "awasan_day"], "prio": 43, "bucket": "online", "line": "Weather app: init. Palamig line forming na sa isip."},
		{"need": ["weather_app", "cash_broke"], "prio": 41, "bucket": "online", "line": "Bayad weather app. Tubig sa bahay? Hindi. Nice."},
		{"need": ["anting_owned", "weather_app"], "prio": 45, "bucket": "online", "line": "Maxed Misc tab. Actual luck: debatable, pre."},

		# --- Stock / sauce / stall ---
		{"need": ["no_sauce", "stall_fishball"], "prio": 22, "bucket": "stall", "line": "Customer: 'Sauce?' Ikaw: strong eye contact. 'Wala.'"},
		{"need": ["has_sauce", "stall_loaded"], "prio": 23, "bucket": "stall", "line": "Puno stock, may sauce. Feeling real tindahan."},
		{"need": ["stall_empty", "cash_ok"], "prio": 26, "bucket": "stall", "line": "May pera, walang stock. Window shopping cart."},
		{"need": ["stall_kikiam", "cash_tight"], "prio": 28, "bucket": "stall", "line": "Restock kikiam. Margin: tahimik na umiiyak."},
		{"need": ["stall_kwek2", "day4_7"], "prio": 27, "bucket": "stall", "line": "May kwek-kwek na. Orange ball economy, activated."},
		{"need": ["stall_fishball", "up_none"], "prio": 16, "bucket": "stall", "line": "Fishball lang upgrade mo sa buhay. Same, pre."},
		{"need": ["no_sauce", "earn_cold"], "prio": 29, "bucket": "stall", "line": "Walang sauce, mabagal benta. Connected dots."},
		{"need": ["stall_loaded", "earn_hot"], "prio": 33, "bucket": "stall", "line": "Stock out, customers out. Nakaka-proud, teh."},
		{"need": ["stall_kikiam", "stall_kwek2"], "prio": 30, "bucket": "stall", "line": "Premium menu unlocked. Premium bills din."},

		# --- Upgrades ---
		{"need": ["up_palamig", "cash_broke"], "prio": 46, "bucket": "stall", "line": "Palamig humming. Wallet: silent treatment."},
		{"need": ["up_palamig", "skipped_water"], "prio": 48, "bucket": "family", "line": "Palamig sold out. Tubig sa bahay: unpaid. Ironic."},
		{"need": ["up_stacked", "cash_tight"], "prio": 42, "bucket": "stall", "line": "Cart pimped out. Personal life: base model."},
		{"need": ["up_none", "day8_14"], "prio": 35, "bucket": "stall", "line": "Day %d, zero upgrades. Pure vanilla grind." % _day()},
		{"need": ["up_palamig", "earn_hot"], "prio": 36, "bucket": "stall", "line": "Palamig carried the stall. Tubig MVP, pre."},

		# --- Night events ---
		{"need": ["night_theft", "cash_broke"], "prio": 53, "bucket": "barangay", "line": "Nanakawan + broke. Barangay bingo, complete."},
		{"need": ["night_theft", "anting_owned"], "prio": 55, "bucket": "barangay", "line": "Charm failed. Tanod: 'Bumili ka ng mas malaki.'"},
		{"need": ["night_luck", "cash_broke"], "prio": 38, "bucket": "money", "line": "May naiwan. Bills: 'Cute. Hintay kami.'"},
		{"need": ["night_quiet", "cash_tight"], "prio": 18, "bucket": "barangay", "line": "Tahimik kagabi. Suspiciously peaceful."},
		{"need": ["night_theft", "theft_repeat"], "prio": 59, "bucket": "barangay", "line": "Nanakawan streak. Kailangan ng bodyguard yang cart."},
		{"need": ["night_luck", "loan_active"], "prio": 40, "bucket": "money", "line": "Nakita mo barya. JuanAngat naka-spot mo agad."},

		# --- Weather days ---
		{"need": ["rain_day", "stall_empty"], "prio": 34, "bucket": "stall", "line": "Ulan + walang stock. Perfect storm, pre."},
		{"need": ["rain_day", "earn_hot"], "prio": 32, "bucket": "stall", "line": "Ulan pero maraming bumili. Wet hero ka."},
		{"need": ["awasan_day", "cash_broke"], "prio": 31, "bucket": "barangay", "line": "Init na init. Ice candy dreams, fishball reality."},
		{"need": ["rain_day", "weather_app"], "prio": 46, "bucket": "online", "line": "App: ulan. Traffic: mabagal. Worth the ₱50 ba?"},

		# --- Tindahan app ---
		{"need": ["app_unpaid", "cash_ok"], "prio": 33, "bucket": "online", "line": "May pera ka, di ka nag-subscribe. Rebel vendor."},
		{"need": ["app_paid", "cash_broke"], "prio": 36, "bucket": "online", "line": "App bayad. Shop open. Wallet closed."},
		{"need": ["app_unpaid", "stall_loaded"], "prio": 40, "bucket": "online", "line": "Stock ready, app locked. Paywall meta, teh."},

		# --- Earnings ---
		{"need": ["earn_hot", "cash_tight"], "prio": 34, "bucket": "stall", "line": "Maganda araw sa stall. Bills winning pa rin."},
		{"need": ["earn_cold", "bill_gap"], "prio": 28, "bucket": "stall", "line": "Mabagal benta + unpaid bills. Classic Martes."},
		{"need": ["earn_hot", "peak_crash"], "prio": 45, "bucket": "money", "line": "Okay ngayon. Peak money? Feeling fiction."},

		# --- Combos (specific) ---
		{"need": ["skipped_food", "skipped_water"], "prio": 50, "bucket": "family", "line": "Food at tubig unpaid. Survival mode: hard."},
		{"need": ["skipped_elec", "fam_sick"], "prio": 51, "bucket": "family", "line": "Walang kuryente, may sakit. Fan dreams only."},
		{"need": ["loan_active", "fam_sick", "cash_broke"], "prio": 68, "bucket": "family", "line": "Utang, lagnat, zero pesos. Grabe araw n'yo."},
		{"need": ["sbatter_name", "anting_owned"], "prio": 58, "bucket": "online", "line": "Sbatter name + anting. Luck build? Unclear."},
		{"need": ["vendor_proper", "day15_plus"], "prio": 55, "bucket": "barangay", "line": "%s pa rin standing Day %d. Respect, pre." % [_name(), _day()]},
		{"need": ["rent_ok", "loan_none", "paid_all"], "prio": 30, "bucket": "family", "line": "Clean sheet tonight. Rare vendor W."},
		{"need": ["stall_kikiam", "no_sauce"], "prio": 32, "bucket": "stall", "line": "Kikiam walang sauce. Brave o chaotic?"},
		{"need": ["up_palamig", "stall_kikiam", "has_sauce"], "prio": 35, "bucket": "stall", "line": "Full menu energy. Margin? Sus pa rin."},
		{"need": ["cash_rich", "day8_14"], "prio": 38, "bucket": "money", "line": "Day %d pa may laman wallet. Turuan mo kami." % _day()},
		{"need": ["homeless", "loan_active"], "prio": 88, "bucket": "family", "line": "Walang bahay, may utang pa. Final arc toh."},

		{"need": ["day1", "loan_active"], "prio": 70, "bucket": "money", "line": "Day 1, utang na agad. Grabe ka mag-start."},
		{"need": ["medicine_needed", "loan_active"], "prio": 64, "bucket": "family", "line": "Gamot o utang? JuanAngat offers both trauma."},
		{"need": ["stall_empty", "rent_late2"], "prio": 52, "bucket": "family", "line": "Walang stock, delikado rent. Double jeopardy."},
		{"need": ["earn_hot", "skipped_rent"], "prio": 39, "bucket": "money", "line": "Magandang benta, hindi pa rent. Classic vendor."},
		{"need": ["kikiam_unlocked", "cash_broke"], "prio": 37, "bucket": "stall", "line": "Available na ang kikiam. Budget? Hindi pa."},
		{"need": ["risk_low", "paid_all"], "prio": 19, "bucket": "family", "line": "Bills clean, risk low. Enjoy habang rare."},
		{"need": ["sbatter_win", "cash_ok"], "prio": 52, "bucket": "online", "line": "Panalo sa Sbatter. Temporary lang ang saya, pre."},
		{"need": ["night_quiet", "paid_all"], "prio": 21, "bucket": "barangay", "line": "Tahimik na gabi. Tanod: vacation mode."},

		# --- Fallbacks (low prio, wide tags) ---
		{"need": ["vendor_proper"], "prio": 5, "bucket": "barangay", "line": "Tito Jun: 'Oy %s, buhay pa cart mo?'" % _name()},
		{"need": ["cash_tight"], "prio": 4, "bucket": "money", "line": "Peso by peso. Barangay economy."},
		{"need": ["bill_gap"], "prio": 4, "bucket": "money", "line": "May pending pa. Story of every vendor."},
		{"need": ["stall_fishball"], "prio": 3, "bucket": "stall", "line": "Fishball sizzle. Background noise ng kalye."},
		{"need": ["fam_healthy"], "prio": 3, "bucket": "family", "line": "Okay pa ang pamilya. Sana all."},
		{"need": ["day4_7"], "prio": 2, "bucket": "barangay", "line": "Midweek grind. Tuloy lang, pre."},
		{"need": ["day1"], "prio": 1, "bucket": "barangay", "line": "Amoy bagong cart. Hope at cooking oil."},
	]


static func _name() -> String:
	var n := PlayerStats.player_name.strip_edges()
	if n.is_empty():
		return "pre"
	if n.begins_with("Sbatter User"):
		return "pre"
	return n.split(" ")[0]


static func _short_name() -> String:
	var n := PlayerStats.player_name
	if n.length() > 12:
		return n.left(12) + "…"
	return n


static func _day() -> int:
	return PlayerStats.daysPassed + 1


static func _sbatter_odds() -> int:
	return SbatterController.get_win_chance_percent()
