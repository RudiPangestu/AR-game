# Scan-to-Summon

[![iOS](https://github.com/RudiPangestu/AR-game/actions/workflows/ios.yml/badge.svg)](https://github.com/RudiPangestu/AR-game/actions/workflows/ios.yml)

Game AR iPhone: arahkan kamera ke benda nyata di rumahmu, benda itu dikenali di perangkat, lalu "menetas" jadi kreatur yang bisa dikoleksi dan diadu.

Gelas kopi jadi kreatur air. Sepatu jadi kreatur cepat. Scan gelas yang sama besok — kreaturnya tetap sama persis.

**Tidak butuh LiDAR.** Jalan di semua iPhone 11 ke atas, bukan hanya model Pro.

---

## Butuh apa

- macOS dengan **Xcode 16** atau lebih baru
- iPhone dengan **iOS 17+** untuk menguji AR (Simulator tidak punya kamera)

## Menjalankan

```bash
open ScanToSummon/ScanToSummon.xcodeproj
```

Pilih scheme `ScanToSummon`, jalankan di iPhone fisik.

Kalau project file bermasalah saat dibuka, `project.yml` adalah sumber kebenarannya dan bisa menghasilkan ulang project yang benar:

```bash
brew install xcodegen
cd ScanToSummon && xcodegen generate
```

## Menjalankan test

```bash
cd ScanToSummon
xcodebuild test -scheme ScanToSummon \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Test mencakup seluruh `Core/` — pemetaan label, determinisme, type chart, resolusi pertarungan, persistensi Kodeks. Semuanya Swift murni tanpa dependensi ARKit, jadi bisa dijalankan di Simulator.

**App sengaja tetap berfungsi di Simulator.** Layar Scan menampilkan "AR butuh iPhone sungguhan", tapi Kodeks dan Tarung tetap jalan, dan tombol scan menghasilkan kreatur sintetis supaya alur lain bisa diiterasi tanpa device. Kode itu di-compile keluar dari build perangkat nyata.

---

## Struktur

```
ScanToSummon/
  App/        entry point, navigasi, resource, String Catalog (en + id)
  Core/       Swift murni — model, pemetaan, stat, pertarungan, penyimpanan
              (tidak boleh import ARKit/RealityKit/UIKit/SwiftUI)
  AR/         ARKit, RealityKit, Vision, visual provider, efek menetas
  Features/   layar SwiftUI: Scan, Kodeks, Tarung
  Tests/      unit test untuk seluruh Core/
docs/
  brainstorm-ar-game-iphone.md   10 ide AR yang dinilai, dan kenapa ini yang dipilih
  scan-to-summon-design.md       desain gameplay, rumus, angka tuning
  creature-asset-spec.md         kontrak aset USDZ untuk kerja Blender nanti
```

Aturan `Core/` tidak boleh mengimpor framework UI bukan gaya-gayaan — itulah yang membuat logika game bisa diuji tanpa simulator dan tanpa kamera.

---

## Cara kerjanya

1. **Klasifikasi** — `VNClassifyImageRequest` dari Vision, di perangkat, ~1300 kategori, tanpa bundling model dan tanpa jaringan.
2. **Pemetaan** — label diurai dari kata terakhir, karena "coffee table" itu meja dan "teddy bear" itu beruang. Tidak cocok → archetype `void`, dibingkai sebagai penemuan, bukan error.
3. **Stat deterministik** — seed dari label lewat FNV-1a. `hashValue` Swift tidak dipakai karena di-seed ulang tiap proses, yang akan diam-diam merusak janji "benda yang sama = kreatur yang sama". Warna sengaja tidak ikut menentukan identitas — hanya tint — karena warna rata-rata bergeser mengikuti cahaya.
4. **Menetas** — telur muncul di permukaan, retak dua kali, lalu meletus. ±2.2 detik, dengan haptics.
5. **Tarung** — turn-based 3v3 di layar 2D biasa. Sengaja bukan AR: inilah lapisan yang bisa dimainkan sambil rebahan.

## Kreatur 3D

Sekarang semuanya prosedural — tubuh dirakit dari sphere dan box di kode, diwarnai dari warna benda yang di-scan.

Model buatan tangan bisa menggantikannya kapan saja tanpa mengubah kode: taruh `Creatures/<archetype>.usdz` di bundle dan loader otomatis memilihnya. Prosedural tetap jadi fallback permanen, bukan sekadar placeholder — kreatur tetap perlu diwarnai per hasil scan. Kontrak asetnya ada di [`docs/creature-asset-spec.md`](docs/creature-asset-spec.md).

---

## Status

MVP tahap awal. Yang belum ada, dan alasannya, tercatat di [`docs/scan-to-summon-design.md`](docs/scan-to-summon-design.md).
