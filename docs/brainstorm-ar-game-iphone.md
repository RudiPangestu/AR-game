# Brainstorming: Game AR untuk iPhone

Dokumen kerja untuk menentukan konsep game AR yang akan dibangun. Fokus: iPhone, native iOS.

---

## 1. Realita yang harus dipatuhi (biar idenya nggak ngawang)

Ini yang membunuh 90% game AR mobile. Semua ide di bawah dinilai dengan constraint ini.

| Constraint | Implikasi desain |
|---|---|
| **Gorilla arm** — tangan pegal angkat HP setelah ~3 menit | Sesi inti harus 2–5 menit. Jangan bikin match 15 menit. |
| **Malu di tempat umum** | Desain untuk main di rumah/kamar, bukan di mall. Jangan wajibkan gerakan lebar. |
| **Ruang sempit** | Harus jalan di ruang 2×2 m. Jangan asumsi living room Amerika. |
| **Baterai & panas** | AR kontinu = throttling setelah ~10–15 menit. Batasi durasi, dan turunkan frame budget. |
| **Retensi** | Game AR murni hampir selalu "wow sekali, lalu hapus". **Ini masalah nomor satu.** |
| **Tracking gagal** | Ruang gelap, dinding polos, lantai reflektif = tracking hilang. Butuh recovery yang tidak menghukum pemain. |

**Insight paling penting:** jangan bikin game yang 100% AR. Struktur yang berhasil = **AR sebagai "momen"** (2–4 menit, berdiri, wow) **+ meta-layer non-AR** (upgrade, koleksi, leaderboard, base building) yang bisa dimainkan sambil rebahan satu tangan. Meta-layer inilah yang bikin orang buka app di hari ke-7.

---

## 2. Kapabilitas iPhone yang layak dieksploitasi

Pilih ide yang **memakai sesuatu dari daftar ini secara esensial**. Kalau idenya cuma "model 3D di atas meja", itu bukan game AR — itu 3D viewer.

- **Scene Reconstruction (mesh ruangan)** — ARKit, **butuh LiDAR**. Geometri ruangan jadi collider. Ini yang paling game-changing.
- **RoomPlan** (iOS 16+, **LiDAR**) — hasilnya bukan cuma mesh, tapi label semantik: ini dinding, ini pintu, ini sofa, ini meja. Bisa dipakai buat level design otomatis.
- **Plane detection** — jalan di semua device, tanpa LiDAR. Ini fallback wajib.
- **People Occlusion** (A12+, tanpa LiDAR) — objek virtual bisa ketutup badan pemain. Murah, efeknya besar.
- **Face tracking / TrueDepth** — party game, filter, ekspresi sebagai input.
- **Image & object anchor** — kartu fisik, poster, atau benda tertentu jadi trigger.
- **Multipeer collaborative session** — dua iPhone melihat objek AR yang sama di meja yang sama. Lokal, latensi rendah.
- **Vision framework** — klasifikasi benda nyata on-device (mug, sepatu, tanaman...).
- **Persistent anchor (ARWorldMap)** — objek AR tetap di posisi yang sama besok pagi.
- ~~**Location Anchor / GeoAnchor**~~ — hanya tersedia di sebagian kota (mayoritas AS/Eropa/Jepang). **Jakarta tidak didukung.** Jangan dipakai; kalau mau game lokasi, pakai GPS + peta biasa ala Pokémon Go.

### Peringatan device: LiDAR itu eksklusif model Pro

LiDAR hanya ada di iPhone **12/13/14/15/16 Pro & Pro Max**. Non-Pro (termasuk 16e, SE, semua model reguler) **tidak punya**. Di pasar Indonesia, ini memotong audiens sangat besar.

**Aturan:** boleh mendesain mekanik yang bersinar di device LiDAR, tapi game **harus tetap bisa dimainkan** dengan plane detection saja. Kalau sebuah ide mati tanpa LiDAR, ide itu berisiko tinggi.

---

## 3. Kandidat ide

### A. Room Raiders — tower defense di kamar sendiri
Musuh keluar dari dinding & bawah pintu asli kamu, jalan mengikuti lantai asli, dan **terhalang furnitur asli**. Kamu pasang turret di atas meja/rak beneran dengan cara mengarahkan HP. Kamu harus muter badan buat lihat serangan dari arah belakang.

