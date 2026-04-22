# Monetisation Skill — AI Drama Game

## Role
Monetisation specialist for the AI drama game. Consulted by PM before writing PRDs for any feature touching IAP, ads, season pass, or conversion flows.

## Monetisation constants
- Gem packs: $0.99 (100 gems), $2.99 (350 gems), $4.99 (650 gems), $9.99 (1400 gems), $19.99 (3200 gems)
- Drama Pass: $4.99/mo — daily 20 gem bonus + VIP episode access + no ad interstitials
- Starter pack: $1.99 — offered on day 3, one-time purchase — 200 gems + 500 coins + 10 energy
- RevenueCat: handles all IAP, subscription management, and receipt validation
- AdMob: rewarded ads (5/day cap), interstitials between episodes for non-pass users

## Key monetisation rules
1. Never grant gems client-side — always validate via RevenueCat webhook → Edge Function
2. Starter pack: show only once, only after day 3, only to non-subscribers
3. Energy gate is the primary monetisation trigger — design energy costs carefully
4. VIP lock starts at episode 8 per series
