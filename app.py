import os, uuid
import numpy as np
from datetime import datetime
from functools import wraps
from flask import (Flask, render_template, request, redirect,
                   url_for, flash, session, send_from_directory, abort)
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
from mysql.connector import Error

# ── TF import (optional) ──────────────────────────────────────────────────────
try:
    import tensorflow as tf
    from tensorflow.keras.models import load_model # type: ignore
    from preprocessing import preprocess_image
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False

# ═════════════════════════════════════════════════════════════════════════════
#  APP CONFIG
# ═════════════════════════════════════════════════════════════════════════════
app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'batikverse-secret-dev-2025')
app.config['UPLOAD_FOLDER']       = '/tmp/uploads'
app.config['MAX_CONTENT_LENGTH']  = 16 * 1024 * 1024
app.config['ALLOWED_EXTENSIONS']  = {'png', 'jpg', 'jpeg', 'webp'}

DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'database': os.environ.get('DB_NAME', 'batikverse_db'),
    'user': os.environ.get('DB_USER', 'root'),
    'password': os.environ.get('DB_PASSWORD', ''),
    'port': int(os.environ.get('DB_PORT', 3306)),
    'charset': 'utf8mb4',
    'collation': 'utf8mb4_unicode_ci',
    'ssl_disabled': False
}

# ═════════════════════════════════════════════════════════════════════════════
#  MODEL CONFIG — sesuaikan dengan class_labels.npy dari model yang dilatih
# ═════════════════════════════════════════════════════════════════════════════
MODEL_PATH         = os.path.join('models', 'model_batik_mobilenetv2.keras')
CLASS_LABELS_PATH  = os.path.join('models', 'class_labels.npy')
CONFIDENCE_THRESHOLD = 0.70

# Label model → nama tampilan (sesuaikan dengan output class_labels.npy)
LABEL_TO_NAME = {
    'Bali_Barong':               'Batik Barong',
    'Jakarta_OndelOndel':        'Batik Ondel-Ondel',
    'Jakarta_Tumpal':            'Batik Tumpal',
    'JawaBarat_MegaMendung':     'Batik Mega Mendung',
    'JawaTengah_Jlamprang':      'Batik Jlamprang',
    'JawaTengah_Truntum':        'Batik Truntum',
    'JawaTimur_Gentongan':       'Batik Gentongan',
    'JawaTimur_Pring':           'Batik Pring',
    'Yogyakarta_Kawung':         'Batik Kawung',
    'Yogyakarta_ParangRusak':    'Batik Parang Rusak',
    'Kalimantan_Dayak':          'Batik Dayak',
    'KalimantanBarat_Insang':    'Batik Insang',
    'SumateraBarat_RumahMinang': 'Batik Rumah Minang',
    'SumateraUtara_Boraspati':   'Batik Boraspati',
    'SumateraUtara_PintuAceh':   'Batik PintuAceh',
    'Lampung_Gajah':             'Batik Gajah',
    'Lampung_Bledheg':           'Batik Bledheg',
    'SulawesiSelatan_Lontara':   'Batik Lontara',
    'Papua_Asmat':               'Batik Asmat',
    'Papua_Cendrawasih':         'Batik Cendrawasih',
    'Maluku_Pala':               'Batik Pala',
    'NTB_Lumbung':               'Batik Lumbung',
    'non_batik':                 'Bukan Batik',
}
VALID_MOTIF_LABELS = [k for k in LABEL_TO_NAME if k != 'non_batik']

_model        = None
_class_labels = None

def load_ml_model():
    global _model, _class_labels
    if not TF_AVAILABLE:
        print("TensorFlow tidak tersedia. Klasifikasi AI dinonaktifkan.")
        return
    if os.path.exists(MODEL_PATH):
        try:
            _model = load_model(MODEL_PATH)
            if os.path.exists(CLASS_LABELS_PATH):
                _class_labels = np.load(CLASS_LABELS_PATH, allow_pickle=True).tolist()
            print(f"Model loaded: {MODEL_PATH}")
            print(f"Labels: {_class_labels}")
        except Exception as e:
            print(f"Model load error: {e}")
    else:
        print(f"Model tidak ditemukan: {MODEL_PATH}")

