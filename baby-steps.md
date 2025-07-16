# Sistem Navigasi Bot yang Ditingkatkan (Enhanced Bot Navigation System - Dynamic Pathfinding)

**Catatan untuk Agen AI:** Implementasikan ide inovasi ini ke dalam file `left4bots_afterload.nut` saja. Jangan memodifikasi file lainnya.

## Tujuan Inovasi
Meningkatkan algoritma pathfinding bot agar mereka dapat menemukan jalur yang lebih optimal, menghindari rintangan dinamis (misalnya, pintu yang tertutup, area yang diblokir oleh musuh), dan beradaptasi dengan perubahan lingkungan secara real-time, mengurangi insiden bot yang terjebak atau melakukan rute yang tidak efisien.

## Baby Steps

1.  **Analisis Pathfinding Bot yang Ada**:
    *   Pelajari kode pathfinding bot yang ada di proyek `left4bots`.
    *   Identifikasi keterbatasan dan area yang menyebabkan bot terjebak atau mengambil rute yang tidak efisien.

2.  **Riset Algoritma Pathfinding Dinamis**:
    *   Teliti algoritma pathfinding yang lebih canggih seperti A*, D* Lite, atau algoritma berbasis navmesh yang dapat menangani rintangan dinamis.
    *   Pahami bagaimana game lain menangani navigasi AI dalam lingkungan yang berubah.

3.  **Implementasi Deteksi Rintangan Dinamis**:
    *   Kembangkan sistem untuk mendeteksi rintangan yang muncul atau berubah di lingkungan (misalnya, pintu yang dibuka/ditutup, objek yang bergerak, area yang diblokir oleh Special Infected).
    *   Pastikan sistem ini dapat mengidentifikasi jenis rintangan dan dampaknya terhadap navigasi.

4.  **Integrasi Algoritma Pathfinding Baru**:
    *   Mulai implementasikan algoritma pathfinding yang dipilih ke dalam kerangka kerja bot.
    *   Fokus pada kemampuan bot untuk menghitung ulang jalur secara cepat ketika rintangan dinamis terdeteksi.

5.  **Pengujian dan Debugging Awal**:
    *   Uji bot di berbagai skenario dengan rintangan dinamis untuk melihat bagaimana mereka beradaptasi.
    *   Identifikasi dan perbaiki bug atau perilaku yang tidak diinginkan.

6.  **Optimasi Kinerja**:
    *   Pastikan algoritma pathfinding baru tidak menyebabkan penurunan kinerja game yang signifikan, terutama dalam skenario dengan banyak bot atau rintangan.
    *   Lakukan optimasi kode jika diperlukan.

7.  **Peningkatan Adaptasi Lingkungan**:
    *   Ajarkan bot untuk tidak hanya menghindari rintangan, tetapi juga memanfaatkan lingkungan (misalnya, mencari jalan memutar yang aman, menggunakan celah, atau menunggu rintangan hilang).
    *   Pertimbangkan perilaku bot saat menghadapi musuh yang memblokir jalur.

8.  **Integrasi dengan AI Director**:
    *   Jelajahi bagaimana AI Director dapat memberikan informasi tentang perubahan lingkungan atau memicu perilaku navigasi tertentu pada bot.

9.  **Pengujian Skala Penuh**:
    *   Uji sistem navigasi yang ditingkatkan dalam permainan penuh dengan banyak bot dan pemain di berbagai peta.
    *   Kumpulkan umpan balik dari penguji untuk penyempurnaan lebih lanjut.

10. **Dokumentasi dan Kustomisasi**:
    *   Dokumentasikan implementasi baru dan berikan opsi kustomisasi bagi pengguna untuk menyesuaikan parameter navigasi bot.

## Perbaikan Error Konsol Left 4 Dead 2

### Detail Error dan Solusi

**Error:** `AN ERROR HAS OCCURED [the index 'GetPlayerForwardVector' does not exist]`
**Lokasi:** `scripts/vscripts/left4bots_afterload.nut` baris 484

**Penyebab:**
Error ini menunjukkan bahwa fungsi `GetPlayerForwardVector()` yang dipanggil pada objek `bot` (yang merupakan instance dari entitas pemain) tidak tersedia atau tidak dikenali dalam konteks Squirrel (bahasa scripting Left 4 Dead 2). Ini kemungkinan besar karena:
1.  Fungsi tersebut tidak ada dalam API Squirrel yang diekspos untuk entitas pemain.
2.  Nama fungsi salah ketik atau tidak sesuai dengan konvensi penamaan yang benar.
3.  Objek `bot` bukan tipe yang diharapkan yang memiliki fungsi tersebut.

**Solusi yang Disarankan (untuk implementasi di `left4bots_afterload.nut`):**

Karena `GetPlayerForwardVector()` tidak tersedia, kita perlu mencari cara alternatif untuk mendapatkan vektor maju bot. Beberapa pendekatan yang mungkin:

1.  **Menggunakan `bot.GetAbsAngles()` dan mengonversinya ke vektor:**
    Jika bot memiliki properti sudut absolut, kita bisa mendapatkan sudut yaw (rotasi horizontal) dan mengonversinya menjadi vektor arah. Ini adalah metode umum dalam game engine.
    Contoh pseudo-code:
    ```squirrel
    local angles = bot.GetAbsAngles();
    local forward = AngleVectors(angles); // Asumsi ada fungsi AngleVectors yang mengonversi sudut ke vektor
    ```
    Anda mungkin perlu mencari fungsi yang setara dengan `AngleVectors` dalam API Squirrel Left 4 Dead 2 atau mengimplementasikannya secara manual menggunakan trigonometri.

2.  **Menggunakan `bot.GetViewVector()` atau `bot.GetAimVector()`:**
    Beberapa game engine menyediakan fungsi untuk mendapatkan vektor arah pandang atau arah bidik pemain. Ini mungkin lebih sesuai jika tujuannya adalah untuk mengetahui ke mana bot "melihat".
    Contoh pseudo-code:
    ```squirrel
    local forward = bot.GetViewVector(); // Atau GetAimVector()
    ```
    Periksa dokumentasi API Squirrel Left 4 Dead 2 untuk fungsi-fungsi semacam ini.

3.  **Menggunakan `NavMesh` atau `Path` terkait informasi arah:**
    Jika bot sedang mengikuti jalur navigasi, mungkin ada cara untuk mendapatkan arah segmen jalur berikutnya dari `NavMesh` yang sedang diikuti bot. Ini akan memberikan arah pergerakan bot.

**Penting:**
Perbaikan sebenarnya harus dilakukan di file `left4bots_afterload.nut` dengan mengganti baris yang bermasalah (baris 484) dengan implementasi yang benar berdasarkan API yang tersedia. Dokumentasi ini hanya memberikan panduan untuk perbaikan tersebut.
