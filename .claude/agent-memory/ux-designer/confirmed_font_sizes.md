---
confirmed: 2026-04-17
screen: character_select
---

# Confirmed font sizes — character select

User verified these sizes as "这个大小不错" after multiple iterations of "too small" feedback.

| Element | Size |
|---------|------|
| Card name label | 28 |
| Card tagline label | 19 |
| Detail panel name | 38 |
| Detail panel tagline | 24 |
| Detail panel description | 22 |

**Baseline ratios** (derive new screens from these):
- Card name : detail name = 28:38 ≈ 1:1.36
- Tagline ≈ name × 0.68
- Description ≈ tagline × 0.92

**Do NOT revert to Godot defaults (14-16px)** — user explicitly called out font size being too small repeatedly.
