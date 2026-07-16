-- ═══════════════════════════════════════════════════════════════════
--  BATIKVERSE NUSANTARA — Database Schema (Gabungan Final)
--  Engine: MySQL 8.0+  |  Charset: utf8mb4
-- ═══════════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS batikverse_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE batikverse_db;

-- ────────────────────────────────────────────────────────────────────
-- TABEL: users
-- ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id_user        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama           VARCHAR(120) NOT NULL,
  email          VARCHAR(180) NOT NULL,
  password_hash  VARCHAR(256) NOT NULL,
  foto_profil    TEXT,
  is_active      TINYINT(1) NOT NULL DEFAULT 1,
  tanggal_daftar TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────────────────────────────────
-- TABEL: user_preferences
-- ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_preferences (
  id_pref         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_user         INT UNSIGNED NOT NULL,
  warna_favorit   VARCHAR(120),
  jenis_batik     VARCHAR(60)  DEFAULT 'semua',
  anggaran        VARCHAR(30)  DEFAULT 'semua',
  acara_favorit   VARCHAR(120),
  wilayah_favorit VARCHAR(120),
  filosofi_kw     VARCHAR(200),
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (id_user) REFERENCES users(id_user) ON DELETE CASCADE,
  UNIQUE KEY uq_user_pref (id_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────────────────────────────────
-- TABEL: motif
-- ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS motif (
  id_motif              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nama_motif            VARCHAR(120) NOT NULL,
  asal_daerah           VARCHAR(120) NOT NULL,
  pulau                 VARCHAR(60),
  provinsi              VARCHAR(100),
  sejarah               TEXT,
  filosofi              TEXT,
  karakteristik         TEXT,
  makna_warna           TEXT,
  cara_pembuatan        TEXT,
  warna_dominan         VARCHAR(200),
  jenis_batik           VARCHAR(80),
  harga_cap_min         INT UNSIGNED DEFAULT 0,
  harga_cap_max         INT UNSIGNED DEFAULT 0,
  harga_tulis_min       INT UNSIGNED DEFAULT 0,
  harga_tulis_max       INT UNSIGNED DEFAULT 0,
  tingkat_kelangkaan    VARCHAR(100),
  deskripsi_kelangkaan  TEXT,
  kapan_digunakan       TEXT,
  acara_cocok           VARCHAR(300),
  referensi             TEXT,
  created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_nama_motif (nama_motif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────────────────────────────────
-- TABEL: galeri_motif
-- ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS galeri_motif (
  id_galeri  INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_motif   INT UNSIGNED NOT NULL,
  gambar     TEXT,
  caption    VARCHAR(255),
  urutan     TINYINT UNSIGNED DEFAULT 0,
  FOREIGN KEY (id_motif) REFERENCES motif(id_motif) ON DELETE CASCADE,
  INDEX idx_galeri_motif (id_motif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────────────────────────────────
-- TABEL: prediksi
-- ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS prediksi (
  id_prediksi      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  id_user          INT UNSIGNED,
  nama_file        VARCHAR(255) NOT NULL,
  gambar_upload    LONGTEXT,
  hasil_prediksi   VARCHAR(120),
  confidence       FLOAT,
  id_motif         INT UNSIGNED,
  tanggal_prediksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_user)  REFERENCES users(id_user)  ON DELETE SET NULL,
  FOREIGN KEY (id_motif) REFERENCES motif(id_motif)  ON DELETE SET NULL,
  INDEX idx_prediksi_user    (id_user),
  INDEX idx_prediksi_tanggal (tanggal_prediksi DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════════════════════
--  SEED DATA — 30 Motif Batik (sesuai daftar penelitian)
-- ═══════════════════════════════════════════════════════════════════

INSERT IGNORE INTO motif
  (nama_motif, asal_daerah, pulau, provinsi, sejarah, filosofi,
   karakteristik, warna_dominan, makna_warna, jenis_batik,
   harga_cap_min, harga_cap_max, harga_tulis_min, harga_tulis_max,
   tingkat_kelangkaan, kapan_digunakan, acara_cocok, referensi)
VALUES

-- ── BALI ─────────────────────────────────────────────────────────
('Bali_Barong',
 'Bali', 'Bali', 'Bali',
 'Motif Barong terinspirasi dari sosok Barong, makhluk mitologis pelindung dalam tradisi Hindu Bali. Motif ini berkembang seiring tradisi tari Barong yang telah berlangsung selama ratusan tahun sebagai bagian dari upacara keagamaan Hindu di Bali.',
 'Barong melambangkan kebaikan, pelindung dari kekuatan jahat, dan penjaga keseimbangan alam semesta. Dalam kosmologi Bali, Barong adalah simbol dharma (kebenaran) yang senantiasa bertarung melawan adharma (kejahatan).',
 'Motif didominasi wujud Barong—binatang mitologis berbulu lebat—dikelilingi ornamen flora khas Bali yang rinci dan simetris.',
 'Merah, Emas, Hitam, Putih',
 'Merah melambangkan keberanian dan semangat. Emas melambangkan kesucian dan kemewahan. Hitam melambangkan perlindungan dan kekuatan.',
 'Tulis, Cap',
 200000, 800000, 2000000, 8000000,
 'Digunakan pada upacara adat dan keagamaan',
 'Upacara keagamaan, festival budaya, galungan, nyepi',
 'Picard, M. (1996). Bali: Cultural Tourism and Touristic Culture. Singapore: Archipelago Press.'),

-- ── DKI JAKARTA ──────────────────────────────────────────────────
('Jakarta_OndelOndel',
 'Jakarta', 'Jawa', 'DKI Jakarta',
 'Motif Ondel-Ondel terinspirasi dari boneka raksasa ikonik budaya Betawi yang telah ada sejak abad ke-17. Ondel-ondel secara historis digunakan sebagai penolak bala dalam tradisi masyarakat Betawi dan kini menjadi simbol identitas Jakarta.',
 'Ondel-ondel melambangkan penjaga dan pelindung kampung dari roh jahat. Dalam budaya Betawi modern, motif ini merepresentasikan kebanggaan identitas lokal Jakarta yang ceria dan terbuka terhadap keberagaman.',
 'Menampilkan sosok ondel-ondel berpasangan (laki-perempuan) dengan warna cerah, dikelilingi motif bunga dan ornamen khas Betawi.',
 'Merah, Hijau, Emas, Putih',
 'Merah (ondel laki) melambangkan keberanian. Hijau (ondel perempuan) melambangkan kesuburan dan harapan.',
 'Cap, Kombinasi',
 75000, 350000, 800000, 3500000,
 'Umum digunakan dan mudah ditemukan',
 'Festival Betawi, HUT Jakarta, acara budaya, sehari-hari',
 'Chaer, A. (2012). Folklor Betawi: Kebudayaan dan Kehidupan Orang Betawi. Jakarta: Masup.'),

('Jakarta_Tumpal',
 'Jakarta', 'Jawa', 'DKI Jakarta',
 'Motif Tumpal merupakan salah satu motif tertua dalam tradisi batik pesisir Jakarta, dipengaruhi oleh motif Tumpal dari berbagai kebudayaan Asia. Di Betawi, motif ini sering digunakan sebagai pembatas atau border pada kain upacara.',
 'Tumpal berbentuk segitiga yang berulang melambangkan gunung atau puncak spiritual, simbol hubungan antara bumi dan langit, serta doa dan harapan agar kehidupan terus menanjak ke arah yang lebih baik.',
 'Pola segitiga berulang yang tersusun rapi seperti gigi, biasanya digunakan sebagai motif tepi atau border pada kain batik Betawi.',
 'Biru, Merah, Putih, Hitam',
 'Biru melambangkan ketenangan dan kebijaksanaan. Merah melambangkan semangat dan keberanian.',
 'Cap, Kombinasi',
 75000, 300000, 700000, 3000000,
 'Umum digunakan dan mudah ditemukan',
 'Acara budaya, sehari-hari, fashion',
 'Shahab, A. (2001). Betawi: Queen of the East. Jakarta: Republika.'),

-- ── JAWA BARAT ───────────────────────────────────────────────────
('JawaBarat_MegaMendung',
 'Cirebon', 'Jawa', 'Jawa Barat',
 'Mega Mendung adalah ikon batik Cirebon yang telah mendapat pengakuan UNESCO sebagai Warisan Budaya Tak Benda. Motif ini lahir dari akulturasi budaya Jawa dan Tionghoa melalui pedagang yang menetap di Cirebon pada abad ke-16 hingga 17.',
 'Mega berarti awan besar, mendung berarti teduh dan sejuk. Motif ini melambangkan pembawa hujan sebagai kesuburan dan kemakmuran. Awan dalam tradisi Tionghoa juga melambangkan dunia atas dan transisi antara langit dan bumi.',
 'Berbentuk awan berlapis-lapis dengan gradasi 3–7 warna dan tepi bergelombang. Komposisi gradasi warna adalah ciri khas paling kuat yang membedakan motif ini.',
 'Biru, Merah, Putih, Hitam',
 'Biru melambangkan ketenangan dan kedamaian. Merah melambangkan keberanian dan kekuatan. Gradasi melambangkan kedalaman makna.',
 'Tulis, Cap, Kombinasi',
 150000, 600000, 1500000, 6000000,
 'Umum digunakan dan mudah ditemukan',
 'Sehari-hari, fashion, acara formal, wisuda',
 'Harini, R. (2010). Batik Cirebon: Makna dan Filosofi. Cirebon: Dinas Kebudayaan Kota Cirebon.'),

-- ── JAWA TENGAH ──────────────────────────────────────────────────
('JawaTengah_Jlamprang',
 'Pekalongan', 'Jawa', 'Jawa Tengah',
 'Jlamprang adalah motif batik tradisional Pekalongan yang mendapat pengaruh dari motif patola India. Para pedagang Gujarat membawa kain patola ke pantai utara Jawa, dan seniman Pekalongan mengadaptasikannya ke dalam teknik batik.',
 'Jlamprang melambangkan kemakmuran dan keberkahan. Motif simetris yang sangat presisi mencerminkan keteraturan, keseimbangan, dan harmoni dalam kehidupan.',
 'Pola geometris simetris sangat presisi menyerupai bintang atau roset multi-sisi. Pola berulang secara konsisten membentuk komposisi yang teratur dan rapi.',
 'Merah, Biru, Hitam, Putih',
 'Merah melambangkan keberanian. Biru melambangkan ketenangan dan kesetiaan. Putih melambangkan kesucian.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Umum digunakan dan mudah ditemukan',
 'Sehari-hari, acara formal, fashion',
 'Doellah, H.S. (2002). Batik: Pengaruh Zaman dan Lingkungan. Solo: Danar Hadi.'),

('JawaTengah_Truntum',
 'Surakarta', 'Jawa', 'Jawa Tengah',
 'Motif Truntum diciptakan oleh Kanjeng Ratu Kencana, permaisuri Pakubuwono III, pada abad ke-18. Dikisahkan beliau menciptakan motif ini saat ditinggal sang raja sebagai ungkapan kerinduan dan pengabdian.',
 'Truntum berasal dari kata "taruntum" yang berarti tumbuh kembali. Melambangkan cinta yang terus bertumbuh dan tak pernah padam. Biasanya digunakan orang tua pengantin sebagai doa untuk cinta abadi sang anak.',
 'Berupa bintang-bintang kecil menyerupai bunga dengan delapan kelopak yang tersebar merata di seluruh permukaan kain berlatar hitam.',
 'Hitam, Emas, Putih',
 'Hitam melambangkan kedalaman dan keabadian. Emas melambangkan kemewahan dan kejayaan cinta.',
 'Tulis',
 200000, 600000, 2000000, 7000000,
 'Digunakan pada upacara adat',
 'Pernikahan, upacara adat Jawa, siraman',
 'Prawirohardjo, O. (2007). Batik Keraton. Yogyakarta: Yayasan Batik Indonesia.'),

-- ── JAWA TIMUR ────────────────────────────────────────────────────
('JawaTimur_Gentongan',
 'Madura', 'Jawa', 'Jawa Timur',
 'Batik Gentongan adalah batik khas Madura yang dinamakan sesuai proses pembuatannya — kain direndam dalam gentong (wadah tanah liat) berisi pewarna alami selama berbulan-bulan hingga bertahun-tahun.',
 'Gentongan melambangkan kesabaran, ketekunan, dan kedalaman nilai dalam proses kehidupan. Proses pewarnaan yang sangat lama mengajarkan bahwa hasil terbaik membutuhkan waktu dan dedikasi.',
 'Warna-warnanya sangat kaya dan dalam karena proses perendaman lama dalam pewarna alami. Motif cenderung abstrak dengan pola bebas yang unik setiap kainnya.',
 'Merah Tua, Coklat Tua, Hitam, Krem',
 'Merah tua dan coklat tua dari pewarna alami melambangkan kematangan dan kebijaksanaan.',
 'Tulis',
 500000, 2000000, 3000000, 15000000,
 'Digunakan pada acara khusus',
 'Acara adat Madura, koleksi, fashion tinggi',
 'Wahyono, E. (2011). Batik Madura: Identitas Budaya. Surabaya: Unesa Press.'),

('JawaTimur_Pring',
 'Situbondo', 'Jawa', 'Jawa Timur',
 'Motif Pring (bambu) adalah motif batik khas Situbondo dan beberapa daerah Jawa Timur lainnya. Bambu dipilih sebagai motif utama karena tanaman ini sangat dekat dengan kehidupan masyarakat setempat.',
 'Pring (bambu) melambangkan keluwesan, kekuatan, dan ketahanan dalam menghadapi berbagai situasi. Bambu yang mudah membungkuk namun tidak patah adalah filosofi hidup yang adaptif namun berprinsip.',
 'Menampilkan rumpun bambu dengan daun dan batang yang tersusun dinamis, menciptakan ritme visual yang menenangkan. Motif ini cenderung naturalistik.',
 'Hijau, Coklat, Kuning, Hitam',
 'Hijau melambangkan kesuburan dan harapan. Coklat melambangkan keteguhan dan tanah yang menopang.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Umum digunakan dan mudah ditemukan',
 'Sehari-hari, fashion, acara informal',
 'Yayasan Batik Indonesia. (2010). Ragam Motif Batik Jawa Timur. Jakarta: YBI.'),

-- ── DI YOGYAKARTA ────────────────────────────────────────────────
('Yogyakarta_Kawung',
 'Yogyakarta', 'Jawa', 'DI Yogyakarta',
 'Kawung merupakan salah satu motif batik paling kuno di Jawa, diyakini sudah ada sejak abad ke-13 berdasarkan relief di Candi Prambanan dan Borobudur. Motif ini eksklusif digunakan oleh keluarga keraton Mataram.',
 'Motif Kawung terinspirasi dari buah aren (kawung) yang dibelah empat. Melambangkan empat arah mata angin dan kesempurnaan hidup. Filosofinya mengajarkan keseimbangan, kemurnian hati, dan pengendalian diri.',
 'Terdiri dari lingkaran elips atau oval yang saling bersinggungan membentuk pola empat kelopak bunga. Setiap unit terdiri dari empat oval yang melingkupi sebuah titik pusat.',
 'Putih, Hitam, Coklat Muda',
 'Putih melambangkan kesucian. Hitam melambangkan kedalaman dan kematangan. Komposisi dua warna mencerminkan keseimbangan yin-yang.',
 'Tulis',
 200000, 700000, 2000000, 8000000,
 'Digunakan pada lingkungan keraton',
 'Upacara keraton, pernikahan adat Jawa, wisuda, acara resmi',
 'Prawirohardjo, O. (2007). Batik Keraton. Yogyakarta: Yayasan Batik Indonesia.'),

('Yogyakarta_ParangRusak',
 'Yogyakarta', 'Jawa', 'DI Yogyakarta',
 'Parang Rusak adalah motif Parang yang paling dikenal dan tertua. Konon diciptakan oleh Sultan Agung Hanyokrokusumo pada masa Kerajaan Mataram Islam. Motif ini termasuk motif larangan yang tidak boleh sembarangan dikenakan.',
 'Parang melambangkan semangat yang tidak pernah putus bagaikan ombak laut. Rusak berarti berlekuk, menggambarkan dinamika kehidupan. Pemakainya diharapkan memiliki jiwa ksatria yang tidak pernah menyerah.',
 'Motif berbentuk diagonal menyerupai huruf S berulang yang saling terhubung, menciptakan pola gelombang tak terputus dari kiri atas ke kanan bawah.',
 'Coklat Sogan, Hitam, Krem',
 'Sogan (coklat kekuningan) adalah warna khas keraton Yogyakarta, melambangkan kematangan dan wibawa.',
 'Tulis',
 300000, 1000000, 3000000, 12000000,
 'Digunakan pada lingkungan keraton',
 'Upacara keraton, pernikahan sakral, pelantikan',
 'Hardjonagoro, K.R.T. (2006). Batik: Sebuah Warisan Budaya. Jakarta: Yayasan Batik Indonesia.'),

-- ── KALIMANTAN ───────────────────────────────────────────────────
('Kalimantan_Dayak',
 'Kalimantan', 'Kalimantan', 'Kalimantan Tengah',
 'Batik Dayak merupakan interpretasi modern dari seni ukir dan tenun tradisional suku Dayak Kalimantan yang diadaptasi ke dalam teknik membatik. Meskipun secara historis suku Dayak tidak membatik, motif-motif tradisional mereka diadaptasi sejak abad ke-20.',
 'Motif Dayak mengandung makna spiritual yang dalam — setiap simbol terhubung dengan alam, roh leluhur, dan keseimbangan kosmis. Burung Enggang sebagai totem suci dan motif sulur melambangkan siklus kehidupan yang abadi.',
 'Didominasi motif Burung Enggang, sulur tanaman merambat, dan pola geometris khas Dayak yang simetris. Biasanya berwarna earth-tone dengan aksen merah dan hitam yang kuat.',
 'Merah, Hitam, Coklat, Emas',
 'Merah melambangkan keberanian. Hitam melambangkan kekuatan roh leluhur. Coklat melambangkan tanah Kalimantan yang subur.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya, fashion etnik, promosi pariwisata Kalimantan',
 'Riwut, N. (2003). Maneser Panatau Tatu Hiang: Menyelami Kekayaan Leluhur. Palangka Raya: Pusaka Lima.'),

('KalimantanBarat_Insang',
 'Pontianak', 'Kalimantan', 'Kalimantan Barat',
 'Batik Insang adalah batik ikonik Kota Pontianak yang terinspirasi dari bentuk insang ikan — mencerminkan kehidupan masyarakat pesisir dan nelayan di tepi Sungai Kapuas.',
 'Insang melambangkan kehidupan yang mengalir seperti air sungai, ketergantungan pada alam, dan kebersyukuran atas sumber daya alam yang melimpah. Motif ini juga melambangkan identitas kuat masyarakat Kalimantan Barat.',
 'Berbentuk susunan pola menyerupai insang ikan yang tersusun rapi dan berirama. Dapat dikombinasikan dengan motif floral dan geometris khas pesisir Kalimantan.',
 'Biru, Hijau, Emas, Merah',
 'Biru dan hijau merefleksikan Sungai Kapuas dan alam Kalimantan. Emas melambangkan kemakmuran nelayan.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Kalbar, sehari-hari, fashion',
 'Dinas Kebudayaan Kalimantan Barat. (2014). Batik Kalimantan Barat. Pontianak.'),

-- ── SUMATERA ─────────────────────────────────────────────────────
('SumateraBarat_RumahMinang',
 'Padang', 'Sumatera', 'Sumatera Barat',
 'Motif Rumah Gadang (Rumah Minang) adalah motif batik khas Sumatera Barat yang terinspirasi dari arsitektur Rumah Gadang — rumah adat Minangkabau dengan atap melengkung seperti tanduk kerbau.',
 'Rumah Gadang melambangkan matrilinealitas dan sistem sosial Minangkabau yang kuat, kebersamaan keluarga besar, serta identitas budaya Minang yang dipertahankan lintas generasi. Rumah adalah pusat kehidupan sosial dan spiritual.',
 'Menampilkan siluet Rumah Gadang dengan atap melengkung khas dikelilingi ornamen flora dan songket Minangkabau dalam komposisi yang elegan.',
 'Merah, Hitam, Emas, Hijau',
 'Merah, hitam, dan emas adalah tiga warna sakral Minangkabau yang melambangkan keberanian, keteguhan, dan kemakmuran adat.',
 'Cap, Kombinasi',
 100000, 450000, 1000000, 4500000,
 'Terbatas pada daerah tertentu',
 'Festival Minangkabau, acara adat, fashion etnik',
 'Navis, A.A. (1984). Alam Terkembang Jadi Guru: Adat dan Kebudayaan Minangkabau. Jakarta: Grafiti Pers.'),

('SumateraUtara_Boraspati',
 'Medan', 'Sumatera', 'Sumatera Utara',
 'Boraspati ni Tano adalah motif batik khas Batak Toba yang terinspirasi dari cecak (Boraspati) — hewan yang dianggap sakral dan pembawa keberuntungan dalam tradisi Batak.',
 'Boraspati melambangkan penjaga rumah dan pembawa rezeki. Dalam kepercayaan Batak, cecak yang ada di rumah adalah pertanda baik. Motif ini mengandung harapan agar pemakainya senantiasa dilindungi dan diberkahi.',
 'Menampilkan motif cecak yang dipadukan dengan gorga (ukiran Batak) tradisional, disusun dalam pola berulang yang ritmis.',
 'Merah, Hitam, Putih',
 'Merah, hitam, dan putih adalah tiga warna utama gorga Batak yang melambangkan kehidupan, kekuatan, dan kesucian.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Batak, sehari-hari, fashion',
 'Vergouwen, J.C. (1964). The Social Organisation and Customary Law of the Toba-Batak. The Hague: Martinus Nijhoff.'),

('SumateraUtara_PintuAceh',
 'Banda Aceh', 'Sumatera', 'Aceh',
 'Motif Pintu Aceh terinspirasi dari arsitektur pintu Rumah Aceh yang khas — pintu berukir dengan motif floral dan geometris Islami yang indah. Batik ini merupakan ekspresi modernisasi tradisi tenun Aceh ke dalam teknik batik.',
 'Pintu Aceh melambangkan keterbukaan, penerimaan tamu, dan kehangatan budaya Aceh. Dalam tradisi Islam Aceh, pintu rumah yang indah mencerminkan kemuliaan tuan rumah dan rasa hormat kepada tamu.',
 'Menampilkan ornamen arsitektural pintu Aceh dengan motif sulur-sulur Islami, bintang, dan geometris yang simetris dan mewah.',
 'Merah, Emas, Hijau, Hitam',
 'Merah dan emas melambangkan keberanian dan kemewahan. Hijau adalah warna Islam yang melambangkan kesuburan dan berkah.',
 'Cap, Kombinasi',
 120000, 500000, 1200000, 5000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Aceh, hari raya Islam, fashion',
 'Dinas Kebudayaan Provinsi Aceh. (2016). Kain Tradisional Aceh. Banda Aceh.'),

-- ── LAMPUNG ──────────────────────────────────────────────────────
('Lampung_Gajah',
 'Lampung', 'Sumatera', 'Lampung',
 'Motif Gajah adalah salah satu motif batik Lampung yang terinspirasi dari Gajah Sumatera, satwa yang sakral dan menjadi simbol provinsi Lampung. Motif ini mencerminkan hubungan erat masyarakat Lampung dengan alam.',
 'Gajah melambangkan kekuatan, kebijaksanaan, kesetiaan, dan keuletan. Dalam tradisi Lampung, gajah dianggap hewan suci yang harus dilindungi. Motif ini juga mengandung pesan pelestarian lingkungan dan satwa liar.',
 'Menampilkan sosok gajah yang megah dikelilingi ornamen flora Sumatera dan motif Tapis (kain tradisional Lampung) yang khas.',
 'Merah, Hitam, Emas, Hijau',
 'Merah melambangkan keberanian Lampung. Emas melambangkan kemewahan dan keagungan. Hijau melambangkan alam Sumatera yang subur.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Umum digunakan dan mudah ditemukan',
 'Festival budaya Lampung, sehari-hari, fashion',
 'Dinas Pariwisata Lampung. (2013). Motif Batik Lampung. Bandar Lampung.'),

('Lampung_Bledheg',
 'Lampung', 'Sumatera', 'Lampung',
 'Motif Bledheg terinspirasi dari petir (bledheg dalam bahasa Jawa-Lampung) — fenomena alam yang dianggap sakral dan penuh kekuatan. Motif ini mencerminkan perpaduan budaya Jawa dan Lampung yang sudah berlangsung lama.',
 'Bledheg (petir) melambangkan kekuatan alam yang dahsyat namun juga pemberi hujan dan kesuburan. Motif ini mengajarkan rasa hormat terhadap alam dan kekuatan yang melampaui manusia.',
 'Pola zigzag dinamis menyerupai kilat petir yang tersusun dalam komposisi berulang, menciptakan energi visual yang kuat dan dinamis.',
 'Biru Tua, Emas, Putih, Hitam',
 'Biru tua melambangkan langit malam saat badai. Emas dan putih melambangkan cahaya kilat yang menerangi.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya, fashion, acara informal',
 'Dinas Pariwisata Lampung. (2013). Motif Batik Lampung. Bandar Lampung.'),

-- ── SULAWESI ─────────────────────────────────────────────────────
('SulawesiSelatan_Lontara',
 'Makassar', 'Sulawesi', 'Sulawesi Selatan',
 'Motif Lontara adalah motif batik khas Sulawesi Selatan yang terinspirasi dari aksara Lontara — sistem tulisan tradisional yang digunakan oleh masyarakat Bugis, Makassar, dan Toraja.',
 'Lontara melambangkan pengetahuan, kecerdasan, dan warisan literasi leluhur. Aksara Lontara adalah bukti peradaban tinggi masyarakat Bugis-Makassar yang telah mendokumentasikan sejarah, hukum, dan sastra dalam bahasa tulisnya sendiri.',
 'Menampilkan huruf-huruf aksara Lontara yang distilasi menjadi ornamen dekoratif, disusun dalam pola berulang yang elegan dan bermakna.',
 'Emas, Hitam, Merah, Putih',
 'Emas melambangkan keagungan kerajaan Bugis-Makassar. Hitam melambangkan keteguhan. Merah melambangkan keberanian.',
 'Cap, Kombinasi',
 120000, 500000, 1200000, 5000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Sulawesi, acara resmi, fashion',
 'Pelras, C. (1996). The Bugis. Oxford: Blackwell.'),

-- ── PAPUA ─────────────────────────────────────────────────────────
('Papua_Asmat',
 'Agats', 'Papua', 'Papua Selatan',
 'Motif Asmat terinspirasi dari seni ukir suku Asmat Papua yang telah diakui sebagai salah satu karya seni paling bernilai di dunia. Ukiran Asmat diakui UNESCO sebagai warisan budaya yang perlu dilindungi.',
 'Motif Asmat mengandung makna spiritual yang sangat dalam — setiap ukiran terhubung dengan roh leluhur, siklus kehidupan dan kematian, serta hubungan antara manusia dan alam Papua. Ukiran adalah doa dan persembahan.',
 'Menampilkan motif geometris khas suku Asmat: pola spiral, chevron, dan figur-figur manusia stilasi yang mencerminkan kosmologi dan kepercayaan animisme.',
 'Hitam, Merah, Putih',
 'Hitam, merah, dan putih adalah tiga warna sakral suku Asmat yang diperoleh dari bahan alam Papua dan digunakan dalam setiap ritual.',
 'Cap, Kombinasi',
 150000, 600000, 1500000, 6000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Papua, pameran seni, koleksi',
 'Schneebaum, T. (1985). Embodied Spirits: Ritual Carvings of the Asmat. Salem: Peabody Museum.'),

('Papua_Cendrawasih',
 'Jayapura', 'Papua', 'Papua',
 'Motif Cendrawasih terinspirasi dari Burung Cendrawasih — "Bird of Paradise" yang menjadi simbol Papua dan lambang keindahan alam nusantara. Burung ini dilindungi oleh hukum Indonesia.',
 'Cendrawasih melambangkan keindahan yang luar biasa, kebebasan, dan surga di bumi. Dalam tradisi Papua, Cendrawasih adalah burung surga yang membawa pesan keajaiban alam dan doa leluhur.',
 'Menampilkan sosok Burung Cendrawasih yang indah dengan bulu ekor panjang berwarna-warni, dikelilingi flora Papua yang rimbun. Visualnya selalu mewah dan penuh warna.',
 'Kuning, Merah, Hijau, Hitam, Emas',
 'Warna-warni bulu Cendrawasih yang indah melambangkan keberagaman dan kekayaan alam Papua yang tak ternilai.',
 'Cap, Kombinasi',
 150000, 600000, 1500000, 6000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Papua, fashion, promosi pariwisata',
 'Beehler, B.M. (1978). Upland Birds of Northeastern New Guinea. Bulletin of Natural History Museum. Honolulu.'),

-- ── MALUKU ───────────────────────────────────────────────────────
('Maluku_Pala',
 'Ambon', 'Maluku', 'Maluku',
 'Motif Pala terinspirasi dari tanaman Pala (Myristica fragrans) — rempah paling berharga yang menjadikan Maluku sebagai pusat perdagangan rempah dunia selama berabad-abad. Pala adalah "emas hijau" Maluku.',
 'Pala melambangkan kekayaan alam Maluku yang luar biasa, keberanian pelaut Maluku mengarungi samudra, dan peran penting Maluku dalam sejarah perdagangan dunia. Motif ini adalah kebanggaan identitas Maluku.',
 'Menampilkan buah pala, biji pala, dan daun tanaman pala dalam komposisi naturalistik yang detail, sering dipadukan dengan ornamen maritim khas Maluku.',
 'Hijau, Coklat, Emas, Merah',
 'Hijau melambangkan alam Maluku yang subur. Coklat biji pala melambangkan kemakmuran. Emas melambangkan nilai tinggi rempah Maluku.',
 'Cap, Kombinasi',
 120000, 500000, 1200000, 5000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya Maluku, sehari-hari, fashion',
 'Andaya, L.Y. (1993). The World of Maluku. Honolulu: University of Hawaii Press.'),

-- ── NTB ──────────────────────────────────────────────────────────
('NTB_Lumbung',
 'Mataram', 'Nusa Tenggara', 'Nusa Tenggara Barat',
 'Motif Lumbung terinspirasi dari lumbung padi (bale) — bangunan penyimpan padi yang menjadi simbol kemakmuran dan ketahanan pangan dalam budaya Lombok dan Sumbawa di NTB.',
 'Lumbung melambangkan kemakmuran, ketahanan, dan kebijaksanaan dalam menyimpan dan mengelola sumber daya. Budaya lumbung mengajarkan prinsip menabung dan tidak boros agar tersedia cadangan di masa sulit.',
 'Menampilkan siluet bangunan lumbung dengan atap jerami khas yang dikelilingi motif padi, bunga, dan ornamen geometris Sasak dan Sumbawa.',
 'Coklat, Emas, Hitam, Hijau',
 'Coklat jerami melambangkan padi dan kemakmuran alam. Emas melambangkan kekayaan panen. Hijau melambangkan kesuburan sawah.',
 'Cap, Kombinasi',
 100000, 400000, 1000000, 4000000,
 'Terbatas pada daerah tertentu',
 'Festival budaya NTB, sehari-hari, fashion',
 'Departemen Pendidikan dan Kebudayaan NTB. (1990). Adat Istiadat Daerah Nusa Tenggara Barat. Mataram.');

-- ═══════════════════════════════════════════════════════════════════
--  Galeri placeholder untuk setiap motif
-- ═══════════════════════════════════════════════════════════════════
INSERT IGNORE INTO galeri_motif (id_motif, gambar, caption, urutan)
SELECT id_motif, NULL, CONCAT('Motif ', nama_motif, ' — tampilan utama'), 0
FROM motif
WHERE id_motif NOT IN (SELECT DISTINCT id_motif FROM galeri_motif);

