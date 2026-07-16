# COOKS-TO-GO UI

Street stall game. Chrome should feel like a night market phone, not a SaaS dashboard.

## Tokens

- **Radius:** 4px everywhere (panels, buttons, chips). Exception: circular notification pips on scaled app icons.
- **Gold** `Color(1.0, 0.86, 0.42)`: money only (wallet HUD, prices, Day Over peso line).
- **Cool ink** `Color(0.48–0.55, 0.62–0.68, 0.82–0.88)`: feed, gallery, Day Over shell, tooltips, stock strips.
- **Blockers / fades:** tinted ink `Color(0.06–0.08, 0.04–0.05, 0.07–0.1)`, never pure black.
- **Font:** `Shared/Font/04B_03__.TTF` (pixel). One face is fine; do not add a second display font for chrome.
- **Pixel readability:** Never ship labels under 16px. Captions 16, body 20, titles 24+. Always pair small chrome with a dark outline (`PixelText` helper). 04B mush without outline is a bug.

## Motion

- Ease: `TRANS_CUBIC` + `EASE_OUT` only. No `TRANS_BACK`.
- One hero `UiMotion.pop_in` per screen. Secondary chrome uses `fade_in`.
- Hover: ~6% scale, not bounce. Focus/tap must match hover for interactive chrome.

## Copy

- Taglish where the player lives (lore, Day Over, weather).
- Section titles sentence case (`Restock`, `Barangay`, `Stock`, `Wallet`), not ALL-CAPS eyebrows.

## Stall HUD

- **Wallet** (gold border) top-right only money chrome.
- **Stock** cool-ink strip under the day bar (middot line), not a twin inventory card.
- Day bar: timer is the type hero; Pause / End Day / Restart are cool ink buttons.
- Intro: cart scales in; chrome fades only.
