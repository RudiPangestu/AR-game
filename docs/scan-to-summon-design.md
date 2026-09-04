# Scan-to-Summon — Desain & Tuning

Dokumen kerja untuk keputusan gameplay. Untuk kenapa ide ini yang dipilih dari sepuluh kandidat, lihat `brainstorm-ar-game-iphone.md`.

---

## Pertanyaan yang sedang dijawab MVP ini

> Apakah momen "scan benda → kreatur menetas" cukup seru sampai orang mau scan benda berikutnya **tanpa disuruh**?

Semua keputusan di bawah tunduk pada pertanyaan itu. Fitur yang tidak membantu menjawabnya sengaja tidak dibangun.

---

## Loop

```
Scan (berdiri, 30 detik)  →  Menetas (3 detik, momen "wow")
        ↓
Kodeks (rebahan)  →  Tarung (rebahan, 2 menit)  →  besok scan lagi
```

Tarung sengaja **bukan di AR**. Itu langsung menjalankan temuan utama dokumen brainstorm: game AR murni mati di hari ketiga karena tangan pegal, jadi lapisan yang bikin orang kembali harus bisa dimainkan satu tangan sambil rebahan.

---

## Determinisme: keputusan desain paling penting

Scan gelas yang sama dua kali → **kreatur yang persis sama**.

Ini bukan optimisasi teknis, ini fondasi fantasi. Kalau tiap scan menghasilkan kreatur acak, benda di rumahmu tidak punya identitas dan app-nya cuma mesin gacha berlapis kamera. Dengan determinisme, gelas birumu **adalah** Aqualin, selamanya.

Konsekuensi yang harus dijaga:

| Konsekuensi | Penanganan |
|---|---|
| Tidak ada yang bisa di-reroll | Scan ulang memberi +6% stat per duplikat, mentok di 10× (Lv 11, ×1.6) |
| Perubahan cahaya kecil bisa mengubah warna rata-rata | Warna dikuantisasi ke 8 bucket per kanal sebelum masuk signature |
| `hashValue` Swift di-seed per proses | Dipakai FNV-1a buatan sendiri (`StableHash`), bukan hash bawaan |

Uji `DeterminismTests.testSameScanProducesIdenticalCreature` menjaga janji ini. Kalau tes itu merah, desainnya yang rusak, bukan cuma kodenya.

---

## Archetype vs Element

Dua konsep terpisah, dan pemisahan ini yang membuat sistemnya tidak meledak:

- **Archetype (12)** — rasa dan tampilan. Menentukan bentuk tubuh, nama, dan base stat.
- **Element (6)** — hanya untuk tempur. Beberapa archetype berbagi element.

Type chart jadi cukup dua kalimat:

```
ember → verdant → aqua → ember
ferro → air   → void → ferro
```

Pertarungan antar-cincin selalu netral. Dengan begitu pemain hafal seluruh chart setelah satu pertandingan, bukan setelah membuka wiki.

Pengali: kuat ×1.5, lemah ×0.67.

---

## Rumus damage

```
raw       = ATK × pengali_move × pengali_tipe
mitigated = raw × 100 / (100 + DEF)
damage    = max(1, mitigated × acak(0.9…1.1))
```

- `move` Basic ×1.0, Surge ×1.85 dengan cooldown 3 giliran
- Mitigasi berbasis rasio, bukan pengurangan, supaya DEF tinggi tetap awet tapi tidak pernah kebal
- Lantai damage 1 memastikan pertarungan selalu selesai — `BattleEngineTests.testBattleAlwaysTerminates` menjaga ini untuk 50 seed

Dengan stat rata-rata (ATK ~25, DEF ~20, HP ~110), satu pukulan ≈ 21 damage, sekitar 5 pukulan per kreatur, total ±15–18 giliran. Kira-kira dua menit.

**Sustain untuk tipe lambat.** Surge dari element `aqua` dan `verdant` menyerap 30% damage yang dihasilkan. Keduanya adalah element bertahan; tanpa ini tim lambat tidak punya jalan menang selain menunggu.

---

## Lawan

`AITeamBuilder` menyusun tim dari kekuatan roster pemain, bukan dari tangga level tetap:

- Satu lawan selalu dipilih untuk **meng-counter element dominan** pemain, jadi pertarungan terasa dirancang, bukan acak
- Dua sisanya bervariasi supaya bukan tembok satu element
- Total power diskalakan ke 0.95× rata-rata pemain — sedikit di bawah, karena MVP ini sedang mencari tahu apakah loop-nya seru, dan kalah di pertarungan pertama adalah cara buruk untuk mengetahuinya

---

## Menangani kesalahan klasifikasi

`VNClassifyImageRequest` akan sering salah. Itu diterima sebagai bagian desain, bukan bug yang harus disembunyikan.

- Ambang confidence rendah (0.10) — kreatur yang salah tapi masuk akal lebih menyenangkan daripada penolakan
- Sampai 5 tebakan teratas dicoba sebelum menyerah
- Tidak ada yang cocok → archetype `void`, dibingkai sebagai penemuan ("Tak terbaca — ada yang menyelinap"), bukan error
- Label mentah **ditampilkan** ke pemain. Melihat "Coffee Mug → Aqualin" adalah sebagian besar alasan scan terasa seperti mesinnya benar-benar mengerti — dan saat salah, kesalahannya jadi lelucon, bukan kegagalan

**Pembacaan kata dari belakang.** Label majemuk diurai dari kata terakhir: "coffee table" itu meja, "water bottle" itu botol, "teddy bear" itu beruang. Membaca dari depan salah di ketiganya.

---

## Angka yang paling mungkin perlu di-tuning

Semuanya terkumpul di `Core/`, tanpa perlu menyentuh UI:

| Angka | Lokasi | Sekarang |
|---|---|---|
| Ambang confidence | `ArchetypeMapper.confidenceThreshold` | 0.10 |
| Varians stat | `StatDeriver.variance` | 0.18 |
| Bonus duplikat | `Creature.effectiveStats` | +6%, mentok 10 |
| Pengali tipe | `TypeChart` | 1.5 / 0.67 |
| Pengali Surge & cooldown | `Move` | 1.85 / 3 |
| Kesulitan lawan | `AITeamBuilder.difficulty` | 0.95 |
| Jeda giliran lawan | `BattleViewModel.turnDelay` | 0.7 dtk |
| Durasi menetas | `HatchEffect` | ±2.2 dtk |

---

## Yang tidak dibangun, dan alasannya

| Tidak ada | Alasan |
|---|---|
| Multiplayer | Mahal, dan bukan itu yang sedang divalidasi |
| Evolusi, daily quest, leaderboard | Memoles retensi di atas loop yang belum terbukti seru |
| Audio | Tidak ada cara membuat file suara dari lingkungan build ini — diganti haptics, yang justru mengerjakan sebagian besar kerja "terasa fisik" |
| App icon | Sama; AppIcon set kosong, hanya memunculkan warning |
| Persistensi anchor AR | Kreatur menetas lalu hilang saat scan berikutnya. Menyimpan posisinya di rumah adalah ide "peliharaan menetap" yang berbeda |

---

## Gate keputusan

Setelah 5 orang mencoba: **apakah ada yang scan benda kedua tanpa disuruh?**

Kalau tidak — perbaiki momen menetasnya (timing, haptics, kejutan). Jangan tambah fitur. Menambahkan evolusi di atas loop yang datar hanya membuat kegagalannya lebih mahal untuk ditemukan.
