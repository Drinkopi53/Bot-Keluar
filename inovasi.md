# Ide Inovasi untuk Mengimprovisasi Kemampuan Bots Survivor dalam Menghadapi Tank

Berikut adalah 20 ide inovasi beserta penjelasan lengkap dan detail untuk meningkatkan kemampuan bots survivor dalam menghadapi Tank, dengan fokus pada improvisasi fungsionalitas yang sudah ada pada `left4bots`:

## 1. Prioritas Target Otomatis
*   **Konsep:** Memperkuat logika dalam `Left4Bots.FindBotNearestEnemy` dan `Left4Bots.HasTanksWithin` untuk memastikan Tank selalu menjadi prioritas tertinggi.
*   **Implementasi:** Saat `Left4Bots.HasTanksWithin` mengembalikan entitas Tank, semua bot akan segera mengalihkan target mereka ke Tank. Ini dapat dilakukan dengan menambahkan `order` prioritas tinggi ke antrean bot atau langsung memanipulasi `scope.AimType` dan `scope.AimTarget` bot untuk menargetkan Tank. Pengecualian untuk Special Infected yang mengancam nyawa rekan tim dapat diintegrasikan dengan memeriksa `Left4Bots.SurvivorsHeldOrIncapped()` sebelum sepenuhnya mengunci target Tank.

## 2. Fokus Serangan Terkoordinasi
*   **Konsep:** Mengembangkan mekanisme koordinasi serangan di antara bot.
*   **Implementasi:** Setelah Tank terdeteksi, satu bot (misalnya, bot dengan `flow` terdepan atau yang memiliki pandangan terbaik) dapat ditunjuk sebagai "pemimpin target". Bot ini akan mengirimkan `order` atau `context` yang berisi entitas Tank ke bot lain. Bot lain kemudian akan menggunakan `Left4Bots.BotShootAtEntity` untuk menembak Tank yang sama. Ini memerlukan penambahan logika komunikasi antar-bot atau sistem `order` baru yang mendukung target bersama.

## 3. Penggunaan Molotov/Incendiary Otomatis
*   **Konsep:** Memperbaiki logika `Left4Bots.GetThrowTarget` untuk Molotov/Incendiary.
*   **Implementasi:** Saat `Left4Bots.GetNearestVisibleTankWithin` mendeteksi Tank, bot dengan Molotov/Incendiary akan memprioritaskan penggunaan item tersebut. Logika `Settings.tank_molotov_chance` dan `Settings.tank_throw_range_min/max` sudah ada, tetapi dapat dioptimalkan untuk memastikan penggunaan yang lebih cerdas, termasuk penilaian risiko `AreOtherSurvivorsNearby` yang lebih ketat.

## 4. Penggunaan Bom Pipa/Bile Otomatis (Pengalihan)
*   **Konsep:** Memperbaiki logika `Left4Bots.GetThrowTarget` untuk Pipe Bomb/Bile Bomb.
*   **Implementasi:** Saat `Left4Bots.HasAngryCommonsWithin` mendeteksi gerombolan Common Infected di sekitar Tank, bot akan menggunakan Pipe Bomb atau Bile Bomb. Untuk Pipe Bomb, target lemparan dapat diatur ke posisi yang jauh dari Tank menggunakan `Left4Utils.BotGetFarthestPathablePos`. Untuk Bile Bomb, dapat dilemparkan langsung ke Tank atau area sekitarnya, dengan mempertimbangkan `Settings.tank_vomitjar_chance`.

## 5. Posisi Bertahan Adaptif
*   **Konsep:** Memperluas logika pergerakan bot untuk posisi taktis.
*   **Implementasi:** Saat Tank muncul, bot akan menggunakan `NavMesh.GetNavArea` dan `Left4Bots.TryDodge` untuk mencari posisi yang aman. Ini melibatkan pergerakan lateral (`leftVector`) dan penggunaan penutup. Logika ini dapat diperluas untuk secara aktif mencari `cover` (objek dengan `CONTENTS_SOLID` atau `CONTENTS_BLOCKLOS`) dan menghindari area sempit yang rentan.

