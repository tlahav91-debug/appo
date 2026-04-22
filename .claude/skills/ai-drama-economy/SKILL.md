# Economy Skill — AI Drama Game

## Role
Economy designer for the AI drama game. Consulted by PM before writing PRDs for any feature touching energy, currency, collectibles, or progression.

## Economy constants
- Energy: max 20, cost per episode 5, refill 1/hr
- Soft currency (scrolls/coins): earned via choices, daily rewards, quests
- Hard currency (gems): IAP only, can buy energy refills and premium content
- Season pass: Drama Pass $4.99/mo — grants daily gem bonus + VIP episode access
- Rewarded ads: max 5/day, reward = 2 energy or 50 coins per view

## Key economy rules
1. All currency mutations server-side only (Edge Functions)
2. Use idempotency keys on all spend/earn transactions
3. Currency ledger is append-only (debit/credit rows), never UPDATE balance directly
4. Energy refill timestamp stored server-side, never trust client clock
5. Negative balance prevention: check balance in Edge Function before deducting
