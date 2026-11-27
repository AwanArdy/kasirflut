# Panduan Desain TERATUR POS

Dokumen ini adalah acuan visual dan interaksi untuk aplikasi **TERATUR POS** (Flutter). Gunakan panduan ini saat membuat layar baru, menambah komponen, atau meninjau perubahan UI agar hasilnya tetap konsisten dengan tampilan yang sudah ada.

> Sumber acuan: implementasi di `lib/core/constants/`, `lib/presentation/`, dan tema aplikasi di `lib/main.dart`.

---

## 1. Ringkasan Produk

TERATUR POS adalah aplikasi kasir (point of sale) untuk outlet makanan/minuman dengan karakter:

- **Cepat dipakai saat sibuk** — aksi utama besar, alur checkout singkat.
- **Offline-first** — transaksi tetap jalan tanpa koneksi, sinkron otomatis.
- **Teratur secara operasional** — shift kas, modal awal, selisih laci, dan riwayat lokal terlihat jelas.
- **Tenang dan bersih** — dominasi putih, hijau lembut, banyak ruang kosong, tanpa gradien ramai.

Arah visual: **clean productivity / natural green**, Material 3, sudut membulat sedang, bayangan sangat halus, dan aksen hijau sebagai satu-satunya warna aksi utama.

---

## 2. Prinsip Desain

1. **Satu aksi utama per area.**
   Setiap panel hanya punya satu tombol paling menonjol. Di katalog: kartu produk. Di sidebar: `Payment Process`. Di dialog: aksi konfirmasi.
2. **Hijau untuk aksi, hijau tua untuk teks.**
   `primary` dipakai sebagai latar tombol/aksen; teks hijau memakai `primaryStrong` agar tetap terbaca.
3. **Status harus terbaca tanpa warna.**
   Setiap status penting disertai ikon dan label (`Offline (3)`, `Shift Belum Dibuka`, `Pending Offline`, `Kurang Bayar`).
4. **Kejelasan angka lebih penting daripada dekorasi.**
   Harga, total, kembalian, dan selisih kas selalu ditonjolkan dengan ukuran/weight lebih tinggi.
5. **Umpan balik langsung.**
   Perubahan qty, pilihan kategori, dan metode bayar memakai animasi singkat 150–180 ms.
6. **Konsisten, bukan seragam.**
   Radius dan spacing mengikuti skala di dokumen ini; jangan menambah nilai baru tanpa alasan.

---

## 3. Token Warna

Definisi: `lib/core/constants/app_colors.dart`

### 3.1 Fondasi

| Token | Hex | Penggunaan |
|---|---|---|
| `background` | `#F4F6F2` | Latar halaman / scaffold |
| `surface` | `#FFFFFF` | Kartu, panel, dialog, top bar |
| `surfaceDim` | `#E2E8E0` | Latar tombol disabled |
| `surfaceBright` | `#FFFFFF` | Permukaan paling terang |

### 3.2 Tonal Container

| Token | Hex | Penggunaan |
|---|---|---|
| `surfaceContainerLowest` | `#FFFFFF` | Kontainer paling terang |
| `surfaceContainerLow` | `#F2F7EE` | Isian input, kartu item keranjang, chip netral |
| `surfaceContainer` | `#E7F7EE` | Kontainer tonal hijau muda |
| `surfaceContainerHigh` | `#DCE7D4` | Pemisah / area sekunder |
| `surfaceContainerHighest` | `#D4E0CC` | Penekanan area sekunder |

### 3.3 Teks & Garis

| Token | Hex | Penggunaan |
|---|---|---|
| `onSurface` | `#0A0F0A` | Teks utama, judul |
| `onSurfaceVariant` | `#46524A` | Teks sekunder, metadata |
| `outline` | `#747F76` | Ikon pasif, placeholder |
| `outlineVariant` | `#C3CEC2` | Border kartu, input, divider |

### 3.4 Primary (aksi utama)

| Token | Hex | Penggunaan |
|---|---|---|
| `primary` | `#84C163` | Tombol utama, pill aktif, badge qty, border kartu terpilih |
| `onPrimary` | `#FFFFFF` | Teks/ikon di atas `primary` |
| `primaryHover` | `#6CA74C` | Hover (desktop/web) |
| `primaryActive` | `#578F38` | Pressed/active |
| `primaryStrong` | `#3F6B1C` | Teks hijau, harga, ikon pada latar terang |
| `primaryContainer` | `#D8ECC5` | Latar lembut untuk aksen hijau |
| `onPrimaryContainer` | `#1F3C0E` | Teks di atas `primaryContainer` |