- **Kenapa AR-native:** denah rumah pemain = level design. Tiap pemain punya map unik, dan itu gratis. Nggak bisa dibikin di game biasa.
- **Kuat:** replayable (pindah ruangan = map baru), sesi 3 menit pas, meta-layer upgrade turret gampang ditempel, screenshot-able.
- **Risiko:** paling bagus dengan LiDAR/RoomPlan. Fallback non-LiDAR = musuh spawn dari tepi bidang lantai yang terdeteksi — masih jalan, tapi kurang magis.
- **Effort:** sedang. Ini kandidat terkuat.

### B. Scan-to-Summon — benda di rumahmu jadi monster
Arahkan kamera ke benda nyata, app mengklasifikasi (Vision), lalu benda itu "menetas" jadi kreatur dengan stat sesuai jenisnya. Gelas → elemental air. Sepatu → kreatur cepat. Tanaman → tipe grass. Lalu bertarung/koleksi.

- **Kenapa AR-native:** kamera jadi *input mekanik*, bukan cuma jendela. Loop-nya "keliling rumah nyari bahan".
- **Kuat:** paling viral. Orang otomatis pengen scan barang aneh dan pamer hasilnya. Koleksi = retensi.
- **Risiko:** kualitas klasifikasi. Kalau sering salah tebak, ilusinya pecah. Mitigasi: jangan klaim akurat — bungkus sebagai "mesin sihir yang suka salah baca", dan sediakan ~40 kategori umum + fallback lucu untuk yang tak dikenali.
- **Effort:** sedang. Tidak butuh LiDAR sama sekali → jangkauan device paling luas.

### C. Tabletop Arena — board game 2 pemain di satu meja
Dua iPhone, satu meja, collaborative session. Keduanya melihat arena yang sama dari sudut masing-masing. Genre: auto-battler / catur taktis / tower rush.

- **Kenapa AR-native:** "duduk berhadapan di meja yang sama" adalah pengalaman yang layar datar tidak punya.
- **Kuat:** risiko teknis paling rendah, retensi ditentukan kualitas game-nya (bukan kualitas AR-nya). Aman.
- **Risiko:** butuh dua orang yang hadir fisik — akuisisi user susah. Nilai AR-nya "hanya" presentasi.
- **Effort:** sedang–besar (desain game strategi yang seimbang itu mahal).

### D. Micro Racers — balap RC di lantai rumah
Mobil mini balapan di lantai asli; kaki meja, sepatu, dan karpet jadi rintangan. Mesh ruangan jadi dinding sirkuit.

- **Kuat:** HP dipegang setinggi pinggang (nggak pegal), instan dimengerti, multiplayer lokal enak.
- **Risiko:** butuh lantai lapang. Fisika mobil di mesh kasar itu susah dibikin enak.
- **Effort:** sedang.

### E. Penunggu Rumah — hantu/peliharaan yang menetap
Objek AR di-anchor permanen di satu titik rumah (ARWorldMap). Dia "hidup" di situ: lapar, tumbuh, kirim notifikasi. Widget & Live Activity di home screen sebagai meta-layer.

- **Kuat:** retensi terbaik dari semua ide (habit harian). Sesi sangat pendek → nggak pegal.
- **Risiko:** relokalisasi ARWorldMap sering gagal kalau pencahayaan/tata ruang berubah. Butuh flow "pasang ulang" yang tidak menyakitkan. Gameplay-nya tipis kalau berdiri sendiri.
- **Effort:** kecil–sedang. Bagus sebagai **lapisan retensi** yang ditempel ke ide A atau B, bukan sebagai game utuh.

### F. Ide lain (dicatat, tidak diprioritaskan)
- **Portal di dinding** — efek "wow" luar biasa, tapi tipis sebagai game. Pakai sebagai set-piece/intro di dalam ide lain.
- **Escape room di rumah sendiri** — seru sekali, tapi konten sekali pakai; biaya produksi per jam-main sangat mahal.
- **Party game face-tracking** — murah dan lucu, tapi kompetitornya padat.
- **Fitness/tinju body-tracking** — HP harus disandarkan, kalibrasi ribet, ruang gerak besar. Skip.
- **Rhythm game a la Beat Saber** — pegal parah dalam 90 detik. Skip.

