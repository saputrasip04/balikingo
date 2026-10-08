# Tech — Arsitektur & Panduan Teknis

## Stack
| Lapisan | Pilihan |
|---|---|
| UI | HTML5 + CSS variables + JavaScript Vanilla (tanpa build step) |
| Font | Space Grotesk (Google Fonts, fallback `system-ui`) |
| Excel | SheetJS 0.18.5 dari cdnjs (impor dan template) |
| Penyimpanan | `localStorage` (satu kunci `pinjam_db`) |
| PWA | `manifest.webmanifest` + `sw.js` (network-first untuk HTML, pinjam-v4) |

## Struktur File
```
BalikinGo/
├─ index.html            # SPA: CSS, view (Form, Return, History, Dash, PJ, Settings), logika
├─ manifest.webmanifest  # metadata install PWA
├─ sw.js                 # cache offline (pinjam-v4)
├─ backend/              # Node.js + Express + SQLite (Fase 4)
├─ docker-compose.yml    # Docker containerization
├─ prd.md  database.md  tech.md  agent.md
```

## Menjalankan Lokal
Service worker dan `crypto.subtle` butuh **localhost atau HTTPS**; membuka lewat `file://` tidak cukup.
```bash
python -m http.server 8080      # atau: npx serve .
```
Buka `http://localhost:8080`. Untuk mengetes di HP, gunakan HTTPS (mis. tunnel atau sertifikat lokal), karena akses kamera dan install PWA di IP LAN biasa (`http://192.168.x.x`) diblokir browser.
Login petugas bawaan: `admin` / `admin123`.

## Pola Kode
- **State:** objek `S` (UI) dan `db` (data persisten). `render()` membuat ulang DOM dari state.
- **Form Peminjaman:** Widget aktif (`#active-borrowed-wrap`) mendeteksi barang pinjaman yang berstatus `ok` atau `returning`.
- **Input aman:** nilai form disimpan di `S.d`, sehingga render ulang tidak menghapus isian.
- **Escape:** semua teks pengguna melewati `e()` untuk mencegah XSS.
- **Foto:** `shrink()` memakai canvas (maks. 720 px, JPEG 0,7) sebelum disimpan.

## Real-Time
`BroadcastChannel('pinjam')` dan event `storage` memicu `syncCheck()`: muat ulang `db`, bandingkan status pengajuan milik perangkat, tampilkan toast + `Notification` bila berubah. Berlaku untuk tab/jendela di **browser dan perangkat yang sama**.

## Keamanan (Realistis)
- Password di-hash SHA-256, tetapi seluruh data ada di sisi klien, sehingga ini bukan keamanan sungguhan. Cukup untuk lingkungan tepercaya (lab/sekolah).
- Untuk penggunaan multi-perangkat, gunakan backend di folder `backend/` (Node/Express + SQLite).

## Keterbatasan Saat Ini
1. Impor/unduh Excel butuh internet pada pemakaian pertama (cdnjs), lalu tersimpan di cache SW.
2. Ikon PWA berupa SVG; sebagian browser meminta PNG 192/512 px untuk install, jadi tambahkan bila perlu.
3. Sinkronisasi antar-perangkat penuh membutuhkan backend aktif (Node/Express + SQLite).

## Status Implementasi & Roadmap
1. [x] Modul Pengembalian (tab `🔄 Pengembalian`, kondisi barang, catatan, foto bukti, konfirmasi/tolak petugas).
2. [x] Widget barang yang sedang dipinjam / belum kembali di atas Formulir Peminjaman.
3. [x] Form peminjaman ringkas (tombol foto & nama barang satu deret baris horizontal).
4. [ ] Backend ringan (Node/Express + SQLite) via Docker untuk sinkronisasi antar-perangkat LAN.
