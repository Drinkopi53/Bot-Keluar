# Rencana Pengembangan: Posisi Bertahan Adaptif untuk Bots Survivor

Dokumen ini merinci langkah-langkah pengembangan fitur "Posisi Bertahan Adaptif" untuk bots survivor dalam menghadapi Tank, dengan fokus pada implementasi yang bertahap dan terperinci.

## Konsep Fitur

Bots akan secara cerdas menyesuaikan posisi mereka di medan perang untuk menjaga jarak aman dari Tank sambil tetap mempertahankan garis tembak yang jelas. Ini melibatkan pergerakan lateral, penggunaan penutup, dan menghindari terjebak di sudut.

## Prioritas Pengembangan

1.  **Jarak Optimal:** Bot akan berusaha menjaga jarak optimal dari Tank.
2.  **Pergerakan Lateral:** Bots akan bergerak secara lateral (menyamping) untuk menghindari serangan langsung Tank.
3.  **Penggunaan Penutup:** Bot akan secara otomatis mencari dan menggunakan penutup terdekat yang terlihat.
4.  **Hindari Terjebak:** AI bot akan memiliki logika untuk menghindari terjebak di sudut atau area sempit.

## Diagram Alur Kerja Umum

```mermaid
graph TD
    A[Mulai: Pahami Konsep & Kode Eksisting] --> B{Deteksi Tank Aktif?};
    B -- Ya --> C[Perbarui Logika Jarak Optimal];
    C --> D[Implementasi Penggunaan Penutup Dasar];
    D --> E[Kembangkan Pergerakan Lateral];
    E --> F[Perbaiki Logika Hindari Terjebak];
    F --> G[Uji & Sempurnakan];
    G -- Selesai --> H[Dokumentasikan];
    B -- Tidak --> I[Tunggu Deteksi Tank];
    I --> B;
```

## Daftar Tugas (To-Do List)
