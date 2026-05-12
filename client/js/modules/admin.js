/* === modules\admin.js === */

/**
 * KPSS Dashboard - Admin Module
 * Contains User Management, Reports and Feedbacks
 */

if (typeof API === 'undefined') {
    window.API = window.API_URL || 'http://localhost:3456';
}

// ══════════════════════════════════════════════════════════════════════════
// USER MANAGEMENT
// ══════════════════════════════════════════════════════════════════════════

let _allUsers = [];

function getAccountType(user) {
    if (user.isGuest === true || !user.email || user.email === 'N/A') return 'guest';
    return 'email';
}

function getPlatformType(user) {
    const platform = (user.platform || '').toString().trim().toLowerCase();
    if (platform.includes('android')) return 'android';
    if (platform.includes('ios') || platform.includes('iphone') || platform.includes('ipad')) return 'ios';
    return 'other';
}

function getPlatformLabel(user) {
    const type = getPlatformType(user);
    if (type === 'android') return 'Android';
    if (type === 'ios') return 'iOS';
    if ((user.platform || '').toString().trim()) return user.platform;
    return 'Bilinmiyor';
}

function getLoginMethodLabel(user) {
    if (user.loginMethod) return user.loginMethod;
    const providers = Array.isArray(user.authProviders) ? user.authProviders : [];
    const primary = providers[0] || '';
    const p = primary.toString().toLowerCase();
    if (p === 'google.com') return 'Google';
    if (p === 'password') return 'E-posta/Şifre';
    if (p === 'apple.com') return 'Apple';
    if (p === 'phone') return 'Telefon';
    if (p === 'anonymous') return 'Misafir';
    if (p) return p.replace('.com', '').replace('.', ' ').replace(/\b\w/g, c => c.toUpperCase());
    return user.email && user.email !== 'N/A' ? 'E-posta/Şifre' : 'Bilinmiyor';
}

window.renderUserRows = function (users) {
    const tbody = document.getElementById('userListBody');
    if (!tbody) return;
    if (!users.length) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:2rem; color:var(--text-muted)">Kullanıcı bulunamadı.</td></tr>';
        return;
    }
    tbody.innerHTML = users.map(user => {
        const isPremium = user.isPremium === true;
        const accountType = getAccountType(user);
        const accountTypeLabel = accountType === 'guest' ? 'Misafir' : 'E-posta';
        const platformType = getPlatformType(user);
        const platformLabel = getPlatformLabel(user);
        const loginMethodLabel = getLoginMethodLabel(user);
        const statusBadge = isPremium
            ? `<span style="background:rgba(234, 179, 8, 0.1); color:#eab308; padding:2px 8px; border-radius:12px; font-size:0.75rem; font-weight:bold">PREMIUM</span>`
            : `<span style="background:rgba(148, 163, 184, 0.1); color:#94a3b8; padding:2px 8px; border-radius:12px; font-size:0.75rem; font-weight:bold">FREE</span>`;
        const accountTypeBadge = accountType === 'guest'
            ? `<span style="background:rgba(251, 146, 60, 0.14); color:#fb923c; padding:2px 8px; border-radius:12px; font-size:0.72rem; font-weight:700">MİSAFİR</span>`
            : `<span style="background:rgba(34, 197, 94, 0.14); color:#22c55e; padding:2px 8px; border-radius:12px; font-size:0.72rem; font-weight:700">MAİLLİ</span>`;
        const platformBadge = platformType === 'android'
            ? `<span style="background:rgba(59, 130, 246, 0.14); color:#60a5fa; padding:2px 8px; border-radius:12px; font-size:0.72rem; font-weight:700">ANDROID</span>`
            : platformType === 'ios'
                ? `<span style="background:rgba(148, 163, 184, 0.14); color:#e2e8f0; padding:2px 8px; border-radius:12px; font-size:0.72rem; font-weight:700">iOS</span>`
                : `<span style="background:rgba(148, 163, 184, 0.14); color:#94a3b8; padding:2px 8px; border-radius:12px; font-size:0.72rem; font-weight:700">DİĞER</span>`;
        const photo = `<div style="width:32px; height:32px; border-radius:50%; background:var(--accent); color:white; display:grid; place-items:center; font-weight:bold">${(user.displayName || '?').charAt(0).toUpperCase()}</div>`;
        const lastLogin = user.lastLogin
            ? new Date(user.lastLogin).toLocaleDateString('tr-TR', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
            : (user.createdAt ? new Date(user.createdAt).toLocaleDateString('tr-TR') : '-');
        return `
            <tr style="border-bottom:1px solid var(--border)">
                <td style="padding:1rem">
                    <div style="display:flex; align-items:center; gap:0.75rem">
                        ${photo}
                        <div>
                            <div style="font-weight:500">${user.displayName}</div>
                            <div style="font-size:0.8rem; color:var(--text-muted)">${accountTypeLabel} · ${platformLabel} · ${loginMethodLabel}</div>
                        </div>
                    </div>
                </td>
                <td style="padding:1rem; color:var(--text-muted)">${accountType === 'guest' ? '-' : user.email}</td>
                <td style="padding:1rem">${statusBadge}</td>
                <td style="padding:1rem; font-size:0.9rem">${lastLogin}</td>
                <td style="padding:1rem; font-family:monospace; font-size:0.75rem; color:var(--text-muted)">${user.uid.substring(0, 12)}...</td>
                <td style="padding:1rem">
                    <div style="display:flex; gap:6px; flex-wrap:wrap;">
                        ${accountTypeBadge}
                        ${platformBadge}
                        <span style="background:rgba(99, 102, 241, 0.14); color:#a5b4fc; padding:2px 8px; border-radius:12px; font-size:0.72rem; font-weight:700">${loginMethodLabel.toUpperCase()}</span>
                        <button onclick="showUserDetails('${user.uid}')" style="padding:6px 12px; font-size:0.75rem; background:var(--bg); color:var(--text); border:1px solid var(--border); border-radius:6px; cursor:pointer; font-weight:600;">
                            <span class="material-icons-round" style="font-size:14px; vertical-align:middle;">visibility</span>
                            DETAY
                        </button>
                        ${!isPremium ? `
                            <button onclick="togglePremium('${user.uid}', true)" style="padding:6px 12px; font-size:0.75rem; background:linear-gradient(135deg, #6366f1, #4f46e5); color:white; border:none; border-radius:6px; cursor:pointer; font-weight:600;">
                                PREMIUM YAP
                            </button>
                        ` : `
                            <button onclick="togglePremium('${user.uid}', false)" style="padding:6px 12px; font-size:0.75rem; background:rgba(239, 68, 68, 0.1); color:#ef4444; border:1px solid rgba(239, 68, 68, 0.3); border-radius:6px; cursor:pointer; font-weight:600">
                                İPTAL ET
                            </button>
                        `}
                    </div>
                </td>
            </tr>
        `;
    }).join('');
};

