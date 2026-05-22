# Turn 18 — discuss Flutter cert (choice #2)

**User prompt:**
> yes

**Assistant response:**
Moved to Choice #2 (Flutter client cert). Recommended **A. Shared
bundled cert** — JWT already does per-user identity, so mTLS only
needs to act as a network filter; per-device enrollment (B) is a lot
of code (CSR generation in Flutter, an `/enroll` endpoint, secure
on-device key storage, bootstrap-token UX) for marginal extra
security. Noted the honest argument for B: willingness to brick a
single stolen phone without rotating everyone.

## Latest prompt

> yes