### 3.5 Sekunder, Tersier, Error

| Token | Hex | Penggunaan |
|---|---|---|
| `secondary` | `#97D06F` | Aksen dekoratif |
| `onSecondary` | `#1F3C0E` | Teks di atas secondary |
| `secondaryContainer` | `#EAF6DF` | Latar sekunder |
| `onSecondaryContainer` | `#1F3C0E` | Teks di atas secondaryContainer |
| `tertiary` | `#337DBC` | Aksen informasi |
| `onTertiary` | `#FFFFFF` | Teks di atas tertiary |
| `tertiaryContainer` | `#E3EFF8` | Latar info |
| `onTertiaryContainer` | `#0C3A5E` | Teks info |
| `error` | `#FF4D4F` | Tombol destruktif, snackbar error |
| `onError` | `#FFFFFF` | Teks di atas error |
| `errorContainer` | `#FFDCDC` | Latar error lembut |
| `onErrorContainer` | `#8F0000` | Teks di atas errorContainer |
| `errorStrong` | `#C1272A` | Teks error, ikon peringatan |

### 3.6 Status Semantik

| Status | Latar | Teks/Ikon | Contoh |
|---|---|---|---|
| Sukses | `successBg` `#EAF6DF` | `successText` `#3F6B1C` | Kembalian cukup, shift balance |
| Peringatan | `warningBg` `#DFF2F0` | `warningText` `#2D756E` | Mode offline, shift belum dibuka, pending sync |
| Info | `infoBg` `#E3EFF8` | `infoText` `#1F5F97` | Informasi netral |
| Bahaya | `dangerBg` `#FFEBEB` | `dangerText` `#C1272A` | Kurang bayar, gagal sync, tutup shift |

> **Aturan penting:** jangan memakai `primary` sebagai warna teks di atas putih. Gunakan `primaryStrong`. Jangan memakai `error` untuk teks panjang; gunakan `errorStrong`.

---

## 4. Tipografi

Definisi: `lib/core/constants/app_typography.dart`
Font: **Plus Jakarta Sans** (judul) dan **Inter** (isi & label), dimuat via `google_fonts`.

| Token | Font | Size | Line height | Weight | Letter spacing | Warna default |
|---|---|---|---|---|---|---|
| `display` | Plus Jakarta Sans | 40 | 48 | 700 | -0.8 | `onSurface` |
| `headlineLg` | Plus Jakarta Sans | 32 | 40 | 700 | -0.64 | `onSurface` |
| `headlineMd` | Plus Jakarta Sans | 24 | 32 | 600 | 0 | `onSurface` |
| `headlineSm` | Plus Jakarta Sans | 20 | 28 | 600 | 0 | `onSurface` |
| `bodyLg` | Inter | 18 | 28 | 400 | 0 | `onSurface` |
| `bodyMd` | Inter | 16 | 24 | 400 | 0 | `onSurface` |
| `bodySm` | Inter | 14 | 20 | 400 | 0 | `onSurfaceVariant` |
| `labelMd` | Inter | 14 | 20 | 600 | 0.7 | `onSurface` |
| `labelSm` | Inter | 12 | 16 | 500 | 0 | `onSurfaceVariant` |

### Aturan pemakaian

- **Judul layar/panel:** `headlineMd` (mis. “Katalog Menu”) atau `headlineSm` (mis. “Order Detail”, “Struk Transaksi”).
- **Judul kecil di kartu/dialog:** `headlineSm`; angka besar (total, kembalian) boleh `headlineMd`.
- **Isi:** `bodyMd`; keterangan pendukung: `bodySm`.
- **Label form & eyebrow:** `labelMd`/`labelSm`, boleh `copyWith(letterSpacing: 0)` untuk teks yang bukan label pendek.
- **Angka uang:** selalu `formatRupiah()` dari `lib/utils/currency_formatter.dart`, tanpa desimal (`Rp 25.000`).
- **Override yang lazim:** `fontSize` turun 1–3 px dan `fontWeight` naik (`w700`/`w800`) untuk nama produk, harga, dan total. Jaga agar tidak menambah gaya teks baru di luar skala ini.
- **Jangan** memakai `display`/`headlineLg` di dalam panel sempit; keduanya khusus hero (login).