window.filterUsers = function () {
    const q = (document.getElementById('userSearchInput')?.value || '').toLowerCase().trim();
    const filter = document.getElementById('userStatusFilter')?.value || 'all';
    const accountTypeFilter = document.getElementById('userAccountTypeFilter')?.value || 'all';
    const platformFilter = document.getElementById('userPlatformFilter')?.value || 'all';
    let filtered = _allUsers;
    if (q) {
        filtered = filtered.filter(u =>
            (u.displayName || '').toLowerCase().includes(q) ||
            (u.email || '').toLowerCase().includes(q) ||
            (u.uid || '').toLowerCase().includes(q)
        );
    }
    if (filter === 'premium') filtered = filtered.filter(u => u.isPremium === true);
    if (filter === 'free') filtered = filtered.filter(u => !u.isPremium);
    if (accountTypeFilter === 'guest') filtered = filtered.filter(u => getAccountType(u) === 'guest');
    if (accountTypeFilter === 'email') filtered = filtered.filter(u => getAccountType(u) === 'email');
    if (platformFilter === 'android') filtered = filtered.filter(u => getPlatformType(u) === 'android');
    if (platformFilter === 'ios') filtered = filtered.filter(u => getPlatformType(u) === 'ios');
    const countEl = document.getElementById('userCount');
    if (countEl) countEl.textContent = `${filtered.length} / ${_allUsers.length} kullanıcı`;
    renderUserRows(filtered);
};

window.loadUsers = async function () {
    const tbody = document.getElementById('userListBody');
    if (!tbody) return;

    // Arama alanı ve filtre yoksa ekle
    const tableWrapper = tbody.closest('table')?.parentElement;
    if (tableWrapper && !document.getElementById('userSearchInput')) {
        const toolbar = document.createElement('div');
        toolbar.style.cssText = 'display:flex;gap:0.75rem;align-items:center;padding:0.85rem 0 1rem 0;flex-wrap:wrap;';
        toolbar.innerHTML = `
            <div style="position:relative;flex:1;min-width:200px;">
                <span class="material-icons-round" style="position:absolute;left:0.65rem;top:50%;transform:translateY(-50%);font-size:1.1rem;color:#64748b;pointer-events:none;">search</span>
                <input id="userSearchInput" type="text" placeholder="İsim, e-posta veya UID ara..."
                    oninput="filterUsers()"
                    style="width:100%;padding:0.55rem 0.75rem 0.55rem 2.3rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;color:var(--text);font-size:0.88rem;box-sizing:border-box;">
            </div>
            <select id="userStatusFilter" onchange="filterUsers()"
                style="padding:0.55rem 0.85rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;color:var(--text);font-size:0.88rem;cursor:pointer;">
                <option value="all">Tümü</option>
                <option value="premium">Premium</option>
                <option value="free">Free</option>
            </select>
            <select id="userAccountTypeFilter" onchange="filterUsers()"
                style="padding:0.55rem 0.85rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;color:var(--text);font-size:0.88rem;cursor:pointer;">
                <option value="all">Tüm Hesaplar</option>
                <option value="email">Mailli Kullanıcı</option>
                <option value="guest">Misafir Kullanıcı</option>
            </select>
            <select id="userPlatformFilter" onchange="filterUsers()"
                style="padding:0.55rem 0.85rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;color:var(--text);font-size:0.88rem;cursor:pointer;">
                <option value="all">Tüm Platformlar</option>
                <option value="android">Android</option>
                <option value="ios">iOS</option>
            </select>
            <span id="userCount" style="font-size:0.82rem;color:#64748b;white-space:nowrap;"></span>
            <button onclick="loadUsers()" title="Yenile"
                style="padding:0.55rem 0.7rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;color:var(--text-muted);cursor:pointer;">
                <span class="material-icons-round" style="font-size:1rem;vertical-align:middle;">refresh</span>
            </button>
        `;
        tableWrapper.insertBefore(toolbar, tableWrapper.querySelector('table'));
    }

    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:2rem; color:var(--text-muted)">Yükleniyor...</td></tr>';

    try {
        const response = await fetch(API + '/users');
        const data = await response.json();

        if (data.error) throw new Error(data.error);
        if (!data.users || data.users.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:2rem; color:var(--text-muted)">Kullanıcı bulunamadı.</td></tr>';
            return;
        }

        _allUsers = data.users;
        filterUsers();

    } catch (e) {
        console.error(e);
        tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:2rem; color:#ef4444">Hata: ${e.message}</td></tr>`;
    }
};

window.togglePremium = async function (uid, makePremium) {
    if (!makePremium) {
        // İptal işlemi - direkt onayla
        if (!confirm('Premium yetkisi iptal edilsin mi?')) return;
        showToast('İşlem yapılıyor...', 'info');
        try {
            const res = await fetch(API + '/users/premium', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ uid, isPremium: false })
            });
            const data = await res.json();
            if (data.success) { showToast('Premium iptal edildi', 'success'); loadUsers(); }
            else showToast('Hata: ' + data.error, 'error');
        } catch (e) { showToast('Bağlantı hatası', 'error'); }
        return;
    }

    // Premium aktifleştirme - plan seç
    const existingModal = document.getElementById('quickPremiumModal');
    if (existingModal) existingModal.remove();

    const modal = document.createElement('div');
    modal.id = 'quickPremiumModal';
    modal.style.cssText = 'position:fixed;inset:0;background:rgba(0,0,0,0.7);z-index:20000;display:flex;align-items:center;justify-content:center;padding:1rem';
    modal.innerHTML = `
        <div style="background:#1e293b;border:1px solid #334155;border-radius:14px;max-width:380px;width:100%;padding:1.5rem">
            <h3 style="margin:0 0 1rem 0;color:#f8fafc;font-size:1rem;display:flex;align-items:center;gap:0.5rem">
                <span class="material-icons-round" style="color:#eab308">workspace_premium</span>
                Premium Plan Seç
            </h3>
            <div style="display:grid;grid-template-columns:repeat(3,1fr);gap:0.6rem;margin-bottom:1rem">
                <button onclick="_applyQuickPlan('${uid}', 1)" style="padding:0.75rem 0.4rem;background:#0f172a;border:2px solid #334155;border-radius:8px;color:#e2e8f0;cursor:pointer;text-align:center">
                    <div style="font-size:1.3rem;font-weight:700;color:#eab308">1</div>
                    <div style="font-size:0.7rem;color:#94a3b8">Aylık</div>
                </button>
                <button onclick="_applyQuickPlan('${uid}', 3)" style="padding:0.75rem 0.4rem;background:#0f172a;border:2px solid #334155;border-radius:8px;color:#e2e8f0;cursor:pointer;text-align:center;position:relative">
                    <div style="position:absolute;top:-6px;right:4px;background:#10b981;color:white;font-size:0.55rem;padding:2px 5px;border-radius:8px">%10</div>
                    <div style="font-size:1.3rem;font-weight:700;color:#eab308">3</div>
                    <div style="font-size:0.7rem;color:#94a3b8">3 Aylık</div>
                </button>
                <button onclick="_applyQuickPlan('${uid}', 12)" style="padding:0.75rem 0.4rem;background:#0f172a;border:2px solid #334155;border-radius:8px;color:#e2e8f0;cursor:pointer;text-align:center;position:relative">
                    <div style="position:absolute;top:-6px;right:4px;background:#10b981;color:white;font-size:0.55rem;padding:2px 5px;border-radius:8px">%25</div>
                    <div style="font-size:1.3rem;font-weight:700;color:#eab308">12</div>
                    <div style="font-size:0.7rem;color:#94a3b8">Yıllık</div>
                </button>
            </div>
            <button onclick="document.getElementById('quickPremiumModal').remove()" style="width:100%;padding:0.6rem;background:transparent;border:1px solid #475569;border-radius:6px;color:#94a3b8;cursor:pointer">İptal</button>
        </div>
    `;
    modal.addEventListener('click', e => { if (e.target === modal) modal.remove(); });
    document.body.appendChild(modal);
};

