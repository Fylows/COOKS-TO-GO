extends RefCounted
## Game-over epitaphs and survival endings. Bad = how you died. Good = how you held on.

const BAD_ENDING_ORDER := [
	"barangay_notice",
	"underpass_clinic",
	"sbatter_sidewalk",
	"botika_closed",
	"juanangat_no_refill",
	"tubig_at_lagnat",
	"palamig_over_paracetamol",
	"tindahan_app_timeout",
	"app_and_utang",
	"grand_opening_closed",
]

const GOOD_ENDING_ORDER := [
	"isang_linggo",
	"walang_utang",
	"kompletong_cart",
	"may_bubong",
	"pamilya_muna",
]

const ENDING_ORDER := BAD_ENDING_ORDER + GOOD_ENDING_ORDER

const ENDINGS := {
	"barangay_notice": {
		"kind": "bad",
		"title": "Barangay Notice No. 88",
		"body": "Three nights late on rent and the padlock went on without a hearing. Your slippers stayed by the door like evidence. The barangay court became the bedroom. People sleep under basketball rings in this country when wages stop matching leases.",
		"detail": "Evicted after unpaid rent streak.",
	},
	"underpass_clinic": {
		"kind": "bad",
		"title": "Outpatient Underpass",
		"body": "No house, and the health center still asked for a queue number you did not have. Free care means wait until the stock arrives, then wait until the doctor arrives, then go home with advice and no bottle. Fever does not respect office hours.",
		"detail": "Homeless and still sick.",
	},
	"sbatter_sidewalk": {
		"kind": "bad",
		"title": "Sbatter User 48291",
		"body": "You pawned your legal name for a bet the ads called \"diskarte.\" The lease went with it. Online betting runs on neon and payday; eviction still runs on paper and padlocks. Your family now shares a sidewalk with a username.",
		"detail": "Evicted after betting your name on Sbatter.",
	},
	"botika_closed": {
		"kind": "bad",
		"title": "Botika Closed, Puso Open",
		"body": "Biogesic sat under glass at a price that laughed at your till. The 24-hour drugstore closed at ten. PhilHealth paperwork wants a job with payslips; street carts get cash and a fever that does not wait for reimbursement.",
		"detail": "Could not afford medicine. No loan left.",
	},
	"juanangat_no_refill": {
		"kind": "bad",
		"title": "5-6 First, Lunas Later",
		"body": "JuanAngat already owned tomorrow's earnings. The interest ate the medicine money before you reached the botika. Informal credit fills the gaps banks will not touch, then bills you for the privilege of staying alive one more shift.",
		"detail": "Sick, broke, and still paying JuanAngat.",
	},
	"tubig_at_lagnat": {
		"kind": "bad",
		"title": "Tubig at Lagnat",
		"body": "You cut the water bill and the ulam so the cart could open. Survival math in a small business: feed the stall first, feed the people later. Later arrived as fever, and the cart could not write a prescription.",
		"detail": "Skipped food/water, then could not buy medicine.",
	},
	"palamig_over_paracetamol": {
		"kind": "bad",
		"title": "Upgrade Path",
		"body": "You bought the palamig gear because growth looks like stainless steel on a cart. Home looked like a thermometer you could not afford to bring down. Hustle culture posts the upgrade. It rarely posts the unpaid Biogesic.",
		"detail": "Bought palamig gear, then missed medicine money.",
	},
	"tindahan_app_timeout": {
		"kind": "bad",
		"title": "Platform Rent",
		"body": "Tindahan App charged a daily fee to keep the stall \"visible.\" Miss it and the tarp stays down. On the sidewalk the QR code is just another landlord with better branding.",
		"detail": "Could not pay the Tindahan App fee.",
	},
	"app_and_utang": {
		"kind": "bad",
		"title": "Two Landlords",
		"body": "JuanAngat wanted his cut. The app wanted Subscribe. Between the scooter interest and the platform fee, a fishball day could not cover both. Debt and digital rent stack faster than a cart shift.",
		"detail": "App unpaid while JuanAngat loan is still open.",
	},
	"grand_opening_closed": {
		"kind": "bad",
		"title": "Grand Opening: Closed",
		"body": "Day one, before the first fishball hit oil, a phone screen asked for rent on an app. Formalizing a sidewalk stall often starts with a fee. Your opening day was a paywall.",
		"detail": "Softlocked on the first morning.",
	},
	"isang_linggo": {
		"kind": "good",
		"title": "Isang Linggo",
		"body": "Seven market days. The tarp went up every morning. Bills argued, the cart answered. In a country that treats sidewalk work like a temporary phase, a full week of openings is already a kind of lease.",
		"detail": "Survived 7 market days.",
	},
	"walang_utang": {
		"kind": "good",
		"title": "Walang Utang",
		"body": "JuanAngat's scooter passed without stopping. The till had room to breathe. Paying a 5-6 man back does not make you rich. It makes the next fever yours to manage, not his.",
		"detail": "Cleared the loan with cash still in pocket.",
	},
	"kompletong_cart": {
		"kind": "good",
		"title": "Kompletong Cart",
		"body": "Palamig jug, bigger bin, faster cook, slower burn. The cart finally looked like the Facebook photos other vendors post. Hardware does not guarantee tomorrow. It does buy you a better shot at today's line.",
		"detail": "Owned every stall upgrade.",
	},
	"may_bubong": {
		"kind": "good",
		"title": "May Bubong Pa",
		"body": "Ten nights and the padlock never learned your name. Rent hurt. Sleep still happened indoors. Keeping a roof while running a cart is quiet politics : the kind that never trends.",
		"detail": "Reached day 10 without ever going homeless.",
	},
	"pamilya_muna": {
		"kind": "good",
		"title": "Pamilya Muna",
		"body": "Kuryente, tubig, ulam : paid before the shiny upgrades. The feed still joked. The thermometer stayed bored. Choosing the house over the hustle photo is how some stalls last past the first viral week.",
		"detail": "Seven days of paid food, water, and electricity.",
	},
}


