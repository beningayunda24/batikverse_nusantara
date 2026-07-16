# BATIKVERSE NUSANTARA
### Know → Love → Preserve

Platform edukasi batik Indonesia berbasis AI — Proyek Penelitian Informatika Universitas Gunadarma.

---

## Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| **Eksplorasi Motif** | 22 motif batik lengkap dengan sejarah, filosofi, makna |
| **Detail Motif** | Informasi mendalam: harga, warna, acara, kelangkaan |
| **Batik Finder** | Rekomendasi motif berdasarkan budget, acara, warna |
| **Perbandingan** | Bandingkan 2 motif batik secara berdampingan |
| **Klasifikasi AI** | Identifikasi motif dari foto (MobileNetV2) |
| **Riwayat Prediksi** | 50 klasifikasi terbaru pengguna |

---

## Stack Teknologi

- **Frontend:** HTML5, CSS3, JavaScript (Vanilla)
- **Backend:** Python Flask
- **Database:** MySQL 8.0+
- **ML:** TensorFlow 2.x, MobileNetV2
- **Deployment:** Render + Railway/Aiven MySQL

---

## Struktur Direktori

```
batikverse/
├── app.py                  # Flask application (routes + logic)
├── schema.sql              # MySQL schema + seed data (20 motif)
├── requirements.txt        # Python dependencies
├── Procfile                # Render/Railway deployment
├── .env.example            # Environment variables template
├── models/
│   ├── model_batik_mobilenetv2.h5   # TF model (letakkan di sini)
│   └── class_labels.npy             # Class labels array
├── uploads/                # Gambar upload pengguna (auto-created)
├── static/
│   ├── css/main.css        # Stylesheet utama
│   ├── js/main.js          # JavaScript utama
│   └── images/             # Gambar statis
└── templates/
    ├── base.html           # Layout dasar
    ├── index.html          # Beranda
    ├── eksplorasi.html     # Eksplorasi motif
    ├── detail.html         # Detail motif
    ├── finder.html         # Batik Finder
    ├── compare.html        # Perbandingan motif
    ├── predict.html        # Klasifikasi AI
    ├── history.html        # Riwayat prediksi
    └── 404.html            # Error page
```

---

## Setup Lokal

### 1. Clone & Install

```bash
git clone <repo-url>
cd batikverse
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
pip install tensorflow-cpu==2.16.1   # atau tensorflow==2.16.1
```

### 2. Konfigurasi Environment

```bash
cp .env.example .env
# Edit .env: isi DB_HOST, DB_USER, DB_PASSWORD, SECRET_KEY
```

### 3. Setup Database

```bash
mysql -u root -p < schema.sql
```

### 4. Tambahkan Model AI (opsional)

```
models/
├── model_batik_mobilenetv2.h5
└── class_labels.npy
```

Pastikan `class_labels.npy` berisi array 20 label sesuai urutan output model:
```python
import numpy as np
labels = ['Betawi', 'Bokor Kencono', 'Buketan', 'Dayak', 'Jlamprang',
          'Kawung', 'Liong', 'Mega Mendung', 'Parang', 'Sekar Jagad',
          'Sidoluhur', 'Sidomukti', 'Sidomulyo', 'Singa Barong', 'Srikaton',
          'Tribusono', 'Tujuh Rupa', 'Truntum', 'Wahyu Tumurun', 'Wirasat']
np.save('models/class_labels.npy', labels)
```

### 5. Jalankan

```bash
python app.py
# Buka: http://localhost:5000
```

---

## Deployment ke Render

1. Push ke GitHub
2. Buat **Web Service** baru di [render.com](https://render.com)
3. Connect repo → Render akan otomatis detect `render.yaml`
4. Tambahkan environment variables di dashboard Render
5. Database: gunakan [Railway](https://railway.app) atau [Aiven](https://aiven.io) MySQL gratis

---

## 20 Motif yang Didukung

```
Betawi · Bokor Kencono · Buketan · Dayak · Jlamprang
Kawung · Liong · Mega Mendung · Parang · Sekar Jagad
Sidoluhur · Sidomukti · Sidomulyo · Singa Barong · Srikaton
Tribusono · Tujuh Rupa · Truntum · Wahyu Tumurun · Wirasat
```

---

## Tim & Kredit

**Proyek Penelitian Informatika**  
Universitas Gunadarma

Model MobileNetV2 diadaptasi dari arsitektur Google dengan fine-tuning pada dataset batik Indonesia.

---

*"Dari pengetahuan lahir kecintaan. Dari kecintaan tumbuh pelestarian."*
