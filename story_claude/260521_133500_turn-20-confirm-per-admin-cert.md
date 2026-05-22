# Turn 20 — confirm per-admin cert

**User prompt:**
> 3 admins, change one time a year

**Assistant response:**
With 3 admins and ~1 turnover/year, confirmed **A. Per-admin cert** —
distribution is trivial at that scale and the TLS-layer audit comes
for free. Noted that when an admin leaves you just stop re-issuing
their cert (re-issuing the CA is overkill for a single departure).
Asked whether to move on to Choice #4.

## Latest prompt

> 3 admins,  change one time a year