static func count() -> int:
	return ENDING_ORDER.size()


static func bad_count() -> int:
	return BAD_ENDING_ORDER.size()


static func good_count() -> int:
	return GOOD_ENDING_ORDER.size()


static func get_ending(id: String) -> Dictionary:
	if id in ENDINGS:
		return ENDINGS[id]
	return ENDINGS["tindahan_app_timeout"]


static func is_good(id: String) -> bool:
	return str(get_ending(id).get("kind", "bad")) == "good"


static func title_for(id: String) -> String:
	return str(get_ending(id).get("title", "Wala na"))


static func body_for(id: String) -> String:
	return str(get_ending(id).get("body", ""))


static func detail_for(id: String) -> String:
	return str(get_ending(id).get("detail", ""))


static func hint_for(id: String) -> String:
	return str(HINTS.get(id, detail_for(id)))


const HINTS := {
	"barangay_notice": "Skip rent until the locksmith visits.",
	"underpass_clinic": "Lose the house while someone still has lagnat.",
	"sbatter_sidewalk": "Bet your real name on Sbatter, then miss rent.",
	"botika_closed": "Get sick with an empty till and no loan left.",
	"juanangat_no_refill": "Stay sick while JuanAngat still owns you.",
	"tubig_at_lagnat": "Skip food or water, then fail to buy medicine.",
	"palamig_over_paracetamol": "Buy palamig gear, then miss medicine money.",
	"tindahan_app_timeout": "Let the Tindahan App fee go unpaid.",
	"app_and_utang": "Owe JuanAngat and still miss the app fee.",
	"grand_opening_closed": "Softlock on morning one before the first sale.",
	"isang_linggo": "Open the stall for seven market days.",
	"walang_utang": "Clear the loan, keep Php 1500+, stay housed and healthy.",
	"kompletong_cart": "Own every cart upgrade.",
	"may_bubong": "Reach day 10 without ever going homeless.",
	"pamilya_muna": "Pay food, water, and power seven nights in a row.",
}


static func index_of(id: String) -> int:
	var i := ENDING_ORDER.find(id)
	return i if i >= 0 else 0