---

## 4. Perbandingan tiga teratas

| | A. Room Raiders | B. Scan-to-Summon | C. Tabletop Arena |
|---|---|---|---|
| AR benar-benar esensial | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Jangkauan device (tanpa LiDAR) | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Potensi viral | ⭐⭐ | ⭐⭐⭐ | ⭐ |
| Retensi D7 | ⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Risiko teknis | sedang | sedang (ML) | rendah |
| Bisa solo dev | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

---

## 5. Rekomendasi

**Bangun A (Room Raiders) sebagai inti, dan pinjam retensi dari E.**

Alasannya: A adalah satu-satunya ide yang mengubah *ruangan pemain menjadi konten*. Itu memberi variasi level tanpa biaya produksi level — hal yang paling mahal untuk tim kecil. Sesi 3 menitnya juga secara alami cocok dengan batas fisik AR.

Kalau prioritasnya **viral dan jangkauan device maksimal** (misalnya target pasar Indonesia yang mayoritas non-Pro), pilih **B** — B tidak butuh LiDAR sama sekali.

### Loop yang dituju
1. **Scan ruangan** (30 dtk, sekali per ruangan, disimpan).
2. **Wave defense** (3 menit, berdiri, muter badan).
3. **Meta non-AR** (2 menit, rebahan): upgrade turret, buka kartu, cek leaderboard.
4. Notifikasi besok: "Ruanganmu diserbu lagi."

### MVP 4 minggu (target: tahu ini seru atau nggak)
- **Minggu 1** — Scan ruangan + visualisasi mesh, deteksi lantai/dinding, fallback plane-only. *Gate: tracking stabil 5 menit di 3 ruangan berbeda.*
- **Minggu 2** — Satu tipe musuh, pathfinding di lantai nyata, satu turret yang bisa ditaruh, tap-to-shoot. *Gate: satu wave bisa dimenangkan.*
- **Minggu 3** — 3 wave, 3 turret, HP/kalah/menang, occlusion, audio spasial. *Gate: 5 orang main; ada yang minta main lagi tanpa disuruh?*
- **Minggu 4** — Meta-layer upgrade + retry, polish, TestFlight.

Kalau di akhir minggu 3 nggak ada yang minta main ulang, buang konsepnya. Jangan lanjut ke polish.

---

## 6. Tech stack

**Rekomendasi: Swift + RealityKit + ARKit (native).**

- Paling ringan di baterai/termal, akses paling cepat ke API baru (RoomPlan, scene reconstruction, occlusion), ukuran app kecil, dan tidak ada lisensi.
- Cocok kalau targetnya memang cuma iPhone.

**Pakai Unity + AR Foundation kalau:** butuh iterasi gameplay/visual yang cepat, mau pakai Asset Store, sudah punya tim Unity, atau nanti mau porting ke Android.

Pegangan: **AR-nya lebih dalam → native menang. Gameplay/kontennya lebih berat → Unity menang.** Untuk Room Raiders, AR-nya dalam → native.

Target minimum: **iOS 17, iPhone 11 ke atas** (A13+, sudah dapat People Occlusion). LiDAR = jalur "enhanced", bukan syarat.

---

## 7. Yang harus dihindari

- Menganggap AR sebagai fitur jualan. Pemain tidak peduli itu AR; mereka peduli itu seru.
- Onboarding yang menyuruh pemain "gerakkan HP perlahan" lebih dari 20 detik. Banyak yang keluar di sini.
- Menghukum pemain saat tracking hilang. Pause, jangan game over.
- Mekanik yang butuh jongkok, lompat, atau mundur cepat — bahaya, pemain nabrak barang.
- Bergantung pada GeoAnchor (tidak tersedia di Indonesia).
- Multiplayer online sebagai fitur MVP. Mahal, dan bukan itu yang sedang divalidasi.

---

## 8. Langkah berikutnya

1. Pilih arah: **A** (default) atau **B** (kalau prioritas jangkauan device & viral).
2. Bikin spike 3 hari: scan ruangan + taruh 1 kubus yang terhalang furnitur asli. Itu sudah cukup untuk membuktikan fondasi teknisnya.
3. Baru setelah spike lolos, mulai MVP 4 minggu di atas.
