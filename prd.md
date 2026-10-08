# PRD — Aplikasi Peminjaman & Pengembalian Peralatan Broadcasting & Perfilman

## 1. Tujuan
Menggantikan pencatatan manual peminjaman alat (kamera, tripod, mic, lighting, dll.) dengan PWA mobile-first yang berjalan offline di server lokal, dengan bukti foto per barang dan persetujuan petugas.

## 2. Pengguna
| Peran | Kebutuhan |
|---|---|
| Peminjam (siswa/anggota) | Mengajukan pinjaman dari HP, memantau status, mengajukan ulang jika ditolak |
| Petugas/Admin | Menyetujui/menolak, memeriksa foto barang, mengelola branding dan daftar penanggung jawab |
| Penanggung jawab (guru/instruktur) | Dipilih peminjam; tercatat di setiap pengajuan |

## 3. Kebutuhan Fungsional
**F1 Branding & Pengaturan (khusus petugas):** unggah logo, ubah nama organisasi (langsung tampil di header dan halaman login), mode gelap tersimpan lokal.
**F2 Penanggung jawab:** tambah manual, edit langsung, impor XLSX/XLS/CSV, unduh template (kolom `Nama`, `Divisi/Kelas`), hapus dengan modal konfirmasi.
**F3 Form peminjaman:** widget daftar alat yang sedang dipinjam/belum dikembalikan di atas formulir (menampilkan nama barang, peminjam, PJ, tanggal, thumbnail foto, badge status, dan tombol pengembalian instan), dropdown penanggung jawab wajib (pencarian + grup divisi), nama peminjam, tanggal pinjam, banyak barang dinamis (satu deret baris foto & nama). Kirim diblokir jika ada yang kosong.
**F4 Menu Pengembalian:** menu khusus peminjaman aktif, pencarian peminjam/alat, form kondisi alat (Baik/Rusak), catatan pengembalian, foto bukti, konfirmasi/penolakan oleh petugas, ekspor Excel.
**F5 Riwayat peminjam:** banner keputusan terbaru, statistik (Menunggu/Disetujui/Ditolak), kartu berwarna status dengan waktu keputusan, tombol "Ajukan ulang" bila ditolak, notifikasi lokal, status ter-update otomatis tanpa refresh.
**F6 Autentikasi petugas:** login username/password, sesi lokal, logout, pesan error visual.
**F7 Dashboard petugas:** statistik total, pencarian global (peminjam, penanggung jawab, nama barang), filter status, tombol Setujui/Tolak/Konfirmasi Kembali, detail per barang (thumbnail, nama, indikator foto, info kondisi kembali), lightbox layar penuh.
**F8 Persistensi:** seluruh data dalam satu struktur lokal (lihat `database.md`).

## 4. Kebutuhan Non-Fungsional
- Mobile-first, target lebar 360–420 px; tetap nyaman di desktop (maks. 520 px).
- Dapat di-install (PWA) dan berjalan offline setelah kunjungan pertama.
- Tanpa backend; siap jalan dengan server statis lokal.
- Sentuhan minimum 44 px; kontras cukup di mode terang dan gelap.

## 5. Alur Utama
1. Peminjam memilih penanggung jawab → mengisi form → foto tiap barang → kirim (status *Menunggu*).
2. Petugas login → membuka pengajuan → memeriksa foto → Setujui/Tolak.
3. Peminjam menerima notifikasi + banner; jika ditolak, memakai "Ajukan ulang".

## 6. Kriteria Penerimaan
- Pengajuan tanpa foto atau nama barang tidak dapat dikirim.
- Perubahan status petugas muncul di tab peminjam tanpa reload.
- Logo dan nama organisasi berubah di header dan login seketika.
- Data bertahan setelah browser ditutup.

## 7. Di Luar Lingkup (v1)
Sinkronisasi real-time antar-perangkat jaringan tanpa server, peran petugas majemuk. Lihat roadmap di `tech.md`.