window._applyQuickPlan = async function (uid, months) {
    document.getElementById('quickPremiumModal')?.remove();
    const startDate = new Date().toISOString().split('T')[0];
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + months);
    const endDateStr = endDate.toISOString().split('T')[0];
    const premiumType = months === 1 ? 'monthly' : months === 3 ? 'quarterly' : 'yearly';

    showToast('Premium aktif ediliyor...', 'info');
    try {
        const res = await fetch(API + '/users/premium', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ uid, isPremium: true, premiumType, premiumStartDate: startDate, premiumEndDate: endDateStr })
        });
        const data = await res.json();
        if (data.success) { showToast(`Premium aktif edildi (${months} ay)`, 'success'); loadUsers(); }
        else showToast('Hata: ' + data.error, 'error');
    } catch (e) { showToast('Bağlantı hatası', 'error'); }
};

// ══════════════════════════════════════════════════════════════════════════
// USER DETAILS MODAL
// ══════════════════════════════════════════════════════════════════════════
window.showUserDetails = async function (uid) {
    let modal = document.getElementById('userDetailModal');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'userDetailModal';
        modal.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.7); z-index: 10000; display: none;
            align-items: center; justify-content: center; padding: 20px;
        `;
        modal.innerHTML = `
            <div style="background: var(--card); border-radius: 16px; max-width: 900px; width: 100%; max-height: 90vh; overflow: hidden; display: flex; flex-direction: column; box-shadow: 0 25px 50px rgba(0,0,0,0.5);">
                <div style="padding: 24px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center;">
                    <h2 style="margin: 0; font-size: 1.25rem; display: flex; align-items: center; gap: 10px;">
                        <span class="material-icons-round" style="color: var(--primary);">person</span>
                        Kullanıcı Detayları
                    </h2>
                    <button onclick="closeUserDetailModal()" style="background: none; border: none; color: var(--text-muted); cursor: pointer; padding: 8px; border-radius: 8px;">
                        <span class="material-icons-round">close</span>
                    </button>
                </div>
                <div id="userDetailContent" style="padding: 24px; overflow-y: auto; flex: 1;">
                    <div style="text-align: center; color: var(--text-muted); padding: 40px;">
                        <span class="material-icons-round" style="font-size: 48px; opacity: 0.3; animation: spin 1s linear infinite;">sync</span>
                        <p>Yükleniyor...</p>
                    </div>
                </div>
            </div>
        `;
        document.body.appendChild(modal);
        modal.addEventListener('click', (e) => {
            if (e.target === modal) closeUserDetailModal();
        });
    }
    modal.style.display = 'flex';
    document.body.style.overflow = 'hidden';
    await loadUserDetails(uid);
};

window.closeUserDetailModal = function () {
    const modal = document.getElementById('userDetailModal');
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = '';
    }
};

window.loadUserDetails = async function (uid) {
    const content = document.getElementById('userDetailContent');
    content.dataset.uid = uid;
    try {
        const res = await fetch(API + '/users/' + uid + '/details');
        const data = await res.json();
        if (!data.success) {
            content.innerHTML = `<div style="color: #ef4444; text-align: center; padding: 40px;">Hata: ${data.error}</div>`;
            return;
        }
        const u = data.user;
        const formatDate = (d) => d ? new Date(d).toLocaleString('tr-TR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-';
        const formatDateInput = (d) => {
            if (!d) return '';
            const date = new Date(d);
            return date.toISOString().split('T')[0];
        };
        const isPremium = u.isPremium;

        // Calculate days left properly
        let daysLeft = 0;
        if (u.premiumEndDate && isPremium) {
            const end = new Date(u.premiumEndDate);
            const now = new Date();
            const diffTime = end - now;
            daysLeft = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
        }

        const statusColor = daysLeft > 7 ? '#10b981' : daysLeft > 0 ? '#f59e0b' : '#ef4444';
        const statusBg = daysLeft > 7 ? 'rgba(16, 185, 129, 0.1)' : daysLeft > 0 ? 'rgba(245, 158, 11, 0.1)' : 'rgba(239, 68, 68, 0.1)';
        const statusBorder = daysLeft > 7 ? 'rgba(16, 185, 129, 0.3)' : daysLeft > 0 ? 'rgba(245, 158, 11, 0.3)' : 'rgba(239, 68, 68, 0.3)';
        const platformType = getPlatformType(u);
        const platformLabel = getPlatformLabel(u);
        const loginMethodLabel = getLoginMethodLabel(u);
        const platformIcon = platformType === 'ios' ? 'phone_iphone' : platformType === 'android' ? 'phone_android' : 'devices';

        content.innerHTML = `
        <!-- Profil Kartı -->
        <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 20px; padding: 16px; background: var(--bg); border-radius: 12px; border: 1px solid var(--border);">
            <div style="width: 56px; height: 56px; border-radius: 50%; background: linear-gradient(135deg, var(--primary), var(--accent)); display: grid; place-items: center; font-size: 22px; font-weight: bold; color: white;">${(u.displayName || '?').charAt(0).toUpperCase()}</div>
            <div style="flex: 1; min-width: 0;">
                <div style="display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
                    <h3 style="margin: 0; font-size: 1.1rem; font-weight: 600;">${u.displayName || 'İsimsiz Kullanıcı'}</h3>
                    <span style="background: ${isPremium ? 'rgba(234, 179, 8, 0.2)' : 'rgba(148, 163, 184, 0.2)'}; color: ${isPremium ? '#eab308' : '#94a3b8'}; padding: 3px 10px; border-radius: 20px; font-size: 0.7rem; font-weight: 600; border: 1px solid ${isPremium ? 'rgba(234, 179, 8, 0.3)' : 'rgba(148, 163, 184, 0.3)'};">${isPremium ? '⭐ PREMIUM' : 'FREE'}</span>
                </div>
                <div style="color: var(--text-muted); font-size: 0.8rem; margin-top: 4px; overflow: hidden; text-overflow: ellipsis;">${u.email || 'Email yok'}</div>
                <div style="display: flex; gap: 12px; margin-top: 6px; font-size: 0.75rem; color: var(--text-muted);">
                    <span><span class="material-icons-round" style="font-size: 12px; vertical-align: middle; margin-right: 2px;">${platformIcon}</span>${platformLabel}</span>
                    <span><span class="material-icons-round" style="font-size: 12px; vertical-align: middle; margin-right: 2px;">login</span>${loginMethodLabel}</span>
                    <span>Kayıt: ${formatDate(u.createdAt).split(' ')[0]}</span>
                </div>
            </div>
        </div>

        <!-- Premium Yönetim Paneli -->
        <div style="background: linear-gradient(135deg, rgba(234, 179, 8, 0.05), rgba(234, 179, 8, 0.02)); border: 1px solid rgba(234, 179, 8, 0.25); border-radius: 14px; padding: 18px; margin-bottom: 16px;">
            <h4 style="margin: 0 0 14px 0; display: flex; align-items: center; gap: 8px; color: #eab308; font-size: 0.95rem;">
                <span class="material-icons-round" style="font-size: 20px;">workspace_premium</span>
                Premium Yönetimi
            </h4>
            
            <!-- Hızlı Plan Butonları -->
            <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin-bottom: 16px;">
                <button onclick="setPremiumPlan('${uid}', 1)" style="padding: 12px 8px; background: var(--bg-card); border: 2px solid var(--border); border-radius: 10px; cursor: pointer; text-align: center; transition: all 0.2s;">
                    <div style="font-size: 1.4rem; font-weight: 700; color: #eab308;">1</div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">Aylık</div>
                </button>
                <button onclick="setPremiumPlan('${uid}', 3)" style="padding: 12px 8px; background: var(--bg-card); border: 2px solid var(--border); border-radius: 10px; cursor: pointer; text-align: center; position: relative;">
                    <div style="position: absolute; top: -6px; right: 6px; background: #10b981; color: white; font-size: 0.6rem; padding: 2px 6px; border-radius: 10px; font-weight: 600;">%10</div>
                    <div style="font-size: 1.4rem; font-weight: 700; color: #eab308;">3</div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">3 Aylık</div>
                </button>
                <button onclick="setPremiumPlan('${uid}', 12)" style="padding: 12px 8px; background: var(--bg-card); border: 2px solid var(--border); border-radius: 10px; cursor: pointer; text-align: center; position: relative;">
                    <div style="position: absolute; top: -6px; right: 6px; background: #10b981; color: white; font-size: 0.6rem; padding: 2px 6px; border-radius: 10px; font-weight: 600;">%25</div>
                    <div style="font-size: 1.4rem; font-weight: 700; color: #eab308;">12</div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">Yıllık</div>
                </button>
            </div>

            <!-- Manuel Tarih Ayarlama -->
            <div style="background: var(--bg-card); border-radius: 10px; padding: 14px; margin-bottom: 14px; border: 1px solid var(--border);">
                <div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 10px; font-weight: 500;">Manuel Tarih Ayarlama</div>
                <div style="display: grid; grid-template-columns: 1fr 1fr auto; gap: 10px; align-items: end;">
                    <div>
                        <label style="display: block; font-size: 0.7rem; color: var(--text-muted); margin-bottom: 4px;">Başlangıç</label>
                        <input type="date" id="premStart_${uid}" value="${formatDateInput(u.premiumStartDate) || new Date().toISOString().split('T')[0]}" style="width: 100%; padding: 8px 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 6px; color: var(--text); font-size: 0.85rem; box-sizing: border-box;">
                    </div>
                    <div>
                        <label style="display: block; font-size: 0.7rem; color: var(--text-muted); margin-bottom: 4px;">Bitiş</label>
                        <input type="date" id="premEnd_${uid}" value="${formatDateInput(u.premiumEndDate)}" style="width: 100%; padding: 8px 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 6px; color: var(--text); font-size: 0.85rem; box-sizing: border-box;">
                    </div>
                    <button onclick="savePremiumDates('${uid}')" style="padding: 8px 14px; background: linear-gradient(135deg, #eab308, #ca8a04); color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem; white-space: nowrap;">
                        Kaydet
                    </button>
                </div>
            </div>

            <!-- Mevcut Durum & Toggle -->
            <div style="display: flex; justify-content: space-between; align-items: center; padding: 12px 14px; background: ${statusBg}; border-radius: 10px; border: 1px solid ${statusBorder}; margin-bottom: 16px;">
                <div>
                    <div style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 2px;">Mevcut Durum</div>
                    <div style="font-weight: 600; color: ${isPremium ? statusColor : '#ef4444'}; font-size: 0.95rem;">
                        ${isPremium ? (daysLeft > 0 ? `${daysLeft} gün kaldı` : 'Süre doldu') : 'Premium Pasif'}
                    </div>
                </div>
                <button onclick="togglePremiumModal('${uid}', ${!isPremium})" style="padding: 8px 14px; background: ${isPremium ? '#ef4444' : '#10b981'}; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: 600; font-size: 0.85rem;">
                    ${isPremium ? 'İptal Et' : 'Aktif Et'}
                </button>
            </div>
        </div>

        <!-- Admin Notları -->
        <div style="background: var(--bg-card); border-radius: 12px; padding: 16px; margin-bottom: 16px; border: 1px solid var(--border);">
            <h4 style="margin: 0 0 12px 0; display: flex; align-items: center; gap: 8px; font-size: 0.95rem;">
                <span class="material-icons-round" style="color: var(--primary);">sticky_note_2</span>
                Admin Notları
            </h4>
            <textarea id="adminNote_${uid}" placeholder="Kullanıcı hakkında not ekle..." style="width: 100%; padding: 10px; background: var(--bg); border: 1px solid var(--border); border-radius: 8px; color: var(--text); font-size: 0.9rem; min-height: 80px; resize: vertical; box-sizing: border-box;">${u.adminNote || ''}</textarea>
            <div style="display: flex; justify-content: flex-end; margin-top: 8px;">
                <button onclick="saveAdminNote('${uid}')" style="padding: 6px 14px; background: var(--primary); color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 0.85rem;">
                    Notu Kaydet
                </button>
            </div>
        </div>

        <!-- Premium Geçmişi -->
        ${u.premiumHistory?.length > 0 ? `
        <div style="background: var(--bg-card); border-radius: 12px; padding: 16px; border: 1px solid var(--border);">
            <h4 style="margin: 0 0 12px 0; display: flex; align-items: center; gap: 8px; font-size: 0.95rem;">
                <span class="material-icons-round" style="color: #eab308;">history</span>
                Premium Geçmişi
            </h4>
            <div style="max-height: 200px; overflow-y: auto;">
                ${u.premiumHistory.map(h => `
                    <div style="display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid var(--border);">
                        <span class="material-icons-round" style="color: ${h.isPremium ? '#eab308' : '#94a3b8'}; font-size: 18px;">
                            ${h.isPremium ? 'workspace_premium' : 'remove_circle'}
                        </span>
                        <div style="flex: 1;">
                            <div style="font-weight: 500; font-size: 0.9rem;">${h.action || (h.isPremium ? 'Premium Yapıldı' : 'Premium İptal')}</div>
                            <div style="color: var(--text-muted); font-size: 0.75rem;">${formatDate(h.changedAt)} • ${h.adminName || 'Sistem'}</div>
                        </div>
                        <span style="background: ${h.isPremium ? 'rgba(234, 179, 8, 0.15)' : 'rgba(148, 163, 184, 0.15)'}; color: ${h.isPremium ? '#eab308' : '#94a3b8'}; padding: 2px 8px; border-radius: 12px; font-size: 0.7rem; font-weight: 600;">
                            ${h.isPremium ? 'AKTİF' : 'PASİF'}
                        </span>
                    </div>
                `).join('')}
            </div>
        </div>
        ` : '<p style="color: var(--text-muted); text-align: center; padding: 20px; font-size: 0.9rem;">Premium geçmişi bulunmuyor.</p>'}
        `;
    } catch (e) {
        content.innerHTML = `<div style="color: #ef4444; text-align: center; padding: 40px;">Hata: ${e.message}</div>`;
    }
};

// Premium plan seçimi
window.setPremiumPlan = async function (uid, months) {
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + months);

    document.getElementById('premStart_' + uid).value = new Date().toISOString().split('T')[0];
    document.getElementById('premEnd_' + uid).value = endDate.toISOString().split('T')[0];

    // premiumType'ı ay sayısına göre belirle
    const premiumType = months === 1 ? 'monthly' : months === 3 ? 'quarterly' : 'yearly';
    await savePremiumDates(uid, true, premiumType);
};

// Premium tarihlerini kaydet
window.savePremiumDates = async function (uid, isSilent = false, premiumType = null) {
    const startDate = document.getElementById('premStart_' + uid)?.value;
    const endDate = document.getElementById('premEnd_' + uid)?.value;

    if (!startDate || !endDate) {
        if (!isSilent) showToast('Başlangıç ve bitiş tarihleri gereklidir', 'error');
        return;
    }

    // premiumType verilmemişse tarih farkından otomatik tahmin et
    if (!premiumType && startDate && endDate) {
        const diffDays = Math.round((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24));
        premiumType = diffDays <= 35 ? 'monthly' : diffDays <= 100 ? 'quarterly' : 'yearly';
    }

    try {
        const res = await fetch(API + '/users/premium', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                uid,
                isPremium: true,
                premiumType,
                premiumStartDate: startDate,
                premiumEndDate: endDate
            })
        });
        const data = await res.json();

        if (data.success) {
            if (!isSilent) showToast('Premium tarihleri güncellendi', 'success');
            await loadUserDetails(uid);
            loadUsers();
        } else {
            if (!isSilent) showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        if (!isSilent) showToast('Bağlantı hatası', 'error');
    }
};

// Modal içindeki premium toggle
window.togglePremiumModal = async function (uid, makePremium) {
    const action = makePremium ? 'Premium aktif edilsin mi?' : 'Premium iptal edilsin mi?';
    if (!confirm(action)) return;

    try {
        const res = await fetch(API + '/users/premium', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ uid, isPremium: makePremium })
        });
        const data = await res.json();

        if (data.success) {
            showToast(makePremium ? 'Premium aktif edildi' : 'Premium iptal edildi', 'success');
            await loadUserDetails(uid);
            loadUsers();
        } else {
            showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

// Admin notunu kaydet
window.saveAdminNote = async function (uid) {
    const note = document.getElementById('adminNote_' + uid)?.value;

    try {
        const res = await fetch(API + '/users/' + uid + '/note', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ note })
        });
        const data = await res.json();

        if (data.success) {
            showToast('Not kaydedildi', 'success');
        } else {
            showToast('Hata: ' + data.error, 'error');
        }
    } catch (e) {
        showToast('Bağlantı hatası', 'error');
    }
};

// ══════════════════════════════════════════════════════════════════════════
// REPORTS LOGIC
// ══════════════════════════════════════════════════════════════════════════

window._allReports = [];
window._reportsTypeMap = {
    'wrong_answer': { label: 'Yanlış Cevap',     color: '#ef4444', icon: 'close',         bg: 'rgba(239,68,68,0.1)'   },
    'typo':         { label: 'Yazım Hatası',      color: '#3b82f6', icon: 'spellcheck',    bg: 'rgba(59,130,246,0.1)'  },
    'wrong_topic':  { label: 'Yanlış Konu',       color: '#f59e0b', icon: 'category',      bg: 'rgba(245,158,11,0.1)'  },
    'unclear':      { label: 'Anlaşılmıyor',      color: '#8b5cf6', icon: 'help_outline',  bg: 'rgba(139,92,246,0.1)'  },
    'duplicate':    { label: 'Tekrar Eden Soru',  color: '#ec4899', icon: 'content_copy',  bg: 'rgba(236,72,153,0.1)'  },
    'other':        { label: 'Diğer',             color: '#64748b', icon: 'more_horiz',    bg: 'rgba(100,116,139,0.1)' }
};

window.loadReports = async function () {
    const el = document.getElementById('reportsList');
    if (!el) return;
    el.innerHTML = '<div style="padding:1rem; color:var(--text-muted)">Yükleniyor...</div>';

    try {
        const res = await fetch(API + '/reports');
        if (!res.ok) {
            el.innerHTML = '<div style="padding:1rem; color:#ef4444">Sunucu hatası: ' + res.status + '</div>';
            return;
        }
        window._allReports = (await res.json()) || [];
        window._renderReports();
    } catch (e) {
        el.innerHTML = `<div style="padding:1rem; color:#ef4444">Hata: ${e.message}</div>`;
    }
};

window._renderReports = function () {
    const el = document.getElementById('reportsList');
    if (!el) return;

    const TYPE_MAP = window._reportsTypeMap;
    const reports  = window._allReports;

    // Aktif filtreler (render sonrası seçili kalsın)
    const filterType   = document.getElementById('reportFilterType')?.value   || '';
    const filterStatus = document.getElementById('reportFilterStatus')?.value || '';

    let filtered = reports;
    if (filterType)   filtered = filtered.filter(r => r.reportType === filterType);
    if (filterStatus === 'pending')  filtered = filtered.filter(r => !r.status || r.status === 'pending');
    else if (filterStatus) filtered = filtered.filter(r => r.status === filterStatus);

    // İstatistikler
    const total    = reports.length;
    const pending  = reports.filter(r => !r.status || r.status === 'pending').length;
    const resolved = reports.filter(r => r.status === 'resolved').length;
    const rejected = reports.filter(r => r.status === 'rejected').length;

    const statsHtml = `
        <div style="display:flex; gap:0.75rem; flex-wrap:wrap; margin-bottom:1.25rem;">
            ${[
                { label: 'Toplam',     value: total,    color: '#94a3b8', bg: 'rgba(148,163,184,0.1)' },
                { label: 'Bekleyen',   value: pending,  color: '#f59e0b', bg: 'rgba(245,158,11,0.1)'  },
                { label: 'Çözüldü',   value: resolved, color: '#10b981', bg: 'rgba(16,185,129,0.1)'  },
                { label: 'Reddedildi', value: rejected, color: '#ef4444', bg: 'rgba(239,68,68,0.1)'   }
            ].map(s => `
                <div style="flex:1; min-width:90px; background:${s.bg}; border:1px solid ${s.color}33; border-radius:10px; padding:0.75rem 1rem; text-align:center;">
                    <div style="font-size:1.6rem; font-weight:700; color:${s.color};">${s.value}</div>
                    <div style="font-size:0.75rem; color:var(--text-muted);">${s.label}</div>
                </div>
            `).join('')}
        </div>`;

    const filtersHtml = `
        <div style="display:flex; gap:0.75rem; flex-wrap:wrap; align-items:center; margin-bottom:1.25rem; padding:0.85rem 1rem; background:var(--card,#1e293b); border:1px solid var(--border); border-radius:10px;">
            <select id="reportFilterType" onchange="window._renderReports()"
                style="padding:0.45rem 0.75rem; background:var(--bg,#0f172a); border:1px solid var(--border); border-radius:7px; color:var(--text); font-size:0.85rem; cursor:pointer;">
                <option value="">Tüm Türler</option>
                ${Object.entries(TYPE_MAP).map(([k, v]) => `<option value="${k}" ${filterType===k?'selected':''}>${v.label}</option>`).join('')}
            </select>
            <select id="reportFilterStatus" onchange="window._renderReports()"
                style="padding:0.45rem 0.75rem; background:var(--bg,#0f172a); border:1px solid var(--border); border-radius:7px; color:var(--text); font-size:0.85rem; cursor:pointer;">
                <option value="">Tüm Durumlar</option>
                <option value="pending"  ${filterStatus==='pending' ?'selected':''}>⏳ Bekleyen</option>
                <option value="resolved" ${filterStatus==='resolved'?'selected':''}>✅ Çözüldü</option>
                <option value="rejected" ${filterStatus==='rejected'?'selected':''}>❌ Reddedildi</option>
            </select>
            <span style="font-size:0.82rem; color:var(--text-muted); margin-left:auto;">${filtered.length} rapor</span>
        </div>`;

    const cardsHtml = filtered.length === 0
        ? '<div style="padding:2rem; text-align:center; color:var(--text-muted);">Rapor bulunamadı.</div>'
        : filtered.map((r, i) => {
            const typeInfo  = TYPE_MAP[r.reportType] || TYPE_MAP['other'];
            const dateStr   = new Date(r.receivedAt || r.timestamp || r.createdAt).toLocaleString('tr-TR');
            const status    = r.status || 'pending';
            const statusBadge =
                status === 'resolved' ? `<span style="background:rgba(16,185,129,0.15);color:#10b981;padding:2px 10px;border-radius:20px;font-size:0.72rem;font-weight:600;">✅ Çözüldü</span>` :
                status === 'rejected' ? `<span style="background:rgba(239,68,68,0.15);color:#ef4444;padding:2px 10px;border-radius:20px;font-size:0.72rem;font-weight:600;">❌ Reddedildi</span>` :
                                        `<span style="background:rgba(245,158,11,0.15);color:#f59e0b;padding:2px 10px;border-radius:20px;font-size:0.72rem;font-weight:600;">⏳ Bekleyen</span>`;

            const rId  = (r.id  || '').replace(/'/g, "\\'");
            const qId  = (r.questionId || '').replace(/'/g, "\\'");
            const rAt  = (r.receivedAt || r.timestamp || '').replace(/'/g, "\\'");

            return `
            <div id="reportCard-${i}" style="background:var(--card,#1e293b); border:1px solid var(--border); border-left:3px solid ${typeInfo.color}; border-radius:12px; padding:1.25rem; margin-bottom:0.75rem; ${status !== 'pending' ? 'opacity:0.72;' : ''}">

                <!-- Başlık satırı -->
                <div style="display:flex; align-items:center; gap:0.65rem; flex-wrap:wrap; margin-bottom:0.9rem;">
                    <div style="width:36px;height:36px;background:${typeInfo.bg};color:${typeInfo.color};border-radius:8px;display:grid;place-items:center;flex-shrink:0;">
                        <span class="material-icons-round" style="font-size:1.2rem;">${typeInfo.icon}</span>
                    </div>
                    <div>
                        <div style="font-weight:700; color:var(--text); font-size:0.95rem;">${typeInfo.label}</div>
                        <div style="font-size:0.75rem; color:var(--text-muted);">${dateStr}</div>
                    </div>
                    ${statusBadge}
                </div>

                <!-- Bilgi grid -->
                <div style="display:grid; grid-template-columns:auto 1fr; gap:0.35rem 1rem; font-size:0.87rem; margin-bottom:0.85rem;">
                    <span style="color:var(--text-muted);">Soru ID</span>
                    <span style="font-family:monospace; color:#6366f1; font-weight:600; cursor:pointer;"
                        onclick="navigator.clipboard.writeText('${r.questionId}'); showToast('ID kopyalandı', 'success')">
                        ${r.questionId}
                        <span class="material-icons-round" style="font-size:11px;vertical-align:middle;opacity:0.5;">content_copy</span>
                    </span>
                    ${r.userName || r.userEmail ? `
                    <span style="color:var(--text-muted);">Kullanıcı</span>
                    <span style="color:var(--text);">
                        ${r.userName || ''}
                        ${r.userEmail ? `<span style="color:var(--text-muted);font-size:0.8rem;"> (${r.userEmail})</span>` : ''}
                        ${r.platform  ? `<span style="background:var(--bg,#0f172a);padding:1px 6px;border-radius:4px;font-size:0.7rem;margin-left:4px;">${r.platform}</span>` : ''}
                    </span>` : ''}
                </div>

                ${r.description ? `
                <div style="background:var(--bg,#0f172a); border-left:3px solid ${typeInfo.color}; padding:0.65rem 1rem; border-radius:0 7px 7px 0; font-size:0.9rem; color:var(--text-muted); font-style:italic; margin-bottom:0.85rem;">
                    "${r.description}"
                </div>` : ''}

                <!-- Inline soru önizleme alanı -->
                <div id="rqPreview-${i}" style="display:none; margin-bottom:0.85rem;"></div>

                <!-- Aksiyonlar -->
                <div style="display:flex; gap:0.5rem; flex-wrap:wrap;">
                    <button onclick="window._toggleRQPreview(${i}, '${qId}')"
                        style="padding:0.42rem 0.85rem; font-size:0.82rem; background:transparent; border:1px solid #6366f1; color:#a5b4fc; border-radius:7px; cursor:pointer; display:flex; align-items:center; gap:0.3rem;">
                        <span class="material-icons-round" style="font-size:0.95rem;">visibility</span> Soruyu Gör
                    </button>
                    <button onclick="viewReportQuestion('${qId}')"
                        style="padding:0.42rem 0.85rem; font-size:0.82rem; background:transparent; border:1px solid var(--border); color:var(--text); border-radius:7px; cursor:pointer; display:flex; align-items:center; gap:0.3rem;">
                        <span class="material-icons-round" style="font-size:0.95rem;">edit</span> Düzenle
                    </button>
                    ${status !== 'resolved' ? `
                    <button onclick="window._updateReportStatus(${i}, '${rId}', '${qId}', '${rAt}', 'resolved')"
                        style="padding:0.42rem 0.85rem; font-size:0.82rem; background:rgba(16,185,129,0.12); border:1px solid #10b981; color:#10b981; border-radius:7px; cursor:pointer; display:flex; align-items:center; gap:0.3rem;">
                        <span class="material-icons-round" style="font-size:0.95rem;">check_circle</span> Çözüldü
                    </button>` : ''}
                    ${status !== 'rejected' ? `
                    <button onclick="window._updateReportStatus(${i}, '${rId}', '${qId}', '${rAt}', 'rejected')"
                        style="padding:0.42rem 0.85rem; font-size:0.82rem; background:rgba(239,68,68,0.1); border:1px solid #ef4444; color:#ef4444; border-radius:7px; cursor:pointer; display:flex; align-items:center; gap:0.3rem;">
                        <span class="material-icons-round" style="font-size:0.95rem;">cancel</span> Reddet
                    </button>` : ''}
                    ${status !== 'pending' ? `
                    <button onclick="window._updateReportStatus(${i}, '${rId}', '${qId}', '${rAt}', 'pending')"
                        style="padding:0.42rem 0.85rem; font-size:0.78rem; background:transparent; border:1px solid var(--border); color:var(--text-muted); border-radius:7px; cursor:pointer;">
                        ↩ Geri Al
                    </button>` : ''}
                    <button onclick="window._deleteReportedQuestion('${qId}', ${i})"
                        style="padding:0.42rem 0.85rem; font-size:0.82rem; background:rgba(239,68,68,0.08); border:1px solid rgba(239,68,68,0.4); color:#f87171; border-radius:7px; cursor:pointer; display:flex; align-items:center; gap:0.3rem; margin-left:auto;">
                        <span class="material-icons-round" style="font-size:0.95rem;">delete_forever</span> Soruyu Sil
                    </button>
                    <button onclick="window._analyzeReportWithAI(${i})"
                        style="padding:0.42rem 0.85rem; font-size:0.82rem; background:linear-gradient(135deg,rgba(99,102,241,0.15),rgba(168,85,247,0.15)); border:1px solid rgba(99,102,241,0.5); color:#a78bfa; border-radius:7px; cursor:pointer; display:flex; align-items:center; gap:0.3rem;">
                        <span class="material-icons-round" style="font-size:0.95rem;">auto_awesome</span> AI Analiz
                    </button>
                </div>
                <!-- AI analiz sonuç alanı -->
                <div id="rqAiAnalysis-${i}" style="display:none; margin-top:0.75rem;"></div>
            </div>`;
        }).join('');

    el.innerHTML = statsHtml + filtersHtml + cardsHtml;
};

window._deleteReportedQuestion = async function (questionId, reportIndex) {
    if (!confirm(`⚠️ DİKKAT\n\n"${questionId}" sorusu veritabanından kalıcı olarak SİLİNECEK.\nBu işlem geri alınamaz!\n\nDevam?`)) return;

    try {
        // Önce sorunun hangi topic'te olduğunu bul
        const findRes = await fetch(`${API}/find-question?id=${encodeURIComponent(questionId)}`);
        const findData = await findRes.json();
        if (!findData.success) {
            // Soru zaten silinmiş olabilir — raporu çözüldü olarak işaretle
            if (!confirm(`Soru yerel veritabanında bulunamadı.\n\nBu soru daha önce silinmiş olabilir.\n\nİlgili raporu "Çözüldü" olarak işaretlemek ister misiniz?`)) return;
            const report = window._allReports[reportIndex];
            if (report) {
                const rId = report.id || '';
                const rAt = report.receivedAt || report.timestamp || '';
                await fetch(`${API}/reports`, {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ id: rId || undefined, questionId, receivedAt: rAt, status: 'resolved' })
                });
                report.status = 'resolved';
                window._renderReports();
                showToast('Rapor çözüldü olarak işaretlendi', 'success');
            }
            return;
        }

        const topicId = findData.topicId;
        const qId     = findData.question?.id || questionId;

        const delRes  = await fetch(`${API}/questions/${encodeURIComponent(topicId)}/${encodeURIComponent(qId)}`, { method: 'DELETE' });
        const delData = await delRes.json();
        if (!delData.success) throw new Error(delData.error || 'Silme başarısız');

        // Raporu da otomatik olarak çözüldü yap
        const report = window._allReports[reportIndex];
        if (report) {
            const rId = report.id || '';
            const rAt = report.receivedAt || report.timestamp || '';
            await fetch(`${API}/reports`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ id: rId || undefined, questionId, receivedAt: rAt, status: 'resolved' })
            });
            report.status = 'resolved';
        }

        showToast(`✅ Soru silindi: ${questionId}`, 'success');
        window._renderReports();
    } catch (e) {
        showToast('Silme hatası: ' + e.message, 'error');
    }
};

window._analyzeReportWithAI = async function (index) {
    const report = window._allReports[index];
    if (!report) return;

    const analysisEl = document.getElementById(`rqAiAnalysis-${index}`);
    if (!analysisEl) return;

    // Toggle: zaten açıksa kapat
    if (analysisEl.style.display !== 'none') {
        analysisEl.style.display = 'none';
        return;
    }

    analysisEl.innerHTML = `<div style="background:rgba(99,102,241,0.08);border:1px solid rgba(99,102,241,0.3);border-radius:10px;padding:1rem;color:#a78bfa;font-size:0.85rem;display:flex;align-items:center;gap:0.5rem;">
        <span class="material-icons-round" style="font-size:1rem;animation:spin 1s linear infinite;">refresh</span>
        AI analiz ediliyor...
    </div>`;
    analysisEl.style.display = 'block';

    try {
        // Önce soruyu bul
        let question = null;
        let topicInfo = null;
        const findRes = await fetch(`${API}/find-question?id=${encodeURIComponent(report.questionId || '')}`);
        if (findRes.ok) {
            const findData = await findRes.json();
            if (findData.success && findData.question) {
                question = findData.question;
                // topicInfo bul
                const TOPICS_CLIENT = window._reportsTypeMap ? null : null; // server'dan al
                topicInfo = findData.topicId ? { name: findData.topicId, lesson: '' } : null;
            }
        }

        const res = await fetch(`${API}/api/ai/analyze-report`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                report: {
                    type: report.type,
                    questionId: report.questionId,
                    description: report.description || ''
                },
                question,
                topicInfo
            })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Analiz başarısız');

        const verdictColor =
            data.verdict === 'Geçerli rapor'     ? '#10b981' :
            data.verdict === 'Kısmen geçerli'    ? '#f59e0b' :
            data.verdict === 'Geçersiz rapor'    ? '#ef4444' : '#94a3b8';

        const actionLabel =
            data.action === 'resolved' ? '✅ Çözüldü olarak işaretle' :
            data.action === 'rejected' ? '❌ Reddet'                  :
            '🔍 Daha fazla inceleme gerekiyor';

        const confidenceBar = `<div style="background:rgba(255,255,255,0.06);border-radius:99px;height:5px;margin-top:4px;overflow:hidden;">
            <div style="width:${data.confidence || 0}%;height:100%;background:${verdictColor};border-radius:99px;transition:width 0.5s;"></div>
        </div>
        <div style="font-size:0.72rem;color:var(--text-muted);margin-top:2px;">Güven: %${data.confidence || 0}</div>`;

        const rId = (report.id || '').replace(/'/g, "\\'");
        const qId = (report.questionId || '').replace(/'/g, "\\'");
        const rAt = (report.receivedAt || report.timestamp || '').replace(/'/g, "\\'");
        const actionBtn = data.action !== 'review' ? `
            <button onclick="window._updateReportStatus(${index}, '${rId}', '${qId}', '${rAt}', '${data.action === 'resolved' ? 'resolved' : 'rejected'}')"
                style="margin-top:0.75rem; padding:0.45rem 1rem; font-size:0.82rem; background:${data.action === 'resolved' ? 'rgba(16,185,129,0.12)' : 'rgba(239,68,68,0.1)'}; border:1px solid ${data.action === 'resolved' ? '#10b981' : '#ef4444'}; color:${data.action === 'resolved' ? '#10b981' : '#ef4444'}; border-radius:7px; cursor:pointer; display:inline-flex; align-items:center; gap:0.3rem;">
                <span class="material-icons-round" style="font-size:0.95rem;">${data.action === 'resolved' ? 'check_circle' : 'cancel'}</span>
                ${actionLabel}
            </button>` : `<div style="margin-top:0.5rem;font-size:0.8rem;color:#f59e0b;">🔍 ${actionLabel}</div>`;

        analysisEl.innerHTML = `
        <div style="background:rgba(15,23,42,0.7);border:1px solid rgba(99,102,241,0.3);border-radius:10px;padding:1rem;">
            <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
                <span class="material-icons-round" style="color:#a78bfa;font-size:1.1rem;">auto_awesome</span>
                <span style="font-size:0.75rem;font-weight:700;color:#a78bfa;text-transform:uppercase;letter-spacing:0.05em;">AI Rapor Analizi</span>
                <span style="background:rgba(0,0,0,0.3);color:${verdictColor};border:1px solid ${verdictColor};padding:2px 9px;border-radius:20px;font-size:0.72rem;font-weight:600;">${data.verdict}</span>
            </div>
            ${confidenceBar}
            <div style="margin-top:0.85rem;font-size:0.87rem;color:#e2e8f0;line-height:1.6;font-weight:600;">${data.summary || ''}</div>
            ${data.details ? `<div style="margin-top:0.5rem;font-size:0.83rem;color:#94a3b8;line-height:1.6;border-top:1px solid rgba(255,255,255,0.06);padding-top:0.5rem;">${data.details}</div>` : ''}
            ${actionBtn}
        </div>`;
    } catch (e) {
        analysisEl.innerHTML = `<div style="background:rgba(239,68,68,0.08);border:1px solid rgba(239,68,68,0.3);border-radius:10px;padding:0.75rem;color:#f87171;font-size:0.85rem;">
            <span class="material-icons-round" style="font-size:0.95rem;vertical-align:middle;">error</span>
            Analiz hatası: ${e.message}
        </div>`;
    }
};

window._toggleRQPreview = async function (index, questionId) {
    const previewEl = document.getElementById(`rqPreview-${index}`);
    if (!previewEl) return;

    if (previewEl.style.display !== 'none') {
        previewEl.style.display = 'none';
        return;
    }

    previewEl.innerHTML = '<div style="color:var(--text-muted);font-size:0.85rem;padding:0.5rem 0;">Soru yükleniyor...</div>';
    previewEl.style.display = 'block';

    try {
        const res = await fetch(`${API}/find-question?id=${encodeURIComponent(questionId)}`);
        const data = await res.json();

        if (!data.success || !data.question) {
            previewEl.innerHTML = '<div style="color:#f59e0b;font-size:0.85rem;padding:0.5rem 0;">⚠️ Soru veritabanında bulunamadı.</div>';
            return;
        }

        const q = data.question;
        const labels = ['A', 'B', 'C', 'D', 'E'];
        const optsHtml = (q.o || []).map((opt, i) => {
            const correct = i === q.a;
            return `<div style="padding:0.42rem 0.75rem; border-radius:6px; font-size:0.85rem;
                background:${correct ? 'rgba(16,185,129,0.15)' : 'rgba(15,23,42,0.5)'};
                border:1px solid ${correct ? '#10b981' : '#334155'};
                color:${correct ? '#6ee7b7' : '#cbd5e1'};">
                <b>${labels[i]})</b> ${opt}${correct ? ' ✓' : ''}
            </div>`;
        }).join('');

        previewEl.innerHTML = `
            <div style="background:rgba(15,23,42,0.6); border:1px solid #334155; border-radius:10px; padding:1rem;">
                <div style="font-size:0.7rem; color:#6366f1; font-weight:600; margin-bottom:0.5rem; text-transform:uppercase; letter-spacing:0.05em;">Soru İçeriği</div>
                <div style="color:#e2e8f0; font-size:0.9rem; line-height:1.6; margin-bottom:0.75rem;">${q.q || ''}</div>
                <div style="display:flex; flex-direction:column; gap:0.3rem;">${optsHtml}</div>
                ${q.e ? `<div style="margin-top:0.75rem; padding:0.6rem 0.75rem; background:rgba(245,158,11,0.08); border-left:3px solid #f59e0b; border-radius:0 6px 6px 0; color:#fcd34d; font-size:0.82rem;"><b>Açıklama:</b> ${q.e}</div>` : ''}
            </div>`;
    } catch (e) {
        previewEl.innerHTML = `<div style="color:#ef4444;font-size:0.85rem;">Hata: ${e.message}</div>`;
    }
};

window._updateReportStatus = async function (index, id, questionId, receivedAt, status) {
    try {
        const res = await fetch(`${API}/reports`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id: id || undefined, questionId, receivedAt, status })
        });
        const data = await res.json();
        if (!data.success) throw new Error(data.error || 'Güncelleme başarısız');

        // Lokal state güncelle
        const report = window._allReports.find(r =>
            (id && r.id === id) ||
            (r.questionId === questionId && (r.receivedAt === receivedAt || r.timestamp === receivedAt))
        );
        if (report) report.status = status;

        window._renderReports();
        const labels = { resolved: 'Çözüldü olarak işaretlendi ✅', rejected: 'Reddedildi ❌', pending: 'Bekleyene alındı' };
        showToast(labels[status] || 'Güncellendi', 'success');
    } catch (e) {
        showToast('Güncelleme hatası: ' + e.message, 'error');
    }
};

window.viewReportQuestion = async function (questionId) {
    showToast('Soru aranıyor...', 'info');
    try {
        const res = await fetch(API + '/find-question?id=' + questionId);
        const data = await res.json();

        if (data.success) {
            editQuestion(data.question, data.topicId);
        } else {
            showToast('Soru veritabanında bulunamadı', 'error');
        }
    } catch (e) {
        showToast('Hata: ' + e.message, 'error');
    }
};


// FEEDBACKS LOGIC
window.loadFeedbacks = async function () {
    const el = document.getElementById('feedbacksList');
    if (!el) return;
    el.innerHTML = '<div style="padding:1rem; color:var(--text-muted)">Yükleniyor...</div>';

    try {
        const res = await fetch(API + '/feedbacks');
        const feedbacks = await res.json();

        if (!feedbacks || feedbacks.length === 0) {
            el.innerHTML = '<div style="padding:2rem; text-align:center; color:var(--text-muted)">Henüz hiç geri bildirim yok.</div>';
            return;
        }

        el.innerHTML = feedbacks.map(f => {
            const dateStr = new Date(f.receivedAt).toLocaleString('tr-TR');
            return `
            <div style="background:var(--card); border:1px solid var(--border); padding:1rem; margin-bottom:0.5rem; border-radius:8px">
                <div style="font-weight:bold; color:var(--accent)">${f.typeName || f.type}</div>
                <div style="margin:0.5rem 0">"${f.message}"</div>
                <div style="font-size:0.8rem; color:var(--text-muted)">${dateStr} - ${f.platform}</div>
            </div>
            `;
        }).join('');
    } catch (e) {
        el.innerHTML = `Hata: ${e.message}`;
    }
};