# ═════════════════════════════════════════════════════════════════════════════
#  DATABASE HELPERS
# ═════════════════════════════════════════════════════════════════════════════
def get_db():
    try:
        return mysql.connector.connect(**DB_CONFIG)
    except Error as e:
        print(f"DB error: {e}")
        return None

def query(sql, params=None, one=False):
    conn = get_db()
    if not conn:
        return None
    try:
        cur = conn.cursor(dictionary=True)
        cur.execute(sql, params or ())
        return cur.fetchone() if one else cur.fetchall()
    except Error as e:
        print(f"Query error: {e}")
        return None
    finally:
        conn.close()

def execute(sql, params=None):
    conn = get_db()
    if not conn:
        return False, None
    try:
        cur = conn.cursor()
        cur.execute(sql, params or ())
        conn.commit()
        return True, cur.lastrowid
    except Error as e:
        print(f"Execute error: {e}")
        conn.rollback()
        return False, None
    finally:
        conn.close()

# ═════════════════════════════════════════════════════════════════════════════
#  AUTH HELPERS
# ═════════════════════════════════════════════════════════════════════════════
def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if 'user_id' not in session:
            flash('Silakan login terlebih dahulu untuk mengakses fitur ini.', 'warning')
            return redirect(url_for('login', next=request.url))
        return f(*args, **kwargs)
    return decorated

def current_user():
    if 'user_id' not in session:
        return None
    return query("SELECT id_user, nama, email, foto_profil, tanggal_daftar FROM users WHERE id_user=%s",
                 (session['user_id'],), one=True)

@app.context_processor
def inject_user():
    return {'current_user': current_user()}

# ═════════════════════════════════════════════════════════════════════════════
#  UPLOAD / AI HELPERS
# ═════════════════════════════════════════════════════════════════════════════
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

def predict_batik(img_path):
    if not TF_AVAILABLE or _model is None or _class_labels is None:
        return None
    try:
        arr = preprocess_image(img_path)
        preds = _model.predict(arr, verbose=0)[0]
        top3_idx = np.argsort(preds)[::-1][:3]

        top3 = [{
            'label':      LABEL_TO_NAME.get(_class_labels[i], _class_labels[i]),
            'raw_label':  _class_labels[i],
            'confidence': float(preds[i]),
            'percentage': round(float(preds[i]) * 100, 2),
        } for i in top3_idx]

        best_raw  = _class_labels[top3_idx[0]]
        best_name = LABEL_TO_NAME.get(best_raw, best_raw)
        best_conf = float(preds[top3_idx[0]])
        is_nonbatik = (best_raw == 'non_batik')
        is_valid    = (best_raw in VALID_MOTIF_LABELS and best_conf >= CONFIDENCE_THRESHOLD)

        return {
            'predicted':    best_name if is_valid else None,
            'raw_label':    best_raw,
            'confidence':   best_conf,
            'top3':         top3,
            'is_valid':     is_valid,
            'is_non_batik': is_nonbatik,
        }
    except Exception as e:
        print(f"Prediction error: {e}")
        return None

# ═════════════════════════════════════════════════════════════════════════════
#  ROUTES — PUBLIC
# ═════════════════════════════════════════════════════════════════════════════
@app.route('/')
def index():
    total_motif    = query("SELECT COUNT(*) c FROM motif", one=True)
    total_prediksi = query("SELECT COUNT(*) c FROM prediksi", one=True)
    highlights = query("""
    SELECT
        m.id_motif,
        m.nama_motif,
        m.asal_daerah,
        m.pulau,
        m.filosofi,
        m.tingkat_kelangkaan,
        g.gambar
    FROM motif m
    LEFT JOIN galeri_motif g
    ON m.id_motif = g.id_motif
    AND g.urutan = 0
    ORDER BY RAND()
    LIMIT 3
    """)
    return render_template('index.html',
        total_motif    = total_motif['c']    if total_motif    else 0,
        total_prediksi = total_prediksi['c'] if total_prediksi else 0,
        highlights     = highlights or [])

