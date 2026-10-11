'use strict';
const express    = require('express');
const Database   = require('better-sqlite3');
const bcrypt     = require('bcryptjs');
const jwt        = require('jsonwebtoken');
const cors       = require('cors');
const path       = require('path');
const fs         = require('fs');

const PORT    = process.env.PORT || 3001;
const SECRET  = process.env.JWT_SECRET || 'balikin-secret-2024';
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'data', 'balikin.db');

// Pastikan folder data ada
fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });

/* ─── DATABASE ─────────────────────────────────────────── */
const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id    INTEGER PRIMARY KEY AUTOINCREMENT,
    uname TEXT    NOT NULL UNIQUE,
    hash  TEXT    NOT NULL
  );
  CREATE TABLE IF NOT EXISTS settings (
    key   TEXT PRIMARY KEY,
    value TEXT
  );
  CREATE TABLE IF NOT EXISTS pj (
    id    TEXT PRIMARY KEY,
    nama  TEXT NOT NULL,
    div   TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS reqs (
    id       TEXT PRIMARY KEY,
    pj_id    TEXT,
    pj_name  TEXT,
    pj_div   TEXT,
    nama     TEXT,
    tgl      TEXT,
    items    TEXT,   -- JSON
    status   TEXT    DEFAULT 'wait',
    at       TEXT,
    dec_at   TEXT,
    ret_note TEXT,
    ret_cond TEXT,
    ret_ph   TEXT,
    ret_at   TEXT
  );
  CREATE TABLE IF NOT EXISTS logs (
    id      TEXT PRIMARY KEY,
    req_id  TEXT,
    status  TEXT,
    note    TEXT,
    at      TEXT
  );
`);

// Buat admin default jika belum ada
const adminExists = db.prepare('SELECT id FROM users WHERE uname = ?').get('admin');
if (!adminExists) {
  const hash = bcrypt.hashSync('admin123', 10);
  db.prepare('INSERT INTO users (uname, hash) VALUES (?,?)').run('admin', hash);
}

/* ─── APP ──────────────────────────────────────────────── */
const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json({ limit: '20mb' }));  // besar untuk foto base64

// Sajikan frontend
app.use(express.static(path.join(__dirname, '..')));

/* ─── AUTH MIDDLEWARE ───────────────────────────────────── */
function auth(req, res, next) {
  const hdr = req.headers.authorization;
  if (!hdr?.startsWith('Bearer ')) return res.status(401).json({ error: 'Unauthorized' });
  try {
    req.user = jwt.verify(hdr.slice(7), SECRET);
    next();
  } catch { res.status(401).json({ error: 'Token tidak valid' }); }
}

/* ─── ROUTES ────────────────────────────────────────────── */

// Login
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const user = db.prepare('SELECT * FROM users WHERE uname = ?').get(username);
  if (!user || !bcrypt.compareSync(password, user.hash))
    return res.status(401).json({ error: 'Username atau password salah' });
  const token = jwt.sign({ id: user.id, u: user.uname }, SECRET, { expiresIn: '7d' });
  res.json({ token, username: user.uname });
});

// Settings
app.get('/api/settings', (req, res) => {
  const rows = db.prepare('SELECT key, value FROM settings').all();
  const settings = {};
  rows.forEach(r => {
    try { settings[r.key] = JSON.parse(r.value); }
    catch { settings[r.key] = r.value; }
  });
  res.json(settings);
});

app.put('/api/settings', auth, (req, res) => {
  const upsert = db.prepare('INSERT OR REPLACE INTO settings (key, value) VALUES (?,?)');
  const tx = db.transaction(data => {
    Object.entries(data).forEach(([k, v]) => upsert.run(k, JSON.stringify(v)));
  });
  tx(req.body);
  res.json({ ok: true });
});

// PJ
app.get('/api/pj', (req, res) => {
  res.json(db.prepare('SELECT * FROM pj ORDER BY div, nama').all());
});

app.post('/api/pj', auth, (req, res) => {
  const { id, nama, div } = req.body;
  db.prepare('INSERT INTO pj (id,nama,div) VALUES (?,?,?)').run(id, nama, div);
  res.json({ ok: true });
});

app.put('/api/pj/:id', auth, (req, res) => {
  const { nama, div } = req.body;
  db.prepare('UPDATE pj SET nama=?, div=? WHERE id=?').run(nama, div, req.params.id);
  res.json({ ok: true });
});

app.delete('/api/pj/:id', auth, (req, res) => {
  db.prepare('DELETE FROM pj WHERE id=?').run(req.params.id);
  res.json({ ok: true });
});

// Requests
app.get('/api/reqs', (req, res) => {
  const reqs = db.prepare('SELECT * FROM reqs ORDER BY at DESC').all();
  res.json(reqs.map(r => ({ ...r, items: JSON.parse(r.items || '[]') })));
});

app.post('/api/reqs', (req, res) => {
  const r = req.body;
  db.prepare(`INSERT INTO reqs (id,pj_id,pj_name,pj_div,nama,tgl,items,status,at,dec_at,ret_note,ret_cond,ret_ph,ret_at)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`).run(
    r.id, r.pj, r.pjN, r.pjD, r.nama, r.tgl,
    JSON.stringify(r.items), 'wait', r.at, null, '', '', '', null
  );
  res.json({ ok: true, id: r.id });
});

app.patch('/api/reqs/:id', auth, (req, res) => {
  const { status, ret_note, ret_cond, ret_ph, ret_at } = req.body;
  const now = new Date().toISOString();
  if (status) db.prepare('UPDATE reqs SET status=?, dec_at=? WHERE id=?').run(status, now, req.params.id);
  if (ret_note !== undefined) db.prepare('UPDATE reqs SET ret_note=?, ret_cond=?, ret_ph=?, ret_at=? WHERE id=?').run(ret_note, ret_cond, ret_ph||'', ret_at, req.params.id);
  res.json({ ok: true });
});

// Logs
app.get('/api/logs', auth, (req, res) => {
  res.json(db.prepare('SELECT * FROM logs ORDER BY at DESC').all());
});

app.post('/api/logs', (req, res) => {
  const l = req.body;
  db.prepare('INSERT INTO logs (id,req_id,status,note,at) VALUES (?,?,?,?,?)').run(l.id, l.rid, l.st, l.note, l.at);
  res.json({ ok: true });
});

// Password
app.put('/api/password', auth, (req, res) => {
  const { newPassword } = req.body;
  if (!newPassword || newPassword.length < 6) return res.status(400).json({ error: 'Min 6 karakter' });
  const hash = bcrypt.hashSync(newPassword, 10);
  db.prepare('UPDATE users SET hash=? WHERE id=?').run(hash, req.user.id);
  res.json({ ok: true });
});

/* ─── SSE: Real-time push ke browser ───────────────────── */
const clients = new Set();

app.get('/api/events', (req, res) => {
  res.set({ 'Content-Type':'text/event-stream', 'Cache-Control':'no-cache', 'Connection':'keep-alive' });
  res.flushHeaders();
  clients.add(res);
  req.on('close', () => clients.delete(res));
});

function broadcast(event, data) {
  clients.forEach(c => c.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`));
}

// Panggil broadcast setelah perubahan data
app.use((req, res, next) => {
  const orig = res.json.bind(res);
  res.json = (body) => {
    if (req.method !== 'GET' && body?.ok) broadcast('update', { t: Date.now() });
    return orig(body);
  };
  next();
});

/* ─── START ─────────────────────────────────────────────── */
app.listen(PORT, () => {
  console.log(`✅ BalikinGo Backend berjalan di http://localhost:${PORT}`);
  console.log(`📁 Database: ${DB_PATH}`);
});
