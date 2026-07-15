extends RefCounted
class_name LoreBank

## Tag-matched barangay feed. Specific combos beat vague fallbacks via `prio`.


static func entries() -> Array:
	return [
		# --- Day 1 / opening ---
		{"need": ["day1", "vendor_proper"], "prio": 12, "bucket": "barangay", "line": "Tita Rosa: 'Uy %s, bago pa lang cart mo ah.'" % _name()},
		{"need": ["day1", "cash_rich"], "prio": 14, "bucket": "money", "line": "Day 1 pa lang, mukhang may pondo. Sus."},
		{"need": ["day1", "stall_fishball"], "prio": 11, "bucket": "stall", "line": "First customer: 'Pabili fishball.' Pressure agad."},
		{"need": ["day1", "app_unpaid"], "prio": 16, "bucket": "online", "line": "Tindahan App: 'Subscribe muna pre, libre ang chismis wala.'"},
		{"need": ["day1", "no_sauce"], "prio": 13, "bucket": "stall", "line": "Neighbor: 'Walang sauce?' Tradition starts today."},

		# --- Early grind ---
		{"need": ["day2_3", "cash_tight"], "prio": 18, "bucket": "family", "line": "Asawa: 'Kumusta first week?' You: 'Existing lang.'"},
		{"need": ["day2_3", "paid_all"], "prio": 20, "bucket": "family", "line": "Bills paid on time. Rare flex, pre."},
		{"need": ["day2_3", "bill_gap"], "prio": 17, "bucket": "money", "line": "Utilities: 'Notice of friendly panic.'"},
		{"need": ["day2_3", "stall_empty"], "prio": 19, "bucket": "stall", "line": "Cart open, stock closed. Bold business model."},
		{"need": ["day2_3", "kikiam_unlocked"], "prio": 21, "bucket": "stall", "line": "Kikiam unlocked. Barangay tier list updating."},
		{"need": ["day2_3", "earn_hot"], "prio": 22, "bucket": "stall", "line": "Stall day was fire. Bills: 'We also exist.'"},

		# --- Mid run ---
		{"need": ["day4_7", "cash_broke"], "prio": 28, "bucket": "money", "line": "Wallet on diet. Cart on hope."},
		{"need": ["day4_7", "rent_late1"], "prio": 30, "bucket": "family", "line": "Landlord text: 'Pre, ano na?' Seen-zoned ka na."},
		{"need": ["day4_7", "loan_active"], "prio": 32, "bucket": "money", "line": "JuanAngat: 'Utang is a lifestyle, not a phase.'"},
		{"need": ["day4_7", "up_palamig"], "prio": 26, "bucket": "stall", "line": "Palamig upgrade live. Main product still stress."},
		{"need": ["day4_7", "night_theft"], "prio": 31, "bucket": "barangay", "line": "Tanod log: 'Nanakawan ulit. CCTV: wala pa rin.'"},
		{"need": ["day4_7", "anting_owned"], "prio": 27, "bucket": "stall", "line": "Anting bought. Luck stat unchanged. Tragic."},
		{"need": ["day4_7", "skipped_food"], "prio": 29, "bucket": "family", "line": "Family rice: postponed. Vendor meal: fishball scraps."},

		# --- Late survival ---
		{"need": ["day8_14", "cash_broke"], "prio": 40, "bucket": "barangay", "line": "Day %d na. Hero ka na, pre. Medyo broke hero." % _day()},
		{"need": ["day8_14", "peak_crash"], "prio": 42, "bucket": "money", "line": "Peak money feels like a different lifetime."},
		{"need": ["day8_14", "theft_repeat"], "prio": 44, "bucket": "barangay", "line": "Barangay group chat: 'Si %s na naman?' " % _name()},
		{"need": ["day8_14", "paid_all", "cash_tight"], "prio": 41, "bucket": "money", "line": "Bills cleared. Wallet gasping for air."},
		{"need": ["day8_14", "up_stacked"], "prio": 38, "bucket": "stall", "line": "Cart upgraded. Bank account downgraded."},
		{"need": ["day15_plus"], "prio": 50, "bucket": "barangay", "line": "Local legend status: Day %d vendor. Respect." % _day()},

		# --- Money tiers ---
		{"need": ["cash_rich", "loan_none"], "prio": 24, "bucket": "money", "line": "Cash okay, utang wala. Suspiciously stable."},
		{"need": ["cash_rich", "loan_active"], "prio": 35, "bucket": "money", "line": "May pera ka pa habang may utang. Accountant ka ba?"},
		{"need": ["cash_broke", "loan_active"], "prio": 48, "bucket": "money", "line": "JuanAngat: 'Payment received. Spirit crushed.'"},
		{"need": ["cash_broke", "loan_none"], "prio": 33, "bucket": "money", "line": "Broke pero dignified. No loan... yet."},
		{"need": ["cash_tight", "skipped_rent"], "prio": 36, "bucket": "family", "line": "Rent skipped. Sleep quality: negotiable."},
		{"need": ["cash_tight", "app_unpaid"], "prio": 34, "bucket": "online", "line": "Can't pay app sub. Irony noted."},

		# --- Rent / homeless ---
		{"need": ["rent_late2", "cash_broke"], "prio": 55, "bucket": "family", "line": "Two nights no rent. Kids think it's camping."},
		{"need": ["rent_late2", "loan_active"], "prio": 58, "bucket": "money", "line": "Utang + late rent. JuanAngat and landlord same mood."},
		{"need": ["homeless"], "prio": 90, "bucket": "family", "line": "Three nights. Barangay hall knows your name now."},
		{"need": ["rent_ok", "cash_broke"], "prio": 25, "bucket": "family", "line": "Rent paid. Everything else: imagination."},
		{"need": ["skipped_rent", "cash_ok"], "prio": 37, "bucket": "money", "line": "May pera ka pero rent hindi. Priorities debate."},

		# --- Family / sick ---
		{"need": ["fam_sick", "medicine_needed"], "prio": 52, "bucket": "family", "line": "Anak may lagnat. Medicine tab staring contest."},
		{"need": ["fam_sick", "medicine_paid"], "prio": 46, "bucket": "family", "line": "Medicine bought. Parent XP +1, pesos -300."},
		{"need": ["fam_sick", "skipped_food"], "prio": 54, "bucket": "family", "line": "Sick kid, unpaid food bill. Double whammy pre."},
		{"need": ["fam_healthy", "risk_high"], "prio": 30, "bucket": "family", "line": "Healthy pa pero risk meter red na. Babala."},
		{"need": ["fam_healthy", "paid_all"], "prio": 20, "bucket": "family", "line": "Family stable. For now. *knock wood*"},
		{"need": ["night_sick"], "prio": 45, "bucket": "family", "line": "Last night: lagnat. Today: pharmacy speedrun."},
		{"need": ["risk_high", "bill_gap"], "prio": 43, "bucket": "family", "line": "Skipped bills piling up. Immune system taking notes."},

		# --- JuanAngat / loan ---
		{"need": ["loan_active", "rent_late1"], "prio": 57, "bucket": "money", "line": "JuanAngat DM: 'Pre, rent mo raw delayed rin.'"},
		{"need": ["loan_active", "cash_rich"], "prio": 39, "bucket": "money", "line": "May utang ka pero mukhang okay pa. Teach me."},
		{"need": ["loan_none", "cash_broke"], "prio": 31, "bucket": "money", "line": "Misc tab: JuanAngat waving. Tempting."},
		{"need": ["loan_active", "earn_hot"], "prio": 40, "bucket": "money", "line": "Good stall day. Loan collector still faster."},

		# --- Sbatter ---
		{"need": ["sbatter_name", "sbatter_loss"], "prio": 62, "bucket": "online", "line": "Sbatter renamed you. Brand identity: deleted."},
		{"need": ["sbatter_name", "sbatter_win"], "prio": 65, "bucket": "online", "line": "Sbatter W! Name mo pa rin nawala though."},
		{"need": ["sbatter_name", "cash_broke"], "prio": 60, "bucket": "online", "line": "Sbatter User ka na. Promos: 52. Pera: 0."},
		{"need": ["sbatter_loss", "loan_active"], "prio": 63, "bucket": "online", "line": "Lost name sa Sbatter, may utang pa. Combo."},
		{"need": ["vendor_proper", "cash_tight"], "prio": 15, "bucket": "online", "line": "Sbatter promo: %d%% win chance. Drops every night." % _sbatter_odds()},
		{"need": ["sbatter_name", "day8_14"], "prio": 61, "bucket": "online", "line": "Day %d: still Sbatter User %s energy." % [_day(), _short_name()]},

		# --- Anting / weather misc ---
		{"need": ["anting_owned", "night_theft"], "prio": 56, "bucket": "stall", "line": "Anting-anting busy raw. Nanakawan pa rin."},
		{"need": ["anting_owned", "night_luck"], "prio": 47, "bucket": "stall", "line": "Anting worked? May naiwan sa mesa. Science unclear."},
		{"need": ["anting_owned", "cash_broke"], "prio": 49, "bucket": "money", "line": "Charm bought. Wallet still haunted."},
		{"need": ["weather_app", "rain_day"], "prio": 44, "bucket": "online", "line": "Weather app called ulan. Spawn rate agrees."},
		{"need": ["weather_app", "awasan_day"], "prio": 43, "bucket": "online", "line": "Awasan alert. Palamig line already forming."},
		{"need": ["weather_app", "cash_broke"], "prio": 41, "bucket": "online", "line": "Paid weather app. Can't pay water bill. Nice."},
		{"need": ["anting_owned", "weather_app"], "prio": 45, "bucket": "online", "line": "Misc tab maxed out. Gameplay buffs: debatable."},

		# --- Stock / sauce / stall ---
		{"need": ["no_sauce", "stall_fishball"], "prio": 22, "bucket": "stall", "line": "Customer: 'Sauce?' You: strong eye contact, 'Wala.'"},
		{"need": ["has_sauce", "stall_loaded"], "prio": 23, "bucket": "stall", "line": "Fully stocked. Cart feels like a real tindahan."},
		{"need": ["stall_empty", "cash_ok"], "prio": 26, "bucket": "stall", "line": "May pera, walang stock. Window shopping cart."},
		{"need": ["stall_kikiam", "cash_tight"], "prio": 28, "bucket": "stall", "line": "Kikiam restocked. Margin crying quietly."},
		{"need": ["stall_kwek2", "day4_7"], "prio": 27, "bucket": "stall", "line": "Kwek-kwek on menu. Orange ball economy."},
		{"need": ["stall_fishball", "up_none"], "prio": 16, "bucket": "stall", "line": "Fishball lang upgrade mo sa buhay. Same pre."},
		{"need": ["no_sauce", "earn_cold"], "prio": 29, "bucket": "stall", "line": "No sauce, slow sales. Connected dots."},
		{"need": ["stall_loaded", "earn_hot"], "prio": 33, "bucket": "stall", "line": "Stock out, customers out. Nakaka-proud."},
		{"need": ["stall_kikiam", "stall_kwek2"], "prio": 30, "bucket": "stall", "line": "Premium menu unlocked. Premium bills too."},

		# --- Upgrades ---
		{"need": ["up_palamig", "cash_broke"], "prio": 46, "bucket": "stall", "line": "Palamig machine humming. Wallet silent."},
		{"need": ["up_palamig", "skipped_water"], "prio": 48, "bucket": "family", "line": "Palamig sold out. Bahay tubig: unpaid. Ironic."},
		{"need": ["up_stacked", "cash_tight"], "prio": 42, "bucket": "stall", "line": "Cart pimped out. Personal life: base model."},
		{"need": ["up_none", "day8_14"], "prio": 35, "bucket": "stall", "line": "Day %d, zero upgrades. Pure vanilla grind." % _day()},
		{"need": ["up_palamig", "earn_hot"], "prio": 36, "bucket": "stall", "line": "Palamig carried the stall today. MVP tubig."},

		# --- Night events ---
		{"need": ["night_theft", "cash_broke"], "prio": 53, "bucket": "barangay", "line": "Nanakawan + broke. Barangay bingo card complete."},
		{"need": ["night_theft", "anting_owned"], "prio": 55, "bucket": "barangay", "line": "Charm failed. Tanod suggests 'bigger charm.'"},
		{"need": ["night_luck", "cash_broke"], "prio": 38, "bucket": "money", "line": "Small windfall. Bills said 'cute, we'll wait.'"},
		{"need": ["night_quiet", "cash_tight"], "prio": 18, "bucket": "barangay", "line": "Quiet night. Suspiciously peaceful."},
		{"need": ["night_theft", "theft_repeat"], "prio": 59, "bucket": "barangay", "line": "Nanakawan streak. Cart needs bodyguard."},
		{"need": ["night_luck", "loan_active"], "prio": 40, "bucket": "money", "line": "Found barya. JuanAngat found you faster."},

		# --- Weather days ---
		{"need": ["rain_day", "stall_empty"], "prio": 34, "bucket": "stall", "line": "Ulan + walang stock. Perfect storm, pre."},
		{"need": ["rain_day", "earn_hot"], "prio": 32, "bucket": "stall", "line": "Ulan pero maraming bumili. Wet hero."},
		{"need": ["awasan_day", "cash_broke"], "prio": 31, "bucket": "barangay", "line": "Awasan heat. Ice candy dreams, fishball reality."},
		{"need": ["rain_day", "weather_app"], "prio": 46, "bucket": "online", "line": "App said rain. Foot traffic slowed. Worth the ₱50."},

		# --- Tindahan app ---
		{"need": ["app_unpaid", "cash_ok"], "prio": 33, "bucket": "online", "line": "May pera ka, di ka nag-subscribe. Rebel vendor."},
		{"need": ["app_paid", "cash_broke"], "prio": 36, "bucket": "online", "line": "App paid. Shop open. Wallet closed."},
		{"need": ["app_unpaid", "stall_loaded"], "prio": 40, "bucket": "online", "line": "Stock ready, app locked. Paywall meta."},

		# --- Earnings ---
		{"need": ["earn_hot", "cash_tight"], "prio": 34, "bucket": "stall", "line": "Good day sa stall. Bills still winning the war."},
		{"need": ["earn_cold", "bill_gap"], "prio": 28, "bucket": "stall", "line": "Slow sales + unpaid bills. Classic Tuesday."},
		{"need": ["earn_hot", "peak_crash"], "prio": 45, "bucket": "money", "line": "Today was okay. Peak money feels like fiction."},

		# --- Combos (specific) ---
		{"need": ["skipped_food", "skipped_water"], "prio": 50, "bucket": "family", "line": "Food at tubig unpaid. Survival mode: hard."},
		{"need": ["skipped_elec", "fam_sick"], "prio": 51, "bucket": "family", "line": "No kuryente, may sakit. Fan dreams only."},
		{"need": ["loan_active", "fam_sick", "cash_broke"], "prio": 68, "bucket": "family", "line": "Utang, lagnat, zero pesos. Boss fight."},
		{"need": ["sbatter_name", "anting_owned"], "prio": 58, "bucket": "online", "line": "Sbatter name + anting. Luck build unclear."},
		{"need": ["vendor_proper", "day15_plus"], "prio": 55, "bucket": "barangay", "line": "%s still standing Day %d. Respect, pre." % [_name(), _day()]},
		{"need": ["rent_ok", "loan_none", "paid_all"], "prio": 30, "bucket": "family", "line": "Clean sheet tonight. Rare vendor W."},
		{"need": ["stall_kikiam", "no_sauce"], "prio": 32, "bucket": "stall", "line": "Kikiam without sauce. Brave or chaotic."},
		{"need": ["up_palamig", "stall_kikiam", "has_sauce"], "prio": 35, "bucket": "stall", "line": "Full menu energy. Margin still sus."},
		{"need": ["cash_rich", "day8_14"], "prio": 38, "bucket": "money", "line": "Day %d pa may laman wallet. Teach us." % _day()},
		{"need": ["homeless", "loan_active"], "prio": 88, "bucket": "family", "line": "Walang bahay, may utang pa. Final arc."},

		{"need": ["day1", "loan_active"], "prio": 70, "bucket": "money", "line": "Day 1 utang na agad. Speedrun any%."},
		{"need": ["medicine_needed", "loan_active"], "prio": 64, "bucket": "family", "line": "Gamot o utang? JuanAngat offers both trauma."},
		{"need": ["stall_empty", "rent_late2"], "prio": 52, "bucket": "family", "line": "Walang stock, delikado rent. Double jeopardy."},
		{"need": ["earn_hot", "skipped_rent"], "prio": 39, "bucket": "money", "line": "Magandang benta, hindi pa rent. Classic vendor."},
		{"need": ["kikiam_unlocked", "cash_broke"], "prio": 37, "bucket": "stall", "line": "Kikiam available na. Budget: hindi pa."},
		{"need": ["risk_low", "paid_all"], "prio": 19, "bucket": "family", "line": "Bills clean, risk low. Enjoy habang rare."},
		{"need": ["sbatter_win", "cash_ok"], "prio": 52, "bucket": "online", "line": "Sbatter panalo. Temporary lang ang saya, pre."},
		{"need": ["night_quiet", "paid_all"], "prio": 21, "bucket": "barangay", "line": "Tahimik na gabi. Tanod nag-vacation mode."},

		# --- Fallbacks (low prio, wide tags) ---
		{"need": ["vendor_proper"], "prio": 5, "bucket": "barangay", "line": "Tito Jun: 'Oy %s, buhay pa cart mo?'" % _name()},
		{"need": ["cash_tight"], "prio": 4, "bucket": "money", "line": "Peso by peso. Barangay economy."},
		{"need": ["bill_gap"], "prio": 4, "bucket": "money", "line": "May bill pa na pending. Story of the vendor."},
		{"need": ["stall_fishball"], "prio": 3, "bucket": "stall", "line": "Fishball sizzle. Background noise ng kalye."},
		{"need": ["fam_healthy"], "prio": 3, "bucket": "family", "line": "Family okay pa. Sana all."},
		{"need": ["day4_7"], "prio": 2, "bucket": "barangay", "line": "Midweek vendor grind. Tuloy lang."},
		{"need": ["day1"], "prio": 1, "bucket": "barangay", "line": "New cart smell. Hope and cooking oil."},
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