---

## 5. Spacing, Radius, Bayangan, Ukuran

### 5.1 Spacing

Gunakan kelipatan **4 px** dengan half-step 2 px dan skala berikut:

`2 · 4 · 6 · 8 · 10 · 12 · 14 · 16 · 18 · 20 · 24 · 28 · 32 · 40`

Panduan umum:

| Konteks | Spacing |
|---|---|
| Ikon ↔ teks | 6–8 |
| Antar elemen dalam kartu | 8–12 |
| Antar grup / field | 14–18 |
| Padding kartu kecil | 12–14 |
| Padding kartu/panel | 20 |
| Padding dialog | 24 (bawaan `AlertDialog`) |
| Padding halaman | 20–24 |
| Jarak section | 24–32 |

### 5.2 Radius

| Nilai | Penggunaan |
|---|---|
| 8 | Chip kecil, tombol mini, tombol “Clear All” |
| 10 | Tombol sekunder, ikon tile kecil, stepper |
| 12 | Input, tombol dialog, kartu item, snackbar |
| 14 | Kartu produk, search bar, CTA besar, panel login |
| 16 | Kartu produk |
| 20 | Dialog, panel error |
| 24 | Kartu login |
| 28 | Panel brand login |
| 999 | Pill, badge, avatar, chip kategori |

Gunakan `BorderRadius.circular(...)`; hindari radius campuran dalam satu komponen kecuali gambar produk (atas membulat, bawah mengikuti kartu).

### 5.3 Bayangan & Elevasi

- Tombol: **elevation 0**. Kedalaman dibentuk oleh warna dan border.
- Kartu produk: `blurRadius 8`, `offset (0,4)`, `onSurface` alpha 0.04.
- Kartu produk terpilih: `blurRadius 14`, alpha `primary` 0.12.
- Kartu login: `blurRadius 24`, `offset (0,10)`, `onSurface` alpha 0.05.
- Pill kategori aktif: `blurRadius 8`, `offset (0,3)`, `primary` alpha 0.25.
- Badge qty: `blurRadius 6`, `offset (0,2)`, `onSurface` alpha 0.15.

### 5.4 Ukuran Kunci

| Elemen | Ukuran |
|---|---|
| Top bar | tinggi 74 |
| Sidebar order | 370 (layar < 1200), 410 (≥ 1200) |
| Kartu login | lebar 430 |
| Dialog kecil | 380–420 |
| Dialog pembayaran | 460 |
| Dialog riwayat | 540 × 420 |
| CTA login | tinggi 52 |
| CTA pembayaran | tinggi 54 |
| Tombol dialog | padding 20 × 12 |
| Tombol kecil kartu | tinggi 36 |
| Tombol ikon top bar | minimal 40 × 40 |
| Search bar katalog | 300 × 46 |
| Ikon tile judul dialog | 38–40, radius 10 |
| Avatar kasir | radius 14 |

---

## 6. Ikonografi

- Keluarga: **Material Icons Rounded** (`*_rounded`), konsisten di seluruh aplikasi.
- Ukuran: 14–16 (inline), 18–20 (tombol), 22–26 (logo/tile), 30–42 (empty state).
- Ikon tile: kotak 36–40, radius 10, latar `primaryContainer`, ikon `primaryStrong`.
- Ikon destruktif (tutup shift, logout): `errorStrong` pada latar `dangerBg`.
- Ikon status: `cloud_off_rounded` (pending), `cloud_done_rounded` (sinkron), `schedule_rounded` (shift belum buka), `wifi_off_rounded` (mode offline).
- Logo aplikasi: `Icons.point_of_sale_rounded` dalam kotak hijau radius 12–14.

---

## 7. Layout & Responsif

### 7.1 Login

| Lebar | Layout |
|---|---|
| ≥ 860 | Dua kolom: panel brand (flex 5) + kartu login (flex 6), padding 32 |
| < 860 | Satu kolom, kartu login di tengah, padding 24 |

