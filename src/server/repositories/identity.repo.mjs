// Accounts at an outside sign-in provider (Google) linked to a user.
export function createIdentityRepository(db) {
  return {
    findUserId(provider, subject) {
      return db.prepare('SELECT user_id AS userId FROM identities WHERE provider = ? AND subject = ?').get(provider, subject)?.userId ?? null;
    },

    insert({provider, subject, userId, email, createdAt}) {
      db.prepare('INSERT INTO identities(provider, subject, user_id, email, created_at) VALUES (?, ?, ?, ?, ?)')
        .run(provider, subject, userId, email, createdAt);
    },
  };
}
