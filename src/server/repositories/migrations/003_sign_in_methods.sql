-- Other ways into an existing account, next to the password:
--   identities: a Google account linked to a user (provider + the provider's
--               permanent id for that person). One Google account opens one user.
--   passkeys:   public keys of the passkeys a user registered. Only the public
--               key is stored; the private key never leaves the person's device.
-- Both are off until the operator sets GOOGLE_CLIENT_ID/SECRET or PASSKEY_RP_ID.

CREATE TABLE identities(
  provider TEXT NOT NULL CHECK(provider IN ('google')),
  subject TEXT NOT NULL,
  user_id TEXT NOT NULL REFERENCES users(id),
  email TEXT NOT NULL,
  created_at TEXT NOT NULL,
  PRIMARY KEY(provider, subject)
);
CREATE INDEX identities_user ON identities(user_id);

CREATE TABLE passkeys(
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  credential_id TEXT NOT NULL UNIQUE,
  public_key TEXT NOT NULL,
  sign_count INTEGER NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  last_used_at TEXT
);
CREATE INDEX passkeys_user ON passkeys(user_id);