- Panel brand: latar `primaryContainer`, radius 28, border `primary` alpha 0.25, dekorasi dua lingkaran (`primary` 14%, `secondary` 20%) yang dipotong tepi.
- Kartu login: `surface`, radius 24, border `outlineVariant`, bayangan halus.
- Server URL disembunyikan di balik teks “Atur Server URL” agar form utama tetap ringkas.

### 7.2 Layar POS

```
┌──────────────────────────────────────────────────────────┐
│ TopNavBar (74)                                           │
├───────────────────────────────────┬──────────────────────┤
│ MenuGridWidget                    │ OrderSidebarWidget   │
│ - judul + search                  │ - header + items     │
│ - banner offline (kondisional)    │ - info pelanggan     │
│ - pill kategori                   │ - daftar item        │
│ - grid produk responsif           │ - ringkasan + CTA    │
└───────────────────────────────────┴──────────────────────┘
```

- Grid produk: 2 kolom (< 540), 3 kolom (540–859), 4 kolom (≥ 860); `childAspectRatio 0.78`, gap 14.
- Sidebar tetap di kanan dengan border kiri `outlineVariant`.
- Padding area katalog: `24, 20, 20, 20`.
- Padding sidebar: 20 horizontal.
- Konten utama memakai `Expanded` + `SafeArea`; tidak ada scroll pada seluruh halaman POS (scroll hanya di grid dan daftar item).

### 7.3 Breakpoint yang dipakai

| Breakpoint | Perubahan |
|---|---|
| 540 | Grid 2 → 3 kolom |
| 860 | Login 1 → 2 kolom; grid 3 → 4 kolom |
| 1200 | Sidebar 370 → 410 |

> Hindari menambah breakpoint baru. Jika butuh tablet kecil, gunakan rentang yang sudah ada.

---

## 8. Komponen

### 8.1 Tombol