## 6. Mundur Taktis
*   **Konsep:** Mengembangkan logika mundur yang cerdas.
*   **Implementasi:** Jika Tank terlalu dekat (`GetDistanceToEntityAABB` < jarak aman) atau bot dalam kondisi HP rendah, bot akan memicu `BotHighPriorityMove` ke arah yang berlawanan dari Tank. Selama mundur, bot akan tetap menembak menggunakan `Left4Bots.BotShootAtEntity` dan menjaga `scope.AimType` tetap pada Tank.

## 7. Prioritas Penyelamatan Rekan
*   **Konsep:** Memperkuat prioritas penyelamatan rekan dari Tank.
*   **Implementasi:** Fungsi `Left4Bots.SpecialGotSurvivor` akan diperluas untuk tidak hanya mem-pause bot yang terjebak, tetapi juga memicu bot lain untuk segera menargetkan Tank yang menyerang rekan. Ini bisa melibatkan `Left4Bots.BotShootAtEntity` pada Tank atau bahkan `Left4Bots.PlayerPressButton` untuk `shove` jika Tank berada dalam jarak `melee` dari rekan yang diserang.

## 8. Penggunaan Senjata Berat Prioritas
*   **Konsep:** Mengoptimalkan pemilihan senjata bot saat Tank muncul.
*   **Implementasi:** Dalam `Left4Bots.EnforcePrimaryWeapon` atau dalam logika pemilihan senjata bot, tambahkan kondisi yang memprioritaskan `weapon_chainsaw`, `weapon_m60`, `weapon_autoshotgun`, atau `weapon_shotgun_spas` saat Tank terdeteksi. Bot akan secara otomatis beralih ke senjata ini menggunakan `bot.SwitchToItem()`.

## 9. Manajemen Amunisi Cerdas
*   **Konsep:** Meningkatkan efisiensi penggunaan amunisi.
*   **Implementasi:** Bot akan mempertimbangkan `Left4Utils.GetAmmoPercent` dari senjata aktif mereka. Saat menghadapi Tank, bot akan mengurangi tembakan sembarangan dan hanya menembak saat `CanTraceTo` Tank. Logika pengisian ulang amunisi dapat ditambahkan untuk mencari momen aman (misalnya, saat Tank tidak `aggroed` pada bot tersebut atau sedang dalam animasi serangan).

## 10. Pemanfaatan Lingkungan
*   **Konsep:** Memperluas interaksi bot dengan objek lingkungan yang dapat meledak.
*   **Implementasi:** Bot akan menggunakan `Left4Bots.FindNearestUsable` untuk mengidentifikasi `prop_physics` seperti tabung propana atau mobil alarm (`prop_car_alarm`) di dekat Tank. Jika Tank berada dalam jangkauan ledakan, bot akan memprioritaskan menembak objek tersebut menggunakan `Left4Bots.BotShootAtEntity` untuk memberikan *damage* area.

## 11. Peringatan Suara/Visual
*   **Konsep:** Meningkatkan sistem peringatan Tank.
*   **Implementasi:** Saat `Left4Bots.HasTanksWithin` mendeteksi Tank, `Left4Bots.SpeakRandomVocalize` akan dipicu dengan `concept` khusus Tank (misalnya, "PlayerAlertTank"). Jika memungkinkan, integrasi dengan sistem HUD (seperti `Left4Hud.AddHud`) dapat digunakan untuk menampilkan ikon atau panah arah Tank.

## 12. Strategi "Kite" (Mengulur)**
*   **Konsep:** Mengembangkan peran "kiter" di antara bot.
*   **Implementasi:** Satu bot (mungkin yang paling cepat atau memiliki HP tinggi) dapat diberi `order` "kite_tank". Bot ini akan menggunakan `BotHighPriorityMove` untuk menjaga jarak optimal dari Tank sambil terus menembak. Logika ini akan berinteraksi dengan `Left4Bots.GetNearestAggroedTankWithin` untuk memastikan bot tetap menjadi target Tank.

## 13. Penggunaan Medkit/Pills Cerdas
*   **Konsep:** Mengoptimalkan penggunaan item medis saat melawan Tank.
*   **Implementasi:** Logika dalam `Left4Bots.BotWillUseMeds` akan diperluas untuk mempertimbangkan ancaman Tank. Jika bot atau rekan tim dalam bahaya kritis dari Tank, penggunaan Medkit/Pills akan diprioritaskan. Bot akan mencari momen aman (`!Left4Bots.HasAggroedTankWithin`) untuk menggunakan item.

