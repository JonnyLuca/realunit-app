# Referral programme and promo code

Implementation spec for this repository and `realunit.app`. The DFX API is
the decision authority. This app is a rendering layer.

## API contract (`api.dfx.swiss` / `dev.api.dfx.swiss`)

Authenticated routes use the existing Bearer session.

### `GET /v1/realunit/referral/summary`

```json
{
  "eligible": true,
  "termsAccepted": true,
  "minHolding": 70,
  "openCount": 1,
  "creditedCount": 2,
  "realuSum": 40,
  "chfSum": 512.4
}
```

`eligible` is the dashboard/settings gate. The app must not recompute
shareholder status or the 70 REALU holding locally.

### `GET /v1/realunit/referral/terms`

```json
{
  "version": "2026-08-14",
  "markdown": "…",
  "markdownEn": "…"
}
```

The app renders this 1:1. Bundled `assets/legal/referral_terms_*.md` is only
a fallback when the call fails.

### `POST /v1/realunit/referral/terms/accept`

Body: `{ "accepted": true }`.

### `POST /v1/realunit/referral/invites`

Body: `{ "guestName": "Alice" }`.

Response:

```json
{
  "code": "AB12CD",
  "url": "https://realunit.app/invite/AB12CD",
  "guestName": "Alice",
  "copyText": "Hey Alice, …"
}
```

The server generates code, URL, and share text.

### `GET /v1/realunit/referral/invites`

List of the current user's invites. The UI only shows **counts** of `Open`
and `Credited` from the summary — never registration, verification, or
purchases of the invited person.

### `POST /v1/realunit/referral/bind`

Body: `{ "code": "AB12CD" }`. Binds an invite or promo code.

```json
{
  "kind": "Promo",
  "campaignText": "…",
  "campaignTextEn": "…",
  "minBuyRealu": 200,
  "validUntil": "2026-09-07T00:00:00Z",
  "redemptionCap": 100
}
```

`kind` is `Invite` or `Promo`. Promo `campaignText` is shown 1:1 in a
dialog. The API rejects self-referral, double-bind, and promo+invite
stacking. Promo credit is only the first successful purchase of at least
`minBuyRealu` (default 200). A first buy below N creates no later claim.
`redemptionCap` is required — no unlimited option.

### `GET /v1/realunit/referral/code/:code` (public)

Landing payload for `realunit.app/invite/…` and `/promo/…`.

### `GET /v1/realunit/referral/payouts`

Each row carries `amount` (whole REALU), `created`, and `chfValue` frozen
at credit. The app never recomputes that CHF amount from the live share
price.

## App surfaces

- Dashboard card and settings entry only when `summary.eligible`
- Terms page; create-invite button after checkbox
  «Ich habe die Teilnahmebedingungen gelesen und akzeptiert»
- Overview: open / credited counts, total REALU, CHF, label «Aktienkurs»
- Registration: optional invite/promo code field (same field). After
  lookup the invite recognition copy or the promo campaign dialog is shown.
- History: referral payouts with amount, date, frozen CHF
- Deeplinks: `realunit-wallet://invite|promo/{code}` and
  `https://realunit.app/invite|promo/{code}`

## Website

`realunit.app/invite/{code}` and `/promo/{code}` look up the public code
route, greet by name or show the promo action text, open the app via the
custom scheme, and show App Store / Play Store badges. The Play Store URL
carries an install referrer (`invite=<code>`). On first Android launch the
app reads that referrer once and stashes the code for post-unlock bind.
The landing greets the invitee by name and tells iOS users to tap the
link again after a fresh install (Play Install Referrer covers Android).

## Out of this repository

Automatic 20 REALU payout, confirmation e-mail, quarterly cap of 100,
three-month pending expiry, compliance visibility, and promo admin
(required redemption cap, deactivation) belong to `DFXswiss/api`.