**Primary (aksi utama)**

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
  child: const Text('Payment Process'),
)
```

- Tinggi 52–54 untuk CTA halaman/dialog besar; padding 20 × 12 untuk dialog.
- Teks `labelMd` (boleh `w700`, `letterSpacing` 0.2–0.3) + ikon 18–20.
- Disabled: latar `surfaceDim`, teks `outline`.

**Sekunder (outlined)**

- Latar `surfaceContainerLow`, border `outlineVariant`, teks `onSurface`/`primaryStrong`.
- Varian bahaya: latar `dangerBg`, border `error` alpha 0.4, teks `errorStrong`.

**Tersier / text**

- `TextButton` untuk “Batal”, “Atur Server URL”, “Clear All”.
- Aksi destruktif diberi latar `dangerBg` + radius 8.

**Tombol ikon**

- Kotak 40 × 40, radius 10, latar `surfaceContainerLow`, border `outlineVariant`.
- Selalu beri `tooltip` (“Refresh Menu”, “Keluar Akun”).

### 8.2 Input & Form

Bawaan tema (`main.dart`):

- `filled: true`, `fillColor: surfaceContainerLow`
- Radius 12, border `outlineVariant`
- Fokus: border `primary` 1.5
- Padding 14 × 14
- Label diletakkan **di luar** field memakai `labelSm`, jarak 6 ke field.
- `prefixIcon` untuk email, password, server, badge, promo.
- `prefixText: 'Rp '` untuk nominal uang.
- Password memakai toggle `visibility_outlined` / `visibility_off_outlined`.
- Pencarian katalog adalah pengecualian: latar `surface`, radius 14, tinggi 46.

### 8.3 Pill & Chip

- Bentuk `BorderRadius.circular(999)`.
- Tinggi efektif 30–42.
- Netral: `surface` atau `surfaceContainerLow` + border `outlineVariant`.
- Aktif: latar `primary`, teks `onPrimary`, border `primary`.
- Status: latar semantik + teks semantik + ikon 14–15.
- Contoh: outlet, status shift, `Items`, kategori, status sync, metode bayar.

### 8.4 Kartu Produk

- Latar `surface`, radius 16, border 1 (`outlineVariant`) atau 1.8 (`primary`) saat ada di keranjang.
- Rasio gambar : info ≈ 11 : 10.
- Gambar memenuhi bagian atas dengan radius atas 14; placeholder `surfaceContainerLow` + ikon kategori.
- Pill kategori di kiri atas (latar putih 92%).
- Badge qty di kanan atas (`primary`, teks putih `w700`).
- Nama produk maksimal 2 baris (`ellipsis`), harga `primaryStrong` `w800`.
- Belum di keranjang: tombol “Tambah” penuh, latar `primaryContainer`.
- Sudah di keranjang: stepper `− qty +`; tombol plus berlatarbelakang `primary`.
- Animasi perubahan state 180 ms.

### 8.5 Daftar Item Keranjang

- Kartu `surfaceContainerLow`, radius 12, border `outlineVariant` alpha 0.6, padding 12.
- Baris: nama (1 baris) + harga satuan → stepper 28 × 28 → subtotal rata kanan (lebar 82).
- Stepper memakai container putih radius 8 dengan border.
- Jarak antar item 10.

### 8.6 Dialog / Modal

Struktur baku:

1. **Title row:** ikon tile 38–40 (radius 10, `primaryContainer`/`dangerBg`) + judul `headlineSm`/default + aksi sekunder di kanan (opsional).
2. **Content:** lebar 380–540, `SingleChildScrollView` bila tinggi terbatas.
3. **Actions:** teks “Batal” (TextButton) + aksi utama (ElevatedButton). Aksi destruktif memakai `error`.

Aturan:

- Latar `surface`, `surfaceTintColor` transparan, radius 20.
- `barrierDismissible: false` untuk pembayaran (mencegah transaksi setengah jadi).
- Ringkasan penting (total, ekspektasi kas, selisih) ditempatkan di kartu `surfaceContainerLow`/`primaryContainer` di bagian atas.
- Modal yang ada di aplikasi: Info Pelanggan, Buka Shift, Tutup Shift, Pembayaran, Struk, Riwayat Lokal.

### 8.7 Snackbar

- `behavior: floating`, radius 12.
- Error: latar `error`, teks putih.
- Sukses/auto-sync: latar `primaryStrong`.
- Netral: tema bawaan.
- Pesan singkat, sebutkan angka bila relevan (“Auto-sync: 3 transaksi offline berhasil dikirim ke server.”).

### 8.8 Empty State

Pola: lingkaran 64–76 (`surfaceContainerLow`) + ikon 30–36 (`outline`) + judul `headlineSm` + deskripsi `bodySm` (maks. 2 baris, rata tengah) + aksi opsional.

Contoh: “Keranjang masih kosong”, “Menu tidak ditemukan” (+ “Reset Filter”), “Belum ada transaksi di perangkat ini.”

### 8.9 Loading & Error

- Loading: `CircularProgressIndicator(color: primary)` di tengah area; di dalam tombol gunakan ukuran 18–22 dan `strokeWidth` 2–2.5.
- Error katalog: kartu `surface` radius 20 + lingkaran `dangerBg` + ikon `error_outline_rounded` + pesan `errorStrong` + tombol “Coba Lagi”.

### 8.10 Banner Offline

- Latar `warningBg`, radius 12, border `warningText` alpha 0.25.
- Ikon `wifi_off_rounded` 18 + teks `labelSm` `w600`.
- Diletakkan tepat di atas pill kategori agar terlihat sebelum memilih menu.

---

## 9. Pola Interaksi & Alur

### 9.1 Menambah pesanan

1. Kasir mengetuk kartu produk atau tombol “Tambah”.
2. Qty bertambah; kartu berubah border, shadow, dan menampilkan stepper.
3. Sidebar langsung memperbarui item, jumlah item, subtotal, pajak, dan total.
4. Umpan balik tidak memakai dialog; perubahan terjadi in-place (180 ms).

### 9.2 Info pelanggan & tipe order

- Kartu info pelanggan di sidebar selalu terlihat; ketuk untuk membuka dialog.
- Default: `Walk-in Customer` + `Dine In`.
- Tipe order: `Dine In` / `Takeaway` / `Delivery` memakai `SegmentedButton` dengan ikon.
- Nama kosong otomatis menjadi “Walk-in Customer”.

### 9.3 Pembayaran

```
Keranjang terisi
  → tekan "Payment Process"
  → jika shift belum aktif, buka dialog "Buka Shift" lebih dulu
  → pilih metode (Tunai / QRIS / Debit / Transfer)
  → [Tunai] isi uang diterima atau pilih chip nominal
  → indikator Kembalian (hijau) / Kurang Bayar (merah)
  → promo opsional (TERATUR10 = 10%)
  → "Bayar Sekarang" (disabled bila uang kurang / sedang proses)
  → struk + status Synced / Offline (Antre Sync)
