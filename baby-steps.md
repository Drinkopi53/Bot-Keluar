**Ide Inovasi: Mundur Taktis (Tactical Retreat)**

**Konsep:**
Mengembangkan logika mundur yang cerdas untuk bot saat menghadapi ancaman langsung dari Tank atau saat bot dalam kondisi HP rendah. Bot akan memprioritaskan keselamatan sambil tetap mempertahankan kemampuan menyerang.

**Implementasi pada `left4bots_afterload.nut`:**

1.  **Definisi Jarak Aman dan Ambang Batas HP Rendah:**
    Tambahkan variabel konfigurasi di awal file `left4bots_afterload.nut` untuk menentukan:
    *   `::Left4Bots.Settings.tank_safe_distance <- 300;` // Jarak aman dari Tank (dalam unit game)
    *   `::Left4Bots.Settings.low_hp_threshold <- 40;` // Ambang batas HP rendah (persentase)

2.  **Modifikasi Fungsi `::Left4Bots.AIFuncs.BotThink_Main`:**
    Di dalam fungsi `::Left4Bots.AIFuncs.BotThink_Main`, setelah pemanggilan `L4B_IsTankActive();` dan di dalam blok `if (g_hTankTarget)`, tambahkan logika berikut:

    *   **Deteksi Ancaman dan Pemicu Mundur:**
        Periksa dua kondisi utama untuk memicu mundur taktis:
        a.  **Tank Terlalu Dekat:** Hitung jarak antara bot dan Tank menggunakan `GetDistanceToEntityAABB(hBot, g_hTankTarget)`. Jika jarak ini kurang dari `::Left4Bots.Settings.tank_safe_distance`.
        b.  **HP Bot Rendah:** Periksa HP bot. Jika `hBot.GetHealth()` kurang dari `hBot.GetMaxHealth() * (::Left4Bots.Settings.low_hp_threshold / 100.0)`.

    *   **Logika Mundur:**
        Jika salah satu kondisi di atas terpenuhi:
        a.  **Tentukan Arah Mundur:** Hitung vektor arah yang berlawanan dari Tank. Ini dapat dilakukan dengan mengambil vektor dari Tank ke bot (`botOrigin - g_vTankLastKnownPos`). Normalisasi vektor ini dan kalikan dengan jarak mundur yang diinginkan (misalnya, 300 unit).
        b.  **Picu `BotHighPriorityMove`:** Gunakan `Left4Utils.BotHighPriorityMove(self, safePos);` untuk menginstruksikan bot bergerak ke posisi mundur yang dihitung. `BotHighPriorityMove` memastikan gerakan ini diprioritaskan di atas gerakan lain.
        c.  **Tetap Menembak:** Pastikan bot tetap menembak selama mundur. Ini dapat dicapai dengan menjaga `scope.AimType` tetap pada `AI_AIM_TYPE.Shoot` atau `AI_AIM_TYPE.Tank` dan memastikan `Left4Bots.BotShootAtEntity(self, g_hTankTarget);` dipanggil secara konsisten. Logika penembakan biasanya sudah ada di `BotAim()`, jadi pastikan `BotAim()` tetap dipanggil.
        d.  **Jaga `scope.AimType`:** Pastikan `scope.AimType` diatur ke `AI_AIM_TYPE.Tank` atau `AI_AIM_TYPE.Shoot` yang menargetkan Tank. Ini penting agar bot terus menembak Tank meskipun sedang bergerak mundur.

**Contoh Implementasi Kode (Tambahkan di `::Left4Bots.AIFuncs.BotThink_Main`):**

