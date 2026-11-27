# Design System & UI Blueprint — Migrasi Frontend POS Kasir (YuaiPOS) ke Flutter

> **Panduan Desain & Spesifikasi Komponen Visual Flutter**
> **Aplikasi Target:** YuaiPOS / Cashy POS (Flutter Frontend)
> **Asal Desain:** React + Tailwind CSS (`@/uikasir`)

---

## 1. Filosofi Desain & Pendekatan Visual

Sistem desain **YuaiPOS** dikembangkan dengan filosofi **Modern Minimalism & Operational High-Speed Efficiency**. Aplikasi kasir digunakan dalam ritme kerja yang cepat dan intensif di area counter/kitchen, sehingga antarmuka harus:

1. **"Invisible UI" & Flat-Plus Approach:** Mengurangi beban kognitif staf dengan meminimalkan penggunaan bayangan tebal (*heavy shadows*). Hirarki visual ditentukan oleh warna kontras, pembatas halus (*ghost borders* 1dp `#C3CEC2`), dan tonal background shift.
2. **Kesesuaian F&B Grade:** Dibuat dengan tingkat kejelasan tinggi (*high legibility*) dari jarak jauh (misal: total harga atau nomor meja).
3. **Touch-First Target Size:** Semua elemen interaktif memiliki area sentuh (*touch target*) minimal 48dp x 48dp untuk mencegah salah tekan (*miss-click*) pada layar sentuh POS.

---

## 2. Token Desain Flutter (Theme & Color Constants)

Seluruh token warna dan tipografi diimplementasikan dalam kelas Dart `AppColors` dan `AppTypography` untuk menjamin konsistensi 100% dengan antarmuka React sebelumnya.

### 2.1 Palet Warna Dart (`lib/core/constants/app_colors.dart`)

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand & Foundations
  static const Color background = Color(0xFFF4F6F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFE2E8E0);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  
  // Tonal Containers
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F7EE);
  static const Color surfaceContainer = Color(0xFFE7EFE0);
  static const Color surfaceContainerHigh = Color(0xFFDCE7D4);
  static const Color surfaceContainerHighest = Color(0xFFD4E0CC);
  
  // Content & Text
  static const Color onSurface = Color(0xFF0A0F0A);
  static const Color onSurfaceVariant = Color(0xFF46524A);
  static const Color outline = Color(0xFF747F76);
  static const Color outlineVariant = Color(0xFFC3CEC2);
  
  // Primary (Hijau Utama POS)
  static const Color primary = Color(0xFF84C163);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryHover = Color(0xFF6CA74C);
  static const Color primaryActive = Color(0xFF578F38);
  static const Color primaryStrong = Color(0xFF3F6B1C);
  static const Color primaryContainer = Color(0xFFD8ECC5);
  static const Color onPrimaryContainer = Color(0xFF1F3C0E);
  
  // Secondary (Hijau Aksesori)
  static const Color secondary = Color(0xFF97D06F);
  static const Color onSecondary = Color(0xFF1F3C0E);
  static const Color secondaryContainer = Color(0xFFEAF6DF);
  static const Color onSecondaryContainer = Color(0xFF1F3C0E);
  
  // Tertiary & Info (Biru Aksesori)
  static const Color tertiary = Color(0xFF337DBC);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE3EFF8);
  static const Color onTertiaryContainer = Color(0xFF0C3A5E);
  
  // Error & Destructive State
  static const Color error = Color(0xFFFF4D4F);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDCDC);
  static const Color onErrorContainer = Color(0xFF8F0000);
  static const Color errorStrong = Color(0xFFC1272A);
  
  // Inverse Surface
  static const Color inverseSurface = Color(0xFF1C241D);
  static const Color inverseOnSurface = Color(0xFFEAF1E8);

  // Semantic Feedback States
  static const Color successBg = Color(0xFFEAF6DF);
  static const Color successText = Color(0xFF3F6B1C);
  
  static const Color warningBg = Color(0xFFDFF2F0);
  static const Color warningText = Color(0xFF2D756E);
  
  static const Color infoBg = Color(0xFFE3EFF8);
  static const Color infoText = Color(0xFF1F5F97);
  
  static const Color dangerBg = Color(0xFFFFEBEB);
  static const Color dangerText = Color(0xFFC1272A);
}
```

### 2.2 Token Tipografi Dart (`lib/core/constants/app_typography.dart`)

YuaiPOS menggunakan strategi **Dual-Font**:
* **Plus Jakarta Sans:** Digunakan untuk judul (*headlines*), total harga, nomor invoice, dan tombol aksi utama untuk memberikan nuansa modern dan legibilitas angka yang tinggi.
* **Inter:** Digunakan untuk teks isi (*body*), nama item menu, rincian biaya, dan label input.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Plus Jakarta Sans Headlines
  static TextStyle display = GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
    letterSpacing: -0.8,
    color: AppColors.onSurface,
  );

  static TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    color: AppColors.onSurface,
  );

  // Inter Body Copy
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurface,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  // Inter Labels
  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    letterSpacing: 0.7,
    color: AppColors.onSurface,
  );

  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.onSurfaceVariant,
  );
}
```

