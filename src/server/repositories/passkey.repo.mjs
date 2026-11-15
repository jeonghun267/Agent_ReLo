const toPasskey = row => row ? {
  id: row.id,
  userId: row.user_id,
  credentialId: row.credential_id,
  publicKey: JSON.parse(row.public_key),
  signCount: row.sign_count,
  name: row.name,
  createdAt: row.created_at,
  lastUsedAt: row.last_used_at,
} : null;

// Public keys of registered passkeys. Rows are always read and removed through the owner's id.
export function createPasskeyRepository(db) {
  return {
    insert({id, userId, credentialId, publicKey, signCount, name, createdAt}) {
      db.prepare('INSERT INTO passkeys(id, user_id, credential_id, public_key, sign_count, name, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)')
        .run(id, userId, credentialId, JSON.stringify(publicKey), signCount, name, createdAt);
    },

    // Signing in starts from the credential the device presents, before the user is known.
    findByCredentialId(credentialId) {
      return toPasskey(db.prepare('SELECT * FROM passkeys WHERE credential_id = ?').get(credentialId));
    },

    listForUser(userId) {
      return db.prepare('SELECT * FROM passkeys WHERE user_id = ? ORDER BY created_at').all(userId).map(toPasskey);
    },

    countForUser(userId) {
      return db.prepare('SELECT COUNT(*) AS n FROM passkeys WHERE user_id = ?').get(userId).n;
    },

    markUsed(id, signCount, usedAt) {
      db.prepare('UPDATE passkeys SET sign_count = ?, last_used_at = ? WHERE id = ?').run(signCount, usedAt, id);
    },

    // Returns whether a row of this user was removed.
    delete(userId, id) {
      return db.prepare('DELETE FROM passkeys WHERE user_id = ? AND id = ?').run(userId, id).changes > 0;
    },
  };
}