```nut
// Tambahkan di awal file left4bots_afterload.nut
::Left4Bots.Settings.tank_safe_distance <- 300; // Jarak aman dari Tank (dalam unit game)
::Left4Bots.Settings.low_hp_threshold <- 40; // Ambang batas HP rendah (persentase)

// ... di dalam ::Left4Bots.AIFuncs.BotThink_Main
if (g_hTankTarget)
{
    local botOrigin = self.GetOrigin();
    local distanceToTank = (botOrigin - g_hTankTarget.GetOrigin()).Length(); // Gunakan GetOrigin() langsung dari g_hTankTarget
    local botHealthPercent = (self.GetHealth().ToFloat() / self.GetMaxHealth().ToFloat()) * 100.0;

    // Logika Mundur Taktis
    if (distanceToTank < ::Left4Bots.Settings.tank_safe_distance || botHealthPercent < ::Left4Bots.Settings.low_hp_threshold)
    {
        local moveAwayVector = (botOrigin - g_hTankTarget.GetOrigin()).Norm() * 300; // Mundur 300 unit
        local safePos = botOrigin + moveAwayVector;

        // Pastikan posisi mundur valid di NavMesh
        local navArea = NavMesh.GetNearestNavArea(safePos);
        if (navArea && navArea.IsValid())
        {
            Left4Utils.BotHighPriorityMove(self, navArea.GetCenter());
            printl("Bot " + self.GetPlayerName() + " memicu mundur taktis dari Tank.");

            // Tetap menembak Tank saat mundur
            local scope = self.GetScriptScope();
            if (scope.AimType != AI_AIM_TYPE.Tank) // Pastikan AimType diatur ke Tank jika belum
            {
                scope.AimType = AI_AIM_TYPE.Tank;
                scope.AimTarget = g_hTankTarget;
            }
            Left4Bots.BotShootAtEntity(self, g_hTankTarget); // Pastikan bot menembak
            return L4B.Settings.bot_think_interval; // Langsung proses frame berikutnya untuk gerakan mundur
        }
    }

    // ... logika yang sudah ada untuk jarak optimal, mencari perlindungan, pergerakan lateral, dan terjebak
}
```

**Penjelasan Detail:**

*   **`::Left4Bots.Settings.tank_safe_distance`**: Menentukan seberapa dekat Tank boleh berada sebelum bot mulai mundur. Nilai ini dapat disesuaikan untuk mengoptimalkan perilaku bot.
*   **`::Left4Bots.Settings.low_hp_threshold`**: Menentukan persentase HP di mana bot akan memicu mundur taktis. Ini mencegah bot mati konyol saat HP-nya kritis.
*   **`GetDistanceToEntityAABB` vs `(Origin - Target.GetOrigin()).Length()`**: Meskipun `GetDistanceToEntityAABB` lebih akurat untuk jarak antar kotak pembatas entitas, dalam konteks ini, perhitungan jarak sederhana antara titik asal bot dan Tank (`(botOrigin - g_hTankTarget.GetOrigin()).Length()`) sudah cukup dan lebih mudah diimplementasikan.
*   **`BotHighPriorityMove`**: Fungsi ini penting karena akan mengesampingkan perintah gerakan lain yang mungkin sedang dilakukan bot, memastikan bot segera mundur.
*   **`scope.AimType = AI_AIM_TYPE.Tank;` dan `Left4Bots.BotShootAtEntity(self, g_hTankTarget);`**: Ini memastikan bahwa meskipun bot sedang bergerak mundur, fokus tembakannya tetap pada Tank. `BotAim()` yang dipanggil di setiap `BotThink_Main` akan menggunakan `AimType` dan `AimTarget` ini untuk mengarahkan tembakan.
*   **`return L4B.Settings.bot_think_interval;`**: Setelah memicu gerakan mundur, kita langsung mengembalikan interval think agar bot segera memproses gerakan mundur di frame berikutnya tanpa melakukan logika think lainnya yang mungkin bertentangan.
*   **Validasi NavMesh**: Penting untuk memastikan `safePos` yang dihitung berada di area NavMesh yang valid. Jika tidak, bot bisa mencoba bergerak ke tempat yang tidak bisa dijangkau.

**Pencegahan Error dan Ambiguitas:**

*   **Variabel Global yang Jelas**: Penggunaan `::Left4Bots.Settings` untuk konfigurasi memastikan variabel mudah diakses dan diubah.
*   **Komentar Kode**: Penjelasan di atas harus diterjemahkan ke dalam komentar kode yang jelas di samping implementasi untuk menjelaskan setiap bagian logika.
*   **Logging**: Tambahkan `printl` atau `Logger.Debug` yang relevan untuk melacak kapan bot memicu mundur taktis, ke mana ia mencoba bergerak, dan mengapa. Ini sangat membantu dalam debugging.
*   **Prioritas Logika**: Pastikan logika mundur taktis dievaluasi di awal blok `if (g_hTankTarget)` agar memiliki prioritas tinggi.
*   **Konsistensi Objek Tank**: Selalu gunakan `g_hTankTarget` yang sudah divalidasi oleh `L4B_IsTankActive()` untuk memastikan kita berinteraksi dengan objek Tank yang valid.