## 14. Prioritas Revive/Heal Rekan
*   **Konsep:** Memperkuat prioritas `revive`/`heal` rekan saat Tank aktif.
*   **Implementasi:** Fungsi `Left4Bots.CancelReviveAndThrowNade` dan `Left4Bots.CheckHealingTarget` akan diperluas. Jika rekan `incapacitated` atau terluka parah, bot akan menilai keamanan menggunakan `HasAngryCommonsWithin` atau `HasSpecialInfectedWithin` sebelum melakukan `revive`/`heal`. Bot lain akan memberikan `cover fire` menggunakan `Left4Bots.BotShootAtEntity`.

## 15. Deteksi Kelemahan Tank
*   **Konsep:** Jika API game memungkinkan, bot akan menargetkan titik lemah Tank.
*   **Implementasi:** Jika `NetProps` atau `LookupBone` dapat mengidentifikasi titik lemah pada model Tank (misalnya, `ValveBiped.Bip01_Spine1` untuk punggung), `Left4Bots.BotShootAtEntityAttachment` akan digunakan untuk menargetkan titik tersebut. Ini akan memerlukan penambahan logika ke `Left4Bots.FindBotNearestEnemy` untuk memprioritaskan titik lemah.

## 16. Formasi Pertahanan
*   **Konsep:** Mengembangkan logika formasi bot.
*   **Implementasi:** Saat Tank muncul, bot akan mencoba menyebar secara cerdas menggunakan `BotHighPriorityMove` untuk menghindari serangan area Tank. Jika ada pemain manusia, bot akan mencoba menjaga posisi yang melindungi pemain manusia, mungkin dengan menggunakan `Left4Bots.AreOtherSurvivorsNearby` untuk menjaga jarak relatif.

## 17. Penggunaan Melee untuk Dorongan
*   **Konsep:** Mengintegrasikan dorongan `melee` sebagai taktik bertahan.
*   **Implementasi:** Jika Tank berada dalam jarak `melee` yang sangat dekat (`GetDistanceToEntityAABB` < jarak `melee`), bot akan memicu `BUTTON_SHOVE` menggunakan `Left4Bots.PlayerPressButton` untuk mendorong Tank menjauh dan menciptakan ruang.

## 18. Adaptasi Terhadap Perilaku Tank
*   **Konsep:** Mengimplementasikan adaptasi sederhana terhadap pola serangan Tank.
*   **Implementasi:** Bot dapat melacak frekuensi lemparan batu Tank atau tingkat agresinya. Jika Tank sering melempar batu, bot akan lebih sering memicu `Left4Bots.TryDodge` atau mencari `cover`. Ini bisa melibatkan penyesuaian dinamis pada `Settings.dodge_charger_diffangle` atau `Settings.dodge_rock_diffangle` secara internal.

## 19. Komunikasi Non-Verbal Lanjutan
*   **Konsep:** Memanfaatkan `context` dan `SpeakResponseConcept` untuk komunikasi non-verbal.
*   **Implementasi:** Selain dialog suara, bot dapat menggunakan `who.SetContext("subject", Tank, 0.1)` dan `DoEntFire("!self", "SpeakResponseConcept", "PlayerAlertTank", 0, null, who)` untuk menunjuk ke arah Tank. Jika ada API untuk gerakan tubuh, itu bisa diintegrasikan.

## 20. Sistem Pembelajaran Adaptif
*   **Konsep:** Mengimplementasikan sistem pembelajaran dasar.
*   **Implementasi:** Meskipun pembelajaran AI yang kompleks mungkin di luar cakupan, versi sederhana dapat melibatkan penyesuaian `Settings` internal bot secara dinamis. Misalnya, jika bot sering mati karena Tank, mereka dapat secara internal meningkatkan `Settings.move_wait_time` atau `Settings.manual_attack_radius` untuk menjadi lebih hati-hati atau agresif. Ini akan memerlukan penyimpanan data performa sederhana dan logika penyesuaian.
