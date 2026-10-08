# agent.md — Panduan untuk Agen AI / Kontributor

Baca `prd.md` (apa yang dibangun), `database.md` (bentuk data), dan `tech.md` (cara kerja) sebelum mengubah kode.

## Konteks Proyek
PWA mobile-first untuk peminjaman alat broadcasting dan perfilman. Tanpa backend, tanpa build step, semua data di `localStorage` (`pinjam_db`).

## Aturan Wajib
1. **Satu sumber data:** semua data persisten berada di objek `db`. Jangan membuat kunci `localStorage` baru untuk data bisnis (kecuali `pinjam_me` dan `pinjam_sess` yang bersifat per perangkat).
2. **Setiap perubahan data memanggil `save()`**, karena itulah yang memicu sinkronisasi real-time. Perubahan status wajib disertai `log()`.
3. **Escape semua teks pengguna** dengan `e()` sebelum masuk ke template HTML.
4. **Validasi peminjaman tidak boleh dilonggarkan:** penanggung jawab, nama peminjam, tanggal, serta nama, kode, dan foto tiap barang wajib ada.
5. **Snapshot pengajuan:** simpan `pjN`/`pjD` di `reqs`. Jangan bergantung pada tabel `pj` untuk riwayat.
6. **Jaga input:** ketik di form tidak boleh memicu `render()` penuh (gunakan `S.d`). Pembaruan real-time tidak me-render ulang saat pengguna sedang mengetik.
7. **Akses petugas:** tab Petugas dan Pengaturan hanya tampil setelah `adm()` bernilai true. Jangan menambah jalur yang melewati pengecekan ini.
8. **Mobile-first:** uji di lebar 360 px. Target sentuh minimal 44 px, dukung mode terang dan gelap lewat CSS variables.

## Konvensi
- Bahasa UI: Indonesia, kalimat sederhana, tombol berupa kata kerja ("Kirim pengajuan", "Setujui").
- Kode: JavaScript Vanilla, tanpa dependensi baru kecuali SheetJS. Bila menambah dependensi, muat dari cdnjs dan daftarkan di `sw.js`.
- Ubah `const C='pinjam-v1'` di `sw.js` setiap kali aset inti berubah agar cache lama dibuang.
- Status memakai kode `wait|ok|no`. Jangan mengganti tanpa migrasi data (naikkan `db.v`).

## Cara Menambah Fitur (Contoh: Modul Pengembalian)
1. Perbarui `prd.md` (kebutuhan dan kriteria penerimaan).
2. Tambah field ke `database.md` (mis. `st:'returned'`, `retAt`, `retNote`) dan naikkan `db.v` dengan fungsi migrasi di `load()`.
3. Tambah view dan aksi (`data-a="kembali"`) mengikuti pola delegasi di `document.onclick`.
4. Catat perubahan di `tech.md` bila arsitektur berubah.

## Checklist Sebelum Selesai
- [ ] Pengajuan tanpa foto ditolak validasi
- [ ] Petugas mengubah status → tab peminjam terbarui tanpa reload
- [ ] Logo dan nama organisasi tampil di header dan login
- [ ] Hapus penanggung jawab menampilkan modal konfirmasi
- [ ] Mode gelap bertahan setelah reload
- [ ] Berjalan offline setelah kunjungan pertama
- [ ] Dokumen `.md` sudah sinkron dengan kode

## Jangan Dilakukan
- Menyimpan password mentah atau membuat kredensial bawaan selain yang terdokumentasi.
- Menambahkan `<form>` yang me-reload halaman, atau `alert()` (gunakan `toast()` dan modal).
- Menyimpan foto resolusi penuh (selalu lewat `shrink()`).