# ── LOGIN ─────────────────────────────────────────────────────────────────────
@app.route('/login', methods=['GET','POST'])
def login():
    if 'user_id' in session:
        return redirect(url_for('index'))
    if request.method == 'POST':
        email = request.form.get('email','').strip().lower()
        pwd   = request.form.get('password','')
        user  = query("SELECT * FROM users WHERE email=%s AND is_active=1", (email,), one=True)
        if user and check_password_hash(user['password_hash'], pwd):
            session['user_id']   = user['id_user']
            session['user_nama'] = user['nama']
            flash(f"Selamat datang kembali, {user['nama']}!", 'success')
            next_url = request.args.get('next')
            return redirect(next_url if next_url else url_for('index'))
        flash('Email atau password salah.', 'error')
    return render_template('login.html')

# ── REGISTER ──────────────────────────────────────────────────────────────────
@app.route('/register', methods=['GET','POST'])
def register():
    if 'user_id' in session:
        return redirect(url_for('index'))
    if request.method == 'POST':
        nama   = request.form.get('nama','').strip()
        email  = request.form.get('email','').strip().lower()
        pwd    = request.form.get('password','')
        pwd2   = request.form.get('confirm_password','')
        if not nama or not email or not pwd:
            flash('Semua kolom wajib diisi.', 'error')
        elif pwd != pwd2:
            flash('Konfirmasi password tidak cocok.', 'error')
        elif len(pwd) < 6:
            flash('Password minimal 6 karakter.', 'error')
        else:
            existing = query("SELECT id_user FROM users WHERE email=%s", (email,), one=True)
            if existing:
                flash('Email sudah terdaftar. Silakan login.', 'error')
            else:
                hashed = generate_password_hash(pwd)
                ok, uid = execute(
                    "INSERT INTO users (nama,email,password_hash) VALUES (%s,%s,%s)",
                    (nama, email, hashed))
                if ok:
                    # buat preferensi default
                    execute("INSERT INTO user_preferences (id_user) VALUES (%s)", (uid,))
                    session['user_id']   = uid
                    session['user_nama'] = nama
                    flash(f'Akun berhasil dibuat. Selamat datang, {nama}!', 'success')
                    return redirect(url_for('index'))
                flash('Gagal membuat akun. Coba lagi.', 'error')
    return render_template('register.html')

# ── LOGOUT ───────────────────────────────────────────────────────────────────
@app.route('/logout')
def logout():
    session.clear()
    flash('Anda telah keluar dari akun.', 'success')
    return redirect(url_for('index'))

