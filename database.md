# Database — Struktur Data Lokal

Seluruh data disimpan dalam **satu objek JSON** pada `localStorage` dengan kunci `pinjam_db`. Satu kunci berarti satu operasi tulis dan satu event sinkronisasi, sehingga status yang diubah petugas langsung terbaca peminjam.

## Struktur Root
```json
{
  "v": 1,
  "settings": { "org": "string", "logo": "dataURL|''", "dark": false },
  "pj":    [ { "id": "string", "nama": "string", "div": "string" } ],
  "reqs":  [ { "id": "", "pj": "pj.id", "pjN": "", "pjD": "", "nama": "", "tgl": "YYYY-MM-DD",
               "items": [ { "n": "nama barang", "k": "kode", "ph": "dataURL JPEG" } ],
               "st": "wait|ok|no", "at": "ISO waktu diajukan", "dec": "ISO waktu keputusan|null" } ],
  "logs":  [ { "id": "", "rid": "reqs.id", "st": "wait|ok|no", "note": "", "at": "ISO" } ],
  "users": [ { "u": "username", "h": "SHA-256 hex password" } ]
}
```

## Catatan Tiap Koleksi
| Koleksi | Keterangan |
|---|---|
| `settings` | Branding dan preferensi tema. Perubahan langsung memengaruhi header dan halaman login. |
| `pj` | Penanggung jawab. `div` dipakai untuk pengelompokan dropdown. |
| `reqs` | Pengajuan. `pjN` dan `pjD` adalah salinan nama/divisi saat diajukan, jadi riwayat tidak berubah bila data `pj` diedit atau dihapus. |
| `logs` | Jejak status (diajukan, disetujui, ditolak) untuk audit. |
| `users` | Akun petugas. Bawaan: `admin` / `admin123` (hash dibuat saat pertama dibuka). **Ganti sebelum dipakai nyata.** |

## Kunci Lain (per perangkat, di luar `pinjam_db`)
| Kunci | Fungsi |
|---|---|
| `pinjam_me` | Daftar ID pengajuan milik perangkat ini, dipakai untuk riwayat peminjam |
| `pinjam_sess` | Sesi login petugas (`1` bila aktif) |

## Status
`wait` = Menunggu · `ok` = Disetujui · `no` = Ditolak. Pengajuan ulang membuat record baru, sedangkan record lama tetap sebagai riwayat.

## Batasan & Migrasi
- Kuota `localStorage` sekitar 5 MB. Foto dikompres (maks. 720 px, JPEG 0,7), sekitar 50–100 KB per foto, sehingga muat ratusan foto.
- Jika penuh, pindahkan `reqs[].items[].ph` ke IndexedDB (store `photos`, kunci = `reqId:index`) dan simpan hanya referensi di JSON.
- Cadangan: ekspor `localStorage.pinjam_db` ke file JSON secara berkala.