```

Aturan:

- Total tagihan selalu terlihat di banner atas dialog.
- Chip nominal cepat: “Uang Pas”, Rp 20.000, Rp 50.000, Rp 100.000.
- Tombol bayar menampilkan spinner dan tidak bisa ditekan ganda.
- Setelah sukses: keranjang dikosongkan, shift dimuat ulang, lalu struk tampil.

### 9.4 Shift kas

- Top bar menampilkan status: `Kas: Rp ...` (aktif) atau `Shift Belum Dibuka` (peringatan).
- Buka shift: pilih Pagi/Sore-Malam, modal awal, catatan.
- Tutup shift: ringkasan modal awal, penjualan tunai, penjualan QRIS, ekspektasi laci; input uang fisik; indikator `Balance` atau `Selisih`.
- Konfirmasi tutup shift memakai warna bahaya.

### 9.5 Offline & sinkronisasi

- Top bar menampilkan `Offline (n)` saat ada antrean, atau `Riwayat & Sync`.
- Banner offline muncul di katalog saat data berasal dari cache SQLite.
- Modal riwayat menampilkan status per transaksi: `Synced`, `Pending Offline`, `Gagal Sync`.
- Sinkronisasi manual memakai tombol “Sync Sekarang” dan menampilkan hasil (berhasil/gagal).

---

## 10. Bahasa & Konten

- Bahasa UI: **Indonesia**, ringkas dan operasional.
- Sapaan/aksi memakai kata kerja: “Masuk Kasir”, “Buka Shift”, “Tutup Shift”, “Bayar Sekarang”, “Coba Lagi”.
- Istilah teknis yang dipertahankan: QRIS, SKU, SQLite, Sync, Offline.
- Nama menu/judul memakai Title Case; label form memakai Sentence case.
- Uang: `Rp 25.000` (tanpa desimal, pemisah ribuan titik).
- Waktu: `HH:mm` untuk jam berjalan; `dd MMM yyyy, HH:mm` untuk struk; `dd/MM HH:mm` untuk daftar riwayat.
- Jangan menampilkan pesan error mentah dari server tanpa konteks; bungkus dengan kalimat yang bisa ditindaklanjuti.
- Angka penting selalu disertai satuan/konteks (“3 Items”, “Selisih: Rp 5.000”).

---

## 11. Aksesibilitas

- **Kontras:** teks hijau di atas putih wajib `primaryStrong` (`#3F6B1C`), bukan `primary`. Teks sekunder memakai `onSurfaceVariant`.
- **Target sentuh:** minimal 40 × 40 untuk tombol ikon; 44 × 44 ideal. Tombol 28–36 di stepper dapat diterima karena berpasangan dan memiliki area kartu, tetapi jangan diturunkan lagi.
- **Jangan andalkan warna saja:** sertakan ikon + teks status.
- **Fokus keyboard (web/desktop):** gunakan `InkWell`/tombol Material, jangan gesture tanpa affordance.
- **Tooltip** untuk semua ikon tanpa label.
- **Ukuran teks:** jangan di bawah 11 px; 11 px hanya untuk badge/metadata pendek.
- **Dialog:** pastikan konten bisa di-scroll pada layar pendek; jangan memotong aksi.

---

## 12. Implementasi di Flutter

### 12.1 Tema global

Ada di `lib/main.dart`: Material 3, scaffold `background`, `ColorScheme.fromSeed(primary)`, divider `outlineVariant`, dialog radius 20, input radius 12, snackbar floating radius 12.

Saat menambah tema baru, taruh di `ThemeData` agar tidak diulang di setiap widget. Namun komponen yang punya gaya khas (kartu produk, pill kategori, banner) tetap memakai style lokal seperti pola yang ada.

### 12.2 Struktur folder presentasi

```
lib/
├── core/constants/       # AppColors, AppTypography (token)
├── presentation/
│   ├── navigation/       # TopNavBar
│   ├── screens/          # LoginScreen, PosScreen
│   └── widgets/          # ProductCard, MenuGrid, OrderSidebar,
│                         # PaymentModal, ShiftModals, OfflineQueueModal
├── logic/                # Cubit per domain (auth, cart, catalog, checkout, shift)
└── utils/                # formatRupiah, formatNumber
```

