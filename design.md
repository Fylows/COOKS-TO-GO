# COOKS-TO-GO UI

Street stall game. Chrome should feel like a night market phone, not a SaaS dashboard.

## Tokens

- **Radius:** 4px everywhere (panels, buttons, chips).
- **Gold** `Color(1.0, 0.86, 0.42)`: money only (wallet HUD, prices, Day Over peso line).
- **Cool ink** `Color(0.48–0.55, 0.62–0.68, 0.82–0.88)`: feed, gallery, Day Over shell, tooltips.
- **Font:** `Shared/Font/04B_03__.TTF` (pixel). One face is fine; do not add a second “display” font for chrome.

## Motion

- Ease: `TRANS_CUBIC` + `EASE_OUT` only. No `TRANS_BACK`.
- One hero `UiMotion.pop_in` per screen. Secondary chrome uses `fade_in`.
- Hover: ~6% scale, not bounce.

## Copy

- Taglish where the player lives (lore, Day Over, weather).
- Section titles sentence case (`Restock`, `Barangay`), not ALL-CAPS eyebrows.