### 2.3 Radius & Spacing Tokens
* **Standard Elements (Buttons, Inputs, Cards):** `BorderRadius.circular(12)` (12dp).
* **Small Badges & Buttons:** `BorderRadius.circular(8)` (8dp).
* **Status Chips & Pills:** `BorderRadius.circular(999)` (Full Pill).
* **Modal Dialog Overlay:** `BorderRadius.circular(16)` (16dp).
* **Grid Spacing Unit:** 8dp base unit (4dp half-step untuk icon-text padding).

---

## 3. Layar & Layout Spesifikasi Flutter

Aplikasi POS menggunakan pembagian tata letak adaptif berbasis rentang lebar layar (*breakpoints*).

```text
+-----------------------------------------------------------------------------------+
| TopNavWidget (Height: 72dp)                                                       |
+---------------------------------------------------------+-------------------------+
| Left Section: MenuGrid (Flex: 7)                        | Right Section: Sidebar  |
|                                                         | OrderSidebar (Width:    |
| - Header & Search Input (w-72)                          |  360dp - 420dp / Flex 5)|
| - Horizontal Category Pills (Scrollable)                |                         |
| - Grid Product Cards (1 to 4 Columns)                   | - Order Header & Count  |
|                                                         | - Customer Info Bar     |
|                                                         | - Cart Items List       |
|                                                         | - Note Input            |
|                                                         | - Promo & Cost Summary  |
|                                                         | - Checkout Button (56dp)|
+---------------------------------------------------------+-------------------------+
```

### 3.1 Breakpoint Grid Adaptif
* **Desktop / Tablet Landscape (Width >= 1024dp):** Split view penuh. MenuGrid (flex 7) + OrderSidebar (width 360dp–420dp).
* **Tablet Portrait (768dp <= Width < 1024dp):** MenuGrid (2 kolom) + OrderSidebar collapsible / bottom sheet.
* **Mobile (Width < 768dp):** Single column. Switch tab antara katalog menu dan keranjang belanja.

---

## 4. Cetak Biru Komponen Widget Flutter (UI Component Specifications)

### 4.1 Header Bar (`TopNavWidget`)
* **Spesifikasi:** `Container(height: 72, color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)))`.
* **Sub-Widget Header:**
  1. **Brand Container:** `Row` berisi logo `Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)))` dengan icon `Icons.point_of_sale` berwarna putih.
  2. **Outlet Badge:** `Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: ShapeDecoration(color: AppColors.surfaceContainer, shape: StadiumBorder()))` dengan teks `Outlet Utama · Makassar`.
  3. **Navigation Tabs:** `Row` berisi link navigasi (`Home`, `Order List`, `History`, `Setting`). Indikator tab aktif menggunakan `Border(bottom: BorderSide(color: AppColors.primary, width: 2))` dan warna teks `AppColors.primaryStrong`. Tab inaktif tanpa border bawah.
  4. **Kasir Info & Clock:** Teks nama kasir aktif + jam realtime (`formatClock(date)`).
  5. **Tombol Tutup Sesi:** `OutlinedButton` dengan border `outlineVariant` dan warna teks `onSurfaceVariant`, berubah merah saat diposisikan hover.

---

### 4.2 Grid Katalog Menu (`MenuGridWidget` & `ProductCardWidget`)

#### A. Container Menu Grid
* **Search Input Field:** `TextField` berlatar belakang `surface`, border `outlineVariant`, rounded 8dp. Icon `search` di posisi prefix.
* **Category Pill List:** `ListView.builder` horizontal dengan height 40dp.
  * Widget `InkWell` / `GestureDetector` wrapped dalam `AnimatedContainer`.
  * Status Aktif: Background `AppColors.primary`, Teks `onPrimary`, shadow halus.
  * Status Inaktif: Background transparent, Teks `onSurfaceVariant`.

#### B. Card Produk (`ProductCardWidget`)
* **Struktur Card:** `Container` berlatar `surface`, border `outlineVariant` 1dp, rounded 12dp.
* **Tampilan Gambar:** `AspectRatio(aspectRatio: 1.0)` memuat `CachedNetworkImage` dengan rounded 8dp.
  * **Low Stock Pill Overlay:** `Positioned(top: 8, left: 8)` berisi `Container` warna `warningBg` dengan teks `warningText` `Stok N` (Bold 12sp).
* **Teks Detail:**
  * Nama Produk: `AppTypography.bodyMd` dengan `FontWeight.bold` (maxLines: 2, overflow: TextOverflow.ellipsis).
  * Kategori: `AppTypography.bodySm`.
  * Harga: `AppTypography.headlineSm` berwarna `onSurface`.
* **Area Tombol Aksi Tambah:**
  * `qty == 0`: Tombol penuh `ElevatedButton` warna `primary`, height 36dp, rounded 6dp dengan icon `add` dan label "Tambah".
  * `qty > 0`: `Row` berisi `IconButton` `remove` (`surfaceContainer`), angka Qty (`bodyMd` Bold), dan `IconButton` `add` (`primary`).

---

### 4.3 Sidebar Keranjang (`OrderSidebarWidget`)

* **Background Section:** `AppColors.surface` dengan border left 1dp `outlineVariant`.
* **Customer Edit Bar:** `Container` warna `surfaceContainerLow` (opacity 40%). Menampilkan nama pelanggan dan nomor meja. Tombol swap `swap_horiz` membuka form input inline.
* **Cart Items Scroll View:** `ListView.separated` dengan divider tipis `outlineVariant`.
  * Item Row: `Row` [ Gambar 48x48dp, `Column` (Nama Item, Harga Satuan x Qty), Subtotal Item, Tombol Close `close` ].
* **Note Input Button:** Tombol dash border dengan icon `edit_note` dan label "Add Order Note".
* **Cost Summary Container:**
  * Subtotal & Tax (10%): `Row` rata kanan-kiri.
  * Discount: Teks merah `errorStrong` (`-Rp X.XXX`).
  * Total Amount: Teks `headlineMd` font *Plus Jakarta Sans* warna `primaryStrong`.
* **Tombol Payment Process:** `SizedBox(height: 56, width: double.infinity)` dengan `ElevatedButton` warna `primary`, text bold 18sp.

---

### 4.4 Modal Buka & Tutup Sesi (`OpenShiftModal` & `CloseShiftModal`)

* **Styling Overlay:** `Dialog` dengan background transparent, dibungkus `BackdropFilter(filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4))`.
* **Container Card:** Rounded 16dp, shadow overlay, width max 448dp.
* **Form Elements:**
  * Karyawan Dropdown: `DropdownButtonFormField<String>` berlatar `surface`, border `outlineVariant`.
  * PIN Input: `TextField` dengan `obscureText: true`, `keyboardType: TextInputType.number`, `maxLength: 6`, letter-spacing 0.4em.
  * Modal Awal: `TextField` dengan prefix text `Rp`.
* **Close Shift Rekap View:**
  * `Container` berlatar `background` rounded 12dp.
  * Baris-baris `SummaryRow`: Transaksi Lunas, Total Penjualan, Modal Awal, Penjualan Tunai, Kas Seharusnya, Kas Fisik Dihitung, dan **Selisih Kas**.

---

### 4.5 Modal Pembayaran (`PaymentModal`)

* **Tabs Metode Bayar:** `GridView.count(crossAxisCount: 4, shrinkWrap: true)` berisi 4 opsi (`CASH`, `QRIS`, `TRANSFER`, `CARD`). Method terpilih memiliki border 2dp `primary` dan background `surfaceContainerLow`.
* **CASH Keypad Engine:**
  * Container Uang Diterima: Background `surfaceContainerLow`, Teks 36sp Bold. Green jika `amount >= total`, else normal.
  * Grid Keypad 3x4: Widget `KeyButton` (height 48dp, border 1dp, text 18sp font-semibold).
  * Key `1`–`9`, `C` (red container text), `0`, `00`.
  * Tombol **"Uang Pas"**: Spans 3 kolom, border `primary`, text `primaryStrong`.
* **Tombol Konfirmasi:** `SizedBox(height: 56)` dengan icon `verified` dan label "Konfirmasi Pembayaran".

---

### 4.6 Modal Struk & Animasi Printer (`ReceiptModal`)

* **Struk Preview Card (Paper Look):** Background `white`, border dashed divider, font *Inter* & *Plus Jakarta Sans*.
* **Animasi Cetak Struk Flutter (`AnimatedContainer`):**
  * State `phase == 'printing'`: Height struk bertambah secara mulus dari `0` ke `paperHeight` menggunakan `Curve.linear` selama 2.5 detik.
  * Simbol Printer Header: Container hitam `inverseSurface` rounded 12dp dengan lampu indikator LED kedip (`semanticWarning` -> `semanticSuccess`).
* **Hardware Printing Integration:** Panggilan native helper via channel ESC-POS printer (`blue_thermal_printer` / `printing`).

---

### 4.7 Order List Page & History Page

* **StatusChipWidget (`lib/presentation/widgets/status_chip_widget.dart`):**
  ```dart
  Widget buildStatusChip(DisplayStatus status) {
    Color bg;
    Color text;
    String label;
    
    switch (status) {
      case DisplayStatus.PENDING:
        bg = AppColors.surfaceContainer;
        text = AppColors.onSurfaceVariant;
        label = 'Pending';
        break;
      case DisplayStatus.COOKING:
        bg = AppColors.warningBg;
        text = AppColors.warningText;
        label = 'Cooking';
        break;
      case DisplayStatus.READY:
        bg = AppColors.successBg;
        text = AppColors.successText;
        label = 'Ready to Serve';
        break;
      case DisplayStatus.DELIVERED:
        bg = AppColors.infoBg;
        text = AppColors.infoText;
        label = 'Telah Diantar';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
  ```

* **History Row Item:** `InkWell` dengan icon metode bayar (`payments`, `qr_code_2`, `currency_exchange`, `credit_card`), invoice number, timestamp, total harga (strikethrough jika void/refund), dan badge status.

---

## 5. Peta Ikon & Aset Visual

| React Material Symbol | Flutter Material Icon / Asset | Penggunaan |
|---|---|---|
| `point_of_sale` | `Icons.point_of_sale` | Logo Brand YuaiPOS |
| `store` | `Icons.store` | Badge Outlet Active |
| `account_balance_wallet` | `Icons.account_balance_wallet` | Badge Modal Awal |
| `home` | `Icons.home` | Tab Navigation Home |
| `list_alt` | `Icons.list_alt` | Tab Navigation Order List |
| `history` | `Icons.history` | Tab Navigation History |
| `settings` | `Icons.settings` | Tab Navigation Setting |
| `logout` | `Icons.logout` | Tombol Tutup Sesi |
| `search` | `Icons.search` | Input Search Menu |
| `add` / `remove` | `Icons.add` / `Icons.remove` | Qty Controls Product Card |
| `shopping_cart` | `Icons.shopping_cart` | Empty Cart State |
| `payments` / `qr_code_2` / `credit_card` | `Icons.payments` / `Icons.qr_code_2` / `Icons.credit_card` | Metode Pembayaran |
| `print` | `Icons.print` | Cetak Struk |