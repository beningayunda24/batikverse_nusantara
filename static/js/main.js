/* BATIKVERSE NUSANTARA — Main JavaScript v2 */

/* ── Navbar scroll shadow ────────────────────────────────────────── */
const navbar = document.getElementById('navbar');
if (navbar) {
  window.addEventListener('scroll', () => {
    navbar.style.boxShadow = window.scrollY > 50
      ? '0 4px 24px rgba(10,14,40,0.22)' : 'none';
  }, { passive: true });
}

/* ── Mobile nav toggle ───────────────────────────────────────────── */
const navToggle = document.getElementById('navToggle');
const navLinks  = document.getElementById('navLinks');
if (navToggle && navLinks) {
  navToggle.addEventListener('click', () => {
    navLinks.classList.toggle('open');
    navToggle.setAttribute('aria-expanded', navLinks.classList.contains('open'));
  });
  document.addEventListener('click', (e) => {
    if (!navToggle.contains(e.target) && !navLinks.contains(e.target))
      navLinks.classList.remove('open');
  });
}

/* ── User dropdown menu ──────────────────────────────────────────── */
const userMenuBtn  = document.getElementById('userMenuBtn');
const userDropdown = document.getElementById('userDropdown');
if (userMenuBtn && userDropdown) {
  userMenuBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    userDropdown.classList.toggle('open');
  });
  document.addEventListener('click', () => userDropdown.classList.remove('open'));
}

/* ── Auto-dismiss flash messages ─────────────────────────────────── */
document.querySelectorAll('.flash').forEach(flash => {
  setTimeout(() => {
    flash.style.opacity = '0';
    flash.style.transform = 'translateX(120%)';
    flash.style.transition = 'all 0.4s ease';
    setTimeout(() => flash.remove(), 400);
  }, 5000);
});

/* ── Fade-in on scroll ───────────────────────────────────────────── */
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.08, rootMargin: '0px 0px -30px 0px' });

document.querySelectorAll('.card, .detail-info-section, .auth-card').forEach(el => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(18px)';
  el.style.transition = 'opacity 0.45s ease, transform 0.45s ease';
  observer.observe(el);
});

/* ── Confidence bar animation ─────────────────────────────────────── */
document.querySelectorAll('.confidence-fill').forEach(bar => {
  const w = bar.style.width;
  bar.style.width = '0%';
  setTimeout(() => { bar.style.width = w; }, 350);
});

/* ── Predict page: upload zone ───────────────────────────────────── */
const zone      = document.getElementById('uploadZone');
const input     = document.getElementById('fileInput');
const defDiv    = document.getElementById('uploadDefault');
const prevDiv   = document.getElementById('uploadPreview');
const prevImg   = document.getElementById('previewImg');
const prevName  = document.getElementById('previewName');
const submitBtn = document.getElementById('submitBtn');
const form      = document.getElementById('predictForm');
const loader    = document.getElementById('loader');
const errorBox  = document.getElementById('uploadError');

const MAX_SIZE = 16 * 1024 * 1024; // 16 MB
const ALLOWED_TYPES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

function validateFile(file) {
  if (!ALLOWED_TYPES.includes(file.type)) {
    return 'Format file tidak didukung. Gunakan JPG, PNG, atau WEBP.';
  }
  if (file.size > MAX_SIZE) {
    return 'Ukuran file melebihi batas 16 MB.';
  }
  return null;
}

function resetUpload() {
  defDiv.style.display = 'block';
  prevDiv.style.display = 'none';
  submitBtn.disabled = true;
  input.value = '';
}

function showPreview(file) {
  const errorMsg = validateFile(file);
  if (errorMsg) {
    errorBox.textContent = errorMsg;
    errorBox.style.display = 'block';
    resetUpload();
    return;
  }
  errorBox.style.display = 'none';

  const reader = new FileReader();
  reader.onload = e => {
    prevImg.src = e.target.result;
    prevName.textContent = file.name;
    defDiv.style.display = 'none';
    prevDiv.style.display = 'block';
    submitBtn.disabled = false;
  };
  reader.readAsDataURL(file);
}

if (zone && input && form) {

    input.addEventListener('change', () => {
        if (input.files.length > 0) {
            showPreview(input.files[0]);
        }
    });

    zone.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            input.click();
        }
    });

    zone.addEventListener('dragover', e => {
        e.preventDefault();
        zone.classList.add('drag-over');
    });

    zone.addEventListener('dragleave', () => {
        zone.classList.remove('drag-over');
    });

    zone.addEventListener('drop', e => {
        e.preventDefault();
        zone.classList.remove('drag-over');

        const file = e.dataTransfer.files[0];
        if (file) {
            input.files = e.dataTransfer.files;
            showPreview(file);
        }
    });

    form.addEventListener('submit', e => {
        if (!input.files.length || submitBtn.disabled) {
            e.preventDefault();
            return;
        }

        submitBtn.style.display = 'none';
        loader.classList.add('active');
    });

}

/* ── Compare: pre-select from URL param ─────────────────────────── */
const urlParams = new URLSearchParams(window.location.search);
const preSelect = urlParams.get('pre');
if (preSelect) {
  const selA = document.querySelector('select[name="motif_a"]');
  if (selA) selA.value = preSelect;
}

/* ── Delete history confirm ──────────────────────────────────────── */
document.querySelectorAll('.confirm-delete').forEach(form => {
  form.addEventListener('submit', e => {
    if (!confirm('Hapus riwayat ini? Tindakan tidak dapat dibatalkan.')) {
      e.preventDefault();
    }
  });
});

/* ── Pulau filter tabs ───────────────────────────────────────────── */
document.querySelectorAll('.pulau-tab[data-pulau]').forEach(tab => {
  tab.addEventListener('click', () => {
    const url = new URL(window.location);
    const val = tab.dataset.pulau;
    if (val) url.searchParams.set('pulau', val);
    else url.searchParams.delete('pulau');
    window.location.href = url.toString();
  });
});

/* ── Profile tabs ────────────────────────────────────────────────── */
document.querySelectorAll('.profile-tab[data-target]').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.profile-tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.profile-panel').forEach(p => p.style.display = 'none');
    tab.classList.add('active');
    const target = document.getElementById(tab.dataset.target);
    if (target) target.style.display = 'block';
  });
});
// Show first tab by default
const firstTab = document.querySelector('.profile-tab[data-target]');
if (firstTab) firstTab.click();

/* ── Back to top ─────────────────────────────────────────────────── */
(function() {
  const btn = document.createElement('button');
  btn.innerHTML = '<i class="fas fa-arrow-up"></i>';
  btn.title = 'Kembali ke atas';
  btn.style.cssText = `
    position:fixed;bottom:2rem;right:2rem;
    width:44px;height:44px;border-radius:50%;
    background:var(--gold);color:var(--ink);
    border:none;cursor:pointer;
    display:flex;align-items:center;justify-content:center;
    opacity:0;transition:opacity 0.3s ease;
    z-index:999;box-shadow:0 4px 12px rgba(200,144,42,0.4);
  `;
  document.body.appendChild(btn);
  btn.addEventListener('click', () => window.scrollTo({ top:0, behavior:'smooth' }));
  window.addEventListener('scroll', () => {
    btn.style.opacity      = window.scrollY > 400 ? '1' : '0';
    btn.style.pointerEvents = window.scrollY > 400 ? 'auto' : 'none';
  }, { passive: true });
})();

/* ── Password toggle (auth pages) ───────────────────────────────── */
window.togglePw = function(id, btn) {
  const f = document.getElementById(id);
  const show = f.type === 'password';
  f.type = show ? 'text' : 'password';
  btn.innerHTML = show
    ? '<i class="fas fa-eye-slash"></i>'
    : '<i class="fas fa-eye"></i>';
};