Aturan:

- Warna/jenis huruf **hanya** dari `AppColors`/`AppTypography`; jangan hardcode `Color(0x...)` atau `TextStyle(fontSize: ...)` baru di widget.
- Format uang **selalu** melalui `formatRupiah`/`formatNumber`.
- Widget presentasional menerima data + callback; akses Cubit dilakukan di level layar/widget container.
- Dialog dibuka lewat fungsi `show*` (`showPaymentModal`, `showOpenShiftDialog`, dll.) agar konsisten.
- Animasi standar: 150 ms (pilihan metode), 180 ms (kartu/kategori), tanpa animasi berlebihan.

### 12.3 Contoh penggunaan token

```dart
Text('Total Amount', style: AppTypography.headlineSm);
Text(
  formatRupiah(state.grandTotal),
  style: AppTypography.headlineMd.copyWith(
    color: AppColors.primaryStrong,
    fontWeight: FontWeight.w800,
  ),
);
```

---

## 13. Do & Don't

| Lakukan | Hindari |
|---|---|
| Gunakan `primary` untuk latar aksi, `primaryStrong` untuk teks | Teks hijau `primary` di atas putih |
| Pertahankan satu CTA utama per panel | Dua tombol solid bersebelahan |
| Gunakan pill untuk filter/status pendek | Pill untuk paragraf panjang |
| Gunakan `surfaceContainerLow` untuk field/kartu sekunder | Abu-abu netral di luar palet |
| Beri ikon + teks pada status | Status hanya warna |
| Gunakan dialog lebar 380–540 | Dialog full-width di desktop |
| Animasi 150–180 ms | Animasi > 300 ms untuk aksi kasir |
| Angka uang rata kanan di daftar | Angka uang tersebar tanpa alignment |
| Border tipis + shadow halus | Shadow tebal/elevasi tinggi |

---

## 14. Checklist Sebelum Merge

- [ ] Warna dan font berasal dari `AppColors`/`AppTypography`.
- [ ] Uang diformat dengan `formatRupiah`.
- [ ] Radius mengikuti skala (8/10/12/14/16/20/24/28/999).
- [ ] Spacing kelipatan 4 (dengan half-step 2).
- [ ] CTA utama jelas; state disabled terlihat.
- [ ] Loading, error, dan empty state tersedia.
- [ ] Status tidak hanya dibedakan lewat warna.
- [ ] Target sentuh ikon ≥ 40 × 40 dan memiliki tooltip.
- [ ] Dialog bisa di-scroll pada layar pendek.
- [ ] Teks bahasa Indonesia konsisten dan tidak terpotong.
- [ ] Diuji pada lebar < 540, 540–859, ≥ 860, dan ≥ 1200.
- [ ] Tidak ada overflow pada grid, top bar, atau sidebar.

---

## 15. Catatan Konsistensi (Technical Debt Visual)

Temuan dari kode saat ini; pertimbangkan saat menyentuh area terkait:

1. **Radius pencarian 14 vs input global 12.** Pertahankan 14 untuk search katalog, atau standarkan ke 12 bila ingin seragam.
2. **Tombol “Tambah” pada kartu hanya 36 px.** Di layar sentuh kecil ini di bawah rekomendasi 44 px; pertimbangkan 40–44 bila ruang memungkinkan.
3. **Beberapa teks memakai `TextStyle` inline** (mis. label “Tambah” dengan `fontWeight` manual) alih-alih `AppTypography`. Prioritaskan token saat refactor.
4. **Sidebar berlebar tetap 370** berpotensi sempit pada layar < 900. Pertimbangkan mode drawer/collapsible untuk tablet portrait.
5. **Top bar berisi banyak kontrol** (outlet, shift, sync, refresh, profil, shift action, logout). Pada lebar menengah, pertimbangkan mengelompokkan aksi sekunder ke menu overflow.
6. **Status shift “Kas”** menampilkan ekspektasi kas, bukan kas fisik aktual; pastikan copywriting tidak menimbulkan salah tafsir.
7. **Warna `inverseOnSurface` (`#EAF1E8`)** sangat terang untuk teks di atas `inverseSurface`; hindari pemakaian tersebut tanpa pemeriksaan kontras.