# ── PROFIL ───────────────────────────────────────────────────────────────────
@app.route('/profil', methods=['GET','POST'])
@login_required
def profil():
    user  = current_user()
    prefs = query("SELECT * FROM user_preferences WHERE id_user=%s",
                  (session['user_id'],), one=True)
    if request.method == 'POST':
        action = request.form.get('action','')
        if action == 'update_profil':
            nama = request.form.get('nama','').strip()
            if nama:
                execute("UPDATE users SET nama=%s WHERE id_user=%s",
                        (nama, session['user_id']))
                session['user_nama'] = nama
                flash('Profil berhasil diperbarui.', 'success')
        elif action == 'update_password':
            old_pwd = request.form.get('old_password','')
            new_pwd = request.form.get('new_password','')
            cnf_pwd = request.form.get('confirm_password','')
            full    = query("SELECT password_hash FROM users WHERE id_user=%s",
                            (session['user_id'],), one=True)
            if not full or not check_password_hash(full['password_hash'], old_pwd):
                flash('Password lama salah.', 'error')
            elif new_pwd != cnf_pwd:
                flash('Konfirmasi password baru tidak cocok.', 'error')
            elif len(new_pwd) < 6:
                flash('Password baru minimal 6 karakter.', 'error')
            else:
                execute("UPDATE users SET password_hash=%s WHERE id_user=%s",
                        (generate_password_hash(new_pwd), session['user_id']))
                flash('Password berhasil diubah.', 'success')
        elif action == 'update_prefs':
            warna    = request.form.get('warna_favorit','')
            jenis    = request.form.get('jenis_batik','semua')
            anggaran = request.form.get('anggaran','semua')
            acara    = request.form.get('acara_favorit','')
            wilayah  = request.form.get('wilayah_favorit','')
            fil_kw   = request.form.get('filosofi_kw','')
            if prefs:
                execute("""UPDATE user_preferences
                           SET warna_favorit=%s, jenis_batik=%s, anggaran=%s,
                               acara_favorit=%s, wilayah_favorit=%s, filosofi_kw=%s
                           WHERE id_user=%s""",
                        (warna,jenis,anggaran,acara,wilayah,fil_kw,session['user_id']))
            else:
                execute("""INSERT INTO user_preferences
                           (id_user,warna_favorit,jenis_batik,anggaran,acara_favorit,wilayah_favorit,filosofi_kw)
                           VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                        (session['user_id'],warna,jenis,anggaran,acara,wilayah,fil_kw))
            flash('Preferensi berhasil disimpan.', 'success')
        return redirect(url_for('profil'))

    # Statistik pengguna
    stats = query("""SELECT
        COUNT(*) total,
        SUM(CASE WHEN hasil_prediksi != 'Tidak dikenali' THEN 1 ELSE 0 END) berhasil
        FROM prediksi WHERE id_user=%s""", (session['user_id'],), one=True)
    return render_template('profil.html', user=user, prefs=prefs, stats=stats)

# ── EKSPLORASI ───────────────────────────────────────────────────────────────
@app.route('/motif')
def eksplorasi():
    q        = request.args.get('q','').strip()
    pulau    = request.args.get('pulau','').strip()
    provinsi = request.args.get('provinsi','').strip()
    warna    = request.args.get('warna','').strip()
    jenis    = request.args.get('jenis','').strip()
    harga    = request.args.get('harga','').strip()

    # Menggunakan Subquery untuk mengambil 1 gambar saja dari galeri_motif
    sql = """
    SELECT
        m.*,
        (SELECT g.gambar FROM galeri_motif g WHERE g.id_motif = m.id_motif LIMIT 1) AS gambar
    FROM motif m
    WHERE 1=1
    """
    params = []
    
    if q:
        sql += " AND (m.nama_motif LIKE %s OR m.asal_daerah LIKE %s OR m.filosofi LIKE %s)"
        like = f"%{q}%"
        params += [like, like, like]
        
    if pulau:
        sql += " AND m.pulau = %s"
        params.append(pulau)
        
    if provinsi:
        sql += " AND m.provinsi LIKE %s"
        params.append(f"%{provinsi}%")
        
    if warna:
        sql += " AND m.warna_dominan LIKE %s"
        params.append(f"%{warna}%")
        
    if jenis:
        sql += " AND m.jenis_batik LIKE %s"
        params.append(f"%{jenis}%")
        
    if harga == 'murah':
        sql += " AND m.harga_cap_min < 100000"
    elif harga == 'sedang':
        sql += " AND m.harga_cap_min BETWEEN 100000 AND 500000"
    elif harga == 'mahal':
        sql += " AND m.harga_cap_min > 500000"
        
    sql += " ORDER BY m.pulau, m.nama_motif"

    motifs    = query(sql, params) or []
    
    pulaus    = query("SELECT DISTINCT pulau FROM motif WHERE pulau IS NOT NULL ORDER BY pulau") or []
    provinsis = query("SELECT DISTINCT provinsi FROM motif WHERE provinsi IS NOT NULL ORDER BY provinsi") or []
    warnas    = query("SELECT DISTINCT warna_dominan FROM motif WHERE warna_dominan IS NOT NULL ORDER BY warna_dominan") or []

    return render_template('eksplorasi.html',
        motifs=motifs, pulaus=pulaus, provinsis=provinsis, warnas=warnas,
        search=q, selected_pulau=pulau, selected_provinsi=provinsi,
        selected_warna=warna, selected_jenis=jenis, selected_harga=harga)

# ── DETAIL MOTIF ──────────────────────────────────────────────────────────────
@app.route('/motif/<int:id_motif>')
def detail_motif(id_motif):
    motif  = query("SELECT * FROM motif WHERE id_motif=%s", (id_motif,), one=True)
    if not motif:
        flash('Motif tidak ditemukan.', 'error')
        return redirect(url_for('eksplorasi'))
    galeri  = query("SELECT * FROM galeri_motif WHERE id_motif=%s ORDER BY urutan", (id_motif,)) or []
    related = query("""SELECT id_motif,nama_motif,asal_daerah,pulau FROM motif
                       WHERE pulau=%s AND id_motif!=%s ORDER BY RAND() LIMIT 3""",
                    (motif.get('pulau',''), id_motif)) or []
    return render_template('detail.html', motif=motif, galeri=galeri, related=related)

# ── BATIK FINDER ──────────────────────────────────────────────────────────────
@app.route('/finder', methods=['GET','POST'])
def finder():
    results, form_data, alasan = [], {}, {}

    # Pre-fill dari preferensi pengguna jika login
    prefs = None
    if 'user_id' in session:
        prefs = query("SELECT * FROM user_preferences WHERE id_user=%s",
                      (session['user_id'],), one=True)

    if request.method == 'POST':
        # Ambil murni apa yang diklik/diketik user di form saat itu saja
        budget    = request.form.get('budget', '')
        acara     = request.form.get('acara', '')
        warna_fav = request.form.get('warna', '').strip()
        fil_kw    = request.form.get('filosofi', '').strip()
        if warna_fav.lower() == 'none':
            warna_fav = ''
        if fil_kw.lower() == 'none':
            fil_kw = ''
        pulau     = request.form.get('pulau', '')
        provinsi  = request.form.get('provinsi', '').strip()
        jenis     = request.form.get('jenis_batik', '')
        
        form_data = dict(budget=budget, acara=acara, warna=warna_fav,
                         filosofi=fil_kw, pulau=pulau, provinsi=provinsi,
                         jenis_batik=jenis)

        sql, params = """
        SELECT m.*,
            (SELECT g.gambar FROM galeri_motif g WHERE g.id_motif = m.id_motif ORDER BY g.urutan LIMIT 1) AS gambar
        FROM motif m WHERE 1=1
        """, []
        reasons     = []

        # Tentukan kolom harga yang relevan berdasarkan jenis batik yang difilter
        if jenis == 'Tulis':
            harga_col = 'harga_tulis_min'
        elif jenis == 'Cap':
            harga_col = 'harga_cap_min'
        else:
            harga_col = None  # 'Kombinasi' atau tidak difilter -> cek kedua kolom

        if budget == 'murah':
            if harga_col:
                sql += f" AND {harga_col} < 100000"
            else:
                sql += " AND (harga_cap_min < 100000 OR harga_tulis_min < 100000)"
            reasons.append("Harga terjangkau (< Rp100.000)")
        elif budget == 'sedang':
            if harga_col:
                sql += f" AND {harga_col} BETWEEN 100000 AND 500000"
            else:
                sql += " AND (harga_cap_min BETWEEN 100000 AND 500000 OR harga_tulis_min BETWEEN 100000 AND 500000)"
            reasons.append("Harga menengah")
        elif budget == 'mahal':
            if harga_col:
                sql += f" AND {harga_col} > 500000"
            else:
                sql += " AND (harga_cap_min > 500000 OR harga_tulis_min > 500000)"
            reasons.append("Batik premium")
        
        if acara and acara.strip() != "":
            sql += " AND acara_cocok LIKE %s"
            params.append(f"%{acara}%"); reasons.append(f"Cocok untuk: {acara}")
            
        if warna_fav and warna_fav.strip() != "":
            sql += " AND warna_dominan LIKE %s"
            params.append(f"%{warna_fav}%"); reasons.append(f"Warna: {warna_fav}")
            
        if fil_kw and fil_kw.strip() != "":
            sql += " AND filosofi LIKE %s"
            params.append(f"%{fil_kw}%"); reasons.append(f"Filosofi: {fil_kw}")
            
        if pulau and pulau.strip() != "" and pulau != 'Semua Pulau':
            sql += " AND pulau = %s"
            params.append(pulau); reasons.append(f"Pulau: {pulau}")
            
        if provinsi and provinsi.strip() != "":
            sql += " AND provinsi LIKE %s"
            params.append(f"%{provinsi}%"); reasons.append(f"Provinsi: {provinsi}")
            
        if jenis and jenis.strip() != "" and jenis != 'Semua Jenis':
            sql += " AND jenis_batik LIKE %s"
            params.append(f"%{jenis}%"); reasons.append(f"Jenis: Batik {jenis}")

        sql += " ORDER BY RAND() LIMIT 3"
        
        # Cetak ke terminal buat pembuktian query aman
        print("DEBUG SQL PENCARIAN:", sql)
        print("DEBUG PARAMETER PENCARIAN:", params)

        results = query(sql, params) or []
        alasan  = ', '.join(reasons) if reasons else 'Pilihan acak dari seluruh koleksi'

        # Bersihkan data string kosong / default agar tidak mengotori database preferensi
        jenis_save = None if (not jenis or jenis == 'Semua Jenis') else jenis
        pulau_save = None if (not pulau or pulau == 'Semua Pulau') else pulau
        warna_save = None if not warna_fav else warna_fav
        budget_save = None if not budget else budget
        acara_save = None if not acara else acara
        fil_save = None if not fil_kw else fil_kw

        # Simpan preferensi jika login
        if 'user_id' in session:
            if prefs:
                execute("""UPDATE user_preferences
                           SET warna_favorit=%s, anggaran=%s, acara_favorit=%s,
                               wilayah_favorit=%s, filosofi_kw=%s, jenis_batik=%s
                           WHERE id_user=%s""",
                        (warna_save, budget_save, acara_save, pulau_save, fil_save, jenis_save, session['user_id']))
            else:
                execute("""INSERT INTO user_preferences
                           (id_user, warna_favorit, anggaran, acara_favorit, wilayah_favorit, filosofi_kw, jenis_batik)
                           VALUES (%s,%s,%s,%s,%s,%s,%s)""",
                        (session['user_id'], warna_save, budget_save, acara_save, pulau_save, fil_save, jenis_save))
            
            # Refresh data preferensi terbaru setelah di-update
            prefs = query("SELECT * FROM user_preferences WHERE id_user=%s", (session['user_id'],), one=True)

    pulaus = query("SELECT DISTINCT pulau FROM motif WHERE pulau IS NOT NULL ORDER BY pulau") or []
    return render_template('finder.html', results=results, form_data=form_data,
                           alasan=alasan, prefs=prefs, pulaus=pulaus)

# ── COMPARE ───────────────────────────────────────────────────────────────────
@app.route('/compare', methods=['GET','POST'])
def compare():
    motif_a = motif_b = region_a = region_b = None
    mode = request.form.get('mode','motif') if request.method=='POST' else request.args.get('mode','motif')
    all_motifs = query("SELECT id_motif,nama_motif,pulau FROM motif ORDER BY pulau,nama_motif") or []
    pulaus     = query("SELECT DISTINCT pulau FROM motif WHERE pulau IS NOT NULL ORDER BY pulau") or []

    if request.method == 'POST':
        if mode == 'motif':
            id_a = request.form.get('motif_a')
            id_b = request.form.get('motif_b')
            if id_a and id_b and id_a != id_b:
                motif_a = query("SELECT * FROM motif WHERE id_motif=%s", (id_a,), one=True)
                motif_b = query("SELECT * FROM motif WHERE id_motif=%s", (id_b,), one=True)
            else:
                flash('Pilih dua motif yang berbeda.', 'warning')
        elif mode == 'daerah':
            pulau_a = request.form.get('pulau_a','')
            pulau_b = request.form.get('pulau_b','')
            if pulau_a and pulau_b and pulau_a != pulau_b:
                region_a = {
                    'pulau': pulau_a,
                    'motifs': query("SELECT * FROM motif WHERE pulau=%s ORDER BY nama_motif", (pulau_a,)) or []
                }
                region_b = {
                    'pulau': pulau_b,
                    'motifs': query("SELECT * FROM motif WHERE pulau=%s ORDER BY nama_motif", (pulau_b,)) or []
                }
            else:
                flash('Pilih dua pulau yang berbeda.', 'warning')

    return render_template('compare.html',
        motif_a=motif_a, motif_b=motif_b,
        region_a=region_a, region_b=region_b,
        all_motifs=all_motifs, pulaus=pulaus, mode=mode)

# ── KLASIFIKASI AI (login required) ──────────────────────────────────────────
@app.route('/predict', methods=['GET','POST'])
@login_required
def predict():
    result = None
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('File tidak ditemukan.', 'error')
            return redirect(request.url)
        f = request.files['file']
        if not f.filename:
            flash('Tidak ada file dipilih.', 'error')
            return redirect(request.url)
        if not allowed_file(f.filename):
            flash('Format tidak didukung. Gunakan JPG, PNG, atau WEBP.', 'error')
            return redirect(request.url)

        os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
        filename = f"{uuid.uuid4().hex}_{secure_filename(f.filename)}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        f.save(filepath)

        prediction = predict_batik(filepath)
        uid        = session['user_id']
        img_url    = url_for('uploaded_file', filename=filename)

        if prediction and prediction['is_valid']:
            nama_motif = prediction['predicted']
            raw_label  = prediction['raw_label']
            motif_detail = query("SELECT * FROM motif WHERE label_model=%s", (raw_label,), one=True)
            id_motif = motif_detail['id_motif'] if motif_detail else None
            execute("""INSERT INTO prediksi
                       (id_user,nama_file,hasil_prediksi,confidence,id_motif)
                       VALUES (%s,%s,%s,%s,%s)""",
                    (uid, filename, nama_motif, prediction['confidence'], id_motif))
            result = dict(status='success', predicted=nama_motif,
                          confidence=round(prediction['confidence']*100,2),
                          top3=prediction['top3'],
                          motif_detail=motif_detail, img_url=img_url)

        elif prediction and prediction['is_non_batik']:
            execute("""INSERT INTO prediksi (id_user,nama_file,hasil_prediksi,confidence)
                       VALUES (%s,%s,%s,%s)""",
                    (uid, filename, 'non_batik', prediction['confidence']))
            result = dict(status='non_batik',
                          confidence=round(prediction['confidence']*100,2),
                          top3=prediction['top3'], img_url=img_url)

        elif prediction and not prediction['is_valid']:
            execute("""INSERT INTO prediksi (id_user,nama_file,hasil_prediksi,confidence)
                       VALUES (%s,%s,%s,%s)""",
                    (uid, filename, 'Tidak dikenali', prediction['confidence']))
            result = dict(status='unrecognized',
                          confidence=round(prediction['confidence']*100,2),
                          img_url=img_url)
        else:
            result = dict(status='model_unavailable', img_url=img_url)

    return render_template('predict.html', result=result)

# ── SERVE GAMBAR UPLOAD (login required, hanya pemilik) ───────────────────────
@app.route('/uploads/<path:filename>')
@login_required
def uploaded_file(filename):
    try:
        user_id = int(session['user_id'])
    except (ValueError, TypeError):
        user_id = session['user_id']

    owns = query("SELECT id_prediksi FROM prediksi WHERE nama_file=%s AND id_user=%s",
                (filename, user_id), one=True)
    
    if not owns:
        print(f"DEBUG DENIED: File {filename} diblokir untuk User ID {user_id}")
        abort(403)
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# ── HISTORY (login required) ──────────────────────────────────────────────────
@app.route('/history')
@login_required
def history():
    q        = request.args.get('q','').strip()
    tgl_dari = request.args.get('dari','').strip()
    tgl_ke   = request.args.get('ke','').strip()

    sql    = """SELECT id_prediksi,nama_file,hasil_prediksi,
                       confidence,tanggal_prediksi,id_motif
                FROM prediksi WHERE id_user=%s"""
    params = [session['user_id']]

    if q:
        sql += " AND (nama_file LIKE %s OR hasil_prediksi LIKE %s)"
        params += [f"%{q}%", f"%{q}%"]
    if tgl_dari:
        sql += " AND DATE(tanggal_prediksi) >= %s"; params.append(tgl_dari)
    if tgl_ke:
        sql += " AND DATE(tanggal_prediksi) <= %s"; params.append(tgl_ke)

    sql += " ORDER BY tanggal_prediksi DESC LIMIT 50"
    riwayat = query(sql, params) or []
    return render_template('history.html', riwayat=riwayat,
                           q=q, tgl_dari=tgl_dari, tgl_ke=tgl_ke)

@app.route('/history/delete/<int:id_prediksi>', methods=['POST'])
@login_required
def delete_history(id_prediksi):
    # Pastikan hanya milik user sendiri
    row = query("SELECT id_prediksi FROM prediksi WHERE id_prediksi=%s AND id_user=%s",
                (id_prediksi, session['user_id']), one=True)
    if row:
        execute("DELETE FROM prediksi WHERE id_prediksi=%s", (id_prediksi,))
        flash('Riwayat berhasil dihapus.', 'success')
    else:
        flash('Riwayat tidak ditemukan.', 'error')
    return redirect(url_for('history'))

# ── ERROR HANDLERS ────────────────────────────────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(413)
def too_large(e):
    flash('File terlalu besar. Maksimum 16 MB.', 'error')
    return redirect(url_for('predict'))

# ─────────────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    load_ml_model()
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)