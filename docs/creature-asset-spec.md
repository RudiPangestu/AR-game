# Kontrak Aset Kreatur (untuk Blender MCP)

Dokumen ini adalah spesifikasi yang harus dipenuhi file USDZ agar bisa langsung dipakai game **tanpa mengubah satu baris kode pun**.

Selama file-nya belum ada, game memakai `ProceduralVisualProvider` — tubuh dirakit dari sphere dan box di kode. Begitu file USDZ muncul di bundle, `CompositeVisualProvider` otomatis memilihnya.

---

## Cara integrasinya bekerja

`ScanToSummon/AR/Visual/CompositeVisualProvider.swift` mencoba dua jalur berurutan:

1. `USDZVisualProvider` — cari `Creatures/<archetype>.usdz` di bundle app
2. `ProceduralVisualProvider` — fallback, selalu berhasil

Jadi kamu bisa mengerjakan satu archetype dulu. Sebelas sisanya tetap tampil prosedural, tidak ada yang rusak.

---

## Daftar file yang dibutuhkan

Nama file **harus** persis sama dengan `rawValue` archetype, huruf kecil semua:

| File | Isi |
|---|---|
| `aqua.usdz` | benda pembawa cairan — gelas, botol, keran |
| `verdant.usdz` | tumbuhan dan kayu |
| `ember.usdz` | api, lampu, sesuatu yang panas |
| `ferro.usdz` | perkakas dan logam |
| `textil.usdz` | kain, bantal, sepatu |
| `glass.usdz` | kaca, cermin, lensa |
| `paper.usdz` | buku, kotak, kertas |
| `fauna.usdz` | hewan, boneka, manusia |
| `snack.usdz` | makanan dan minuman |
| `tech.usdz` | perangkat elektronik |
| `ceramic.usdz` | piring, ubin, tembikar |
| `void.usdz` | benda tak dikenali |

Taruh semuanya di `ScanToSummon/App/Resources/Creatures/`. Folder itu ikut ter-bundle otomatis lewat synchronized folder group Xcode.

**Penting:** folder harus ditambahkan ke Xcode sebagai **folder reference (biru)**, bukan group (kuning). `Bundle.url(forResource:withExtension:subdirectory:)` mencari subdirektori nyata di dalam bundle; kalau ditambahkan sebagai group, file-nya diratakan ke root bundle dan tidak akan ketemu.

---

## Spesifikasi teknis

| Aspek | Nilai | Alasan |
|---|---|---|
| **Tinggi** | ±0.30 m | Skala meja. Lebih besar terasa mengintimidasi di ruang sempit, lebih kecil tidak terbaca dari jarak berdiri. |
| **Pivot / origin** | tengah telapak kaki, di `(0, 0, 0)` | Kode menempelkan kreatur langsung ke anchor permukaan. Pivot di tengah badan membuat kreatur setengah tenggelam di lantai. |
| **Sumbu atas** | **Y-up** | RealityKit memakai Y-up; Blender memakai Z-up. Wajib dikonversi saat ekspor. Lihat catatan di bawah. |
| **Arah hadap** | menghadap **−Z** | Konvensi RealityKit. Kreatur otomatis diputar menghadap kamera; kalau arah hadapnya salah, dia akan membelakangi pemain terus. |
| **Skala unit** | 1 unit = 1 meter | USD memakai `metersPerUnit`. Pastikan skala scene Blender = 1.0. |
| **Budget** | ≤ 10.000 tris | Target iPhone 11. Sesi AR sudah berat; ini bukan tempat memamerkan poligon. |
| **Tekstur** | opsional, ≤ 1024×1024 | Ukuran bundle. Warna utama datang dari tint, bukan dari tekstur. |

---

## Kontrak material — bagian yang paling mudah salah

Kreatur diwarnai dari **warna benda asli yang di-scan**. Gelas biru menghasilkan kreatur biru. Supaya itu bisa terjadi:

1. Mesh badan utama **harus diberi nama node `Body`** (persis, huruf besar B).
2. Material `Body` harus **putih polos** (base color 1,1,1). Kode mengganti materialnya, jadi warna apa pun yang kamu pasang akan hilang — putih membuat preview di Blender mendekati hasil akhir.
3. Bagian yang **tidak** boleh ikut diwarnai — mata, gigi, ornamen — taruh sebagai node terpisah dengan nama apa pun **selain** `Body`. Node itu mempertahankan material aslinya.

Pencocokan dilakukan pada **nama node**, bukan nama material. Nama node selamat dari ekspor USD lewat tool mana pun; nama material tidak selalu terbaca konsisten dari RealityKit.

Lihat `USDZVisualProvider.applyTint(_:to:)` untuk implementasi persisnya.

---

## Animasi (opsional)

Kalau ada, beri nama klip persis seperti ini:

- `idle` — loop, ±2 detik
- `attack` — sekali jalan, ≤1 detik
- `hurt` — sekali jalan, ≤0.5 detik

Kalau tidak ada klip animasi, kode tetap menerapkan bobbing naik-turun seperti pada versi prosedural, jadi kreatur tidak akan diam mati.

---

## Ekspor dari Blender

1. **Skala:** Scene Properties ▸ Units ▸ Unit Scale = 1.0, Length = Meters.
2. **Terapkan transform:** `Ctrl+A` ▸ All Transforms, agar tidak ada skala tersisa di object data.
3. **Ekspor:** File ▸ Export ▸ Universal Scene Description.
4. **Konversi sumbu:** cari opsi orientasi di panel ekspor USD dan pastikan hasilnya **Y-up**. Ini satu-satunya bagian yang perlu kamu verifikasi sekali di versi Blender-mu sendiri — perilaku default opsi ini berubah antar rilis, jadi jangan diasumsikan.
5. **Kalau `.usdz` tidak ada di daftar format:** ekspor `.usdc`, lalu di Mac konversi dengan Reality Converter (gratis dari Apple), atau lewat terminal:
   ```
   xcrun usdzconvert aqua.usdc aqua.usdz
   ```

---

## Cara memverifikasi hasilnya

1. Taruh satu file, misal `aqua.usdz`, di `ScanToSummon/App/Resources/Creatures/`.
2. Jalankan di iPhone, scan sebuah gelas atau botol.
3. Yang harus terlihat: kreatur bermodel, **berwarna mengikuti warna gelasmu**, berdiri di permukaan (bukan tenggelam atau melayang), menghadap kamera.

Kalau muncul kreatur prosedural, file tidak ditemukan — hampir selalu karena folder `Creatures` ditambahkan sebagai group kuning, bukan folder reference biru.

Kalau kreatur muncul tapi warnanya tidak berubah saat scan benda berwarna lain, node badannya tidak bernama `Body`.
