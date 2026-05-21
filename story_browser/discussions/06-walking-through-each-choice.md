# Discussion 06 — Walking through each choice, picking, and a script upgrade

**Span:** "let's talk about #1" through commit of the random-password
upgrade to `gen-pki.sh`.

## Goal

After the four reference guides existed, the user wanted to actually
talk through each choice with vLearn2's specific constraints — and
land on a decision per dimension.

## Conversation shape

For each of the four choices: short recommendation + main trade-off in
2–3 sentences, user confirms ("ok" / "yes" / "go on please"), move to
the next. This is the
[CLAUDE.md exploratory-question pattern](../../../CLAUDE.md) — small
back-and-forth instead of upfront alignment, redirectable at each
step.

## The picks

| Choice | Pick | Reason |
|---|---|---|
| 1. CA strategy | **A. Single CA** | one ops person, single CA key to guard, single `ca.crt` to ship; B's role-separation has no payoff at this scale. |
| 2. Flutter cert | **A. Shared bundled** | JWT already handles user identity; mTLS is a network filter; per-device enrollment is a lot of code for marginal benefit. |
| 3. Admin cert | **A. Per-admin** | user input: 3 admins, ~1 turnover/year. At that scale, per-admin distribution is trivial and the TLS-layer audit is a free benefit. |
| 4. PBE | **A. Legacy SHA1-3DES** | universal import, no real downside if you do password discipline right; B silently breaks `openssl pkcs12 -in` on the RHEL7 host (OpenSSL 1.0.2k can't read AES PBE). |

## Side-quest in choice #4 — random password default

When confirming choice #4, surfaced that the **real** security knob
isn't PBE algorithm, it's password strength. Offered to upgrade
`gen-pki.sh` to default to a random per-cert password (not the cert
name). User: "ok".

### What changed in `gen-pki.sh`

The `client` subcommand now:

1. Generates `PW=$(openssl rand -base64 18)` per invocation.
2. Uses `-passout "pass:${PW}"` instead of the cert name.
3. Writes the password to a sibling `pki/client/<name>.password`
   file (mode 600) so it isn't lost if stdout scrolls.
4. Prints both the password to stdout and a reminder to "send the
   .p12 and the password on separate channels."

### Verified locally

In a throwaway `test-pki-pwd/` dir: regenerated `admin-john`,
confirmed `openssl pkcs12 -in admin-john.p12 -passin
file:admin-john.password` unlocks the bundle cleanly.

### Choice #4 guide updated

The "Password handling" section in
`vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md` was rewritten to
describe the new default and document the override path
(`CLIENT_PASSWORD=hunter2 ./gen-pki.sh client admin-john`) for
scripted re-use.

## Decisions locked in

```
gen-pki.sh defaults now implement A across all four choices:
  1. Single CA
  2. Shared bundled Flutter cert
  3. Per-admin browser cert
  4. Legacy PBE + random per-cert password (sent on separate channel)
```

## Notes from the conversation

- Pre-existing markdown-lint warnings (MD036 emphasis-as-heading on
  `**Pros**`/`**Cons**`, MD060 table-pipe spacing) surfaced during the
  edit. Intentionally not fixed — they apply uniformly across all
  four choice guides and a one-file lint pass would create
  inconsistency.
- IDE warnings from a hook are surfaced to the assistant but don't
  block edits; the assistant has discretion on scope.

## Artifacts

- `gen-pki.sh` — updated `client` subcommand (random password, sibling
  `.password` file).
- `vlearn2-mtls-choice-4-pkcs12-pbe-strategy.md` — updated password
  handling section.

## Where to look for the raw conversation

`story_claude/260521_140033_random-p12-password-default.md`.
