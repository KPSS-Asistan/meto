/* === modules\notifications.js === */

/**
 * KPSS Dashboard - Notifications Module
 * Manages notification templates and sending push notifications
 */

// Global Templates Array
let myTemplates = [];

const DEFAULT_TEMPLATES = [
    {
        title: "☀️ Günaydın, Bugün Senin Günün!",
        body: "Yeni bir gün, yeni hedefler! Kahveni al ve bugün için planladığın ilk testi çözmeye başla. Başarı düzenli çalışanın yanındadır.",
        channel: "daily_reminder",
        icon: "wb_sunny"
    },
    {
        title: "📚 Yeni Soru Paketleri Eklendi",
        body: "Soru bankamız genişlemeye devam ediyor! Müfredata uygun en güncel soruları şimdi keşfet ve eksiklerini kapat.",
        channel: "general",
        icon: "library_add"
    },
    {
        title: "🔥 Çalışma Serini Koruma Vakti",
        body: "Serin bozulmasın! Sadece 10 dakika ayırarak bugünkü çalışma görevini tamamlayabilir ve hedefine bir adım daha yaklaşabilirsin.",
        channel: "streak_alert",
        icon: "local_fire_department"
    },
    {
        title: "✍️ Haftalık Deneme Saati",
        body: "Gerçek sınav provasına hazır mısın? Haftalık denemeni çözerek Türkiye geneli sıralamanı ve gelişimini hemen gör.",
        channel: "general",
        icon: "edit_note"
    },
    {
        title: "🧠 AI Koç Senin İçin Burada",
        body: "Zorlandığın konuları analiz ettim. Senin için bugün odaklanman gereken 3 kritik konuyu listeledim, hadi göz atalım.",
        channel: "motivation",
        icon: "psychology"
    },
    {
        title: "📊 Gelişim Raporun Yayında",
        body: "Geçen haftaya göre netlerin %15 arttı! Bu tempoyla devam edersen hedefine ulaşman çok yakın. Analizini incele.",
        channel: "motivation",
        icon: "bar_chart"
    },
    {
        title: "🎯 Hedef: Memurluk!",
        body: "Hayallerindeki o kadro için bugün neler yaptın? Küçük adımlar büyük sonuçlar doğurur. Şimdi başla!",
        channel: "daily_reminder",
        icon: "target"
    },
    {
        title: "💡 Günün Kritik Bilgisi",
        body: "Sınavda çıkma ihtimali yüksek 'Güncel Bilgiler' notunu hazırladım. Hemen oku, 1 neti cebine koy!",
        channel: "general",
        icon: "lightbulb"
    },
    {
        title: "🏆 Rakiplerin Şu An Çalışıyor",
        body: "Şu an binlerce kişi seninle aynı hedefe koşuyor. Onlardan bir adım önde olmak için şimdi bir test çözmeye ne dersin?",
        channel: "motivation",
        icon: "groups"
    },
    {
        title: "⛔ Hatalarından Ders Çıkar",
        body: "Denemelerde yanlış yaptığın soruları tekrar çözmek, en iyi öğrenme yöntemidir. Yanlışlarını senin için listeledim.",
        channel: "motivation",
        icon: "rule"
    },
    {
        title: "💎 Premium Ayrıcalıklarını Keşfet",
        body: "Reklamsız çalışma, sınırsız yapay zeka desteği ve özel denemeler... Başarı yolculuğunu Premium ile hızlandır.",
        channel: "general",
        icon: "stars"
    },
    {
        title: "😴 Verimli Bir Dinlenme İçin...",
        body: "Bugün harika iş çıkardın! Şimdi zihnini dinlendirme vakti. Yarın daha güçlü bir şekilde devam edeceğiz.",
        channel: "daily_reminder",
        icon: "bedtime"
    },
    {
        title: "🚀 Hız Limitini Zorla!",
        body: "Zamana karşı yarışta hızlanman gerekiyor. Bugün 'Hızlı Soru Çözme' modu ile limitlerini test etmeye ne dersin?",
        channel: "motivation",
        icon: "speed"
    },
    {
        title: "📢 Önemli Sınav Duyurusu",
        body: "Sınav takvimi ve süreçle ilgili yeni bir güncelleme var. Bilgi kirliliğinden uzak, en doğru haberi hemen oku.",
        channel: "general",
        icon: "campaign"
    },
    {
        title: "🤝 Beraber Başaracağız",
        body: "Yalnız değilsin! KPSS Asistan yanındaki en güçlü destekçin. Takıldığın her an bana sorabilirsin.",
        channel: "motivation",
        icon: "handshake"
    }
];

window.initNotificationsPage = function () {
    console.log('Notification page initialized');

    // Load from storage
    const stored = localStorage.getItem('kpss_notif_templates');
    if (stored) {
        myTemplates = JSON.parse(stored);
    } else {
        myTemplates = [...DEFAULT_TEMPLATES];
    }

    // Setup preview listeners
    const titleInput = document.getElementById('notifTitle');
    const bodyInput = document.getElementById('notifBody');
    const imgInput = document.getElementById('notifImage');
    const prevTitle = document.getElementById('prevNotifTitle');
    const prevBody = document.getElementById('prevNotifBody');
    const prevImg = document.getElementById('prevNotifImg');
    const prevImgContainer = document.getElementById('prevNotifImgContainer');

    if (titleInput && bodyInput && prevTitle && prevBody) {
        const updateNotifPreview = () => {
            prevTitle.innerText = titleInput.value || 'Başlık...';
            prevBody.innerText = bodyInput.value || 'Mesaj içeriği burada görünecek...';

            if (imgInput && imgInput.value) {
                prevImg.src = imgInput.value;
                prevImgContainer.style.display = 'block';
            } else if (prevImgContainer) {
                prevImgContainer.style.display = 'none';
            }
        };

        titleInput.oninput = updateNotifPreview;
        bodyInput.oninput = updateNotifPreview;
        if (imgInput) imgInput.oninput = updateNotifPreview;
    }

    renderTemplates();
};

function renderTemplates() {
    const grid = document.getElementById('notifTemplateGrid');
    if (!grid) return;

    grid.innerHTML = myTemplates.map((t, i) => `
        <div style="background:var(--card-bg); border:1px solid var(--border); border-radius:12px; display:flex; gap:12px; align-items:center; padding:10px 14px; position:relative; overflow:hidden">
            <div onclick="applyNotifTemplate(${i})" style="flex:1; cursor:pointer; display:flex; gap:12px; align-items:center">
                <span class="material-icons-round" style="color:var(--accent); font-size:1.4rem">${t.icon || 'star'}</span>
                <div style="font-size:0.85rem; font-weight:600; color:var(--text); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:180px">${t.title}</div>
            </div>
            <button onclick="deleteTemplate(${i})" style="background:none; border:none; color:#ef4444; padding:4px; opacity:0.5; cursor:pointer; font-size:1.1rem" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.5">
                <span class="material-icons-round" style="font-size:1.2rem">delete</span>
            </button>
        </div>
    `).join('');
}

window.saveAsTemplate = function () {
    const title = document.getElementById('notifTitle').value.trim();
    const body = document.getElementById('notifBody').value.trim();
    const channelId = document.getElementById('notifChannel').value;

    if (!title || !body) {
        showToast('Başlık ve mesaj olmadan şablon kaydedilemez!', 'warning');
        return;
    }

    const newTemplate = {
        title,
        body,
        channel: channelId,
        icon: 'stars'
    };

    myTemplates.unshift(newTemplate);
    localStorage.setItem('kpss_notif_templates', JSON.stringify(myTemplates));
    renderTemplates();
    showToast('Şablon kaydedildi!', 'success');
};

window.deleteTemplate = function (index) {
    if (!confirm('Bu şablonu silmek istediğine emin misin?')) return;
    myTemplates.splice(index, 1);
    localStorage.setItem('kpss_notif_templates', JSON.stringify(myTemplates));
    renderTemplates();
};

window.resetDefaultTemplates = function () {
    if (!confirm('Tüm şablonlar varsayılana dönecek. Emin misin?')) return;
    myTemplates = [...DEFAULT_TEMPLATES];
    localStorage.setItem('kpss_notif_templates', JSON.stringify(myTemplates));
    renderTemplates();
};

window.applyNotifTemplate = function (index) {
    const t = myTemplates[index];
    document.getElementById('notifTitle').value = t.title;
    document.getElementById('notifBody').value = t.body;
    document.getElementById('notifChannel').value = t.channel;

    // Explicitly update preview
    document.getElementById('notifTitle').dispatchEvent(new Event('input'));
    showToast('Şablon uygulandı!', 'success');
};

window.sendNotification = async function () {
    const title = document.getElementById('notifTitle').value.trim();
    const body = document.getElementById('notifBody').value.trim();
    const imageUrl = document.getElementById('notifImage').value.trim();
    const channelId = document.getElementById('notifChannel').value;
    const target = document.getElementById('notifTarget').value;
    const personalized = document.getElementById('notifPersonalized')?.checked || false;
    const btn = document.getElementById('btnSendNotif');
    const status = document.getElementById('notifStatus');

    if (!title || !body) {
        showToast('Lütfen başlık ve mesaj girin!', 'warning');
        return;
    }

    if (!confirm(`Bildirim gönderilecek: "${title}"\nOnaylıyor musunuz?`)) return;

    btn.disabled = true;
    btn.innerHTML = '<span class="material-icons-round">sync</span> GÖNDERİLİYOR...';
    status.style.display = 'block';
    status.innerHTML = '<span style="color:var(--text-muted)">İşlem sürüyor...</span>';

    try {
        const res = await fetch(API + '/api/notifications/send', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title, body, imageUrl, channelId, target, personalized })
        });

        const data = await res.json();

        if (data.success) {
            const info = data.sent != null ? `${data.sent}/${data.total} kullanıcıya gönderildi` : (data.messageId || 'OK');
            showToast('✅ Bildirim başarıyla gönderildi!', 'success');
            status.innerHTML = `<span style="color:#22c55e">✓ ${info}</span>`;
            // Clear inputs
            document.getElementById('notifTitle').value = '';
            document.getElementById('notifBody').value = '';
            document.getElementById('notifImage').value = '';
            document.getElementById('prevNotifTitle').innerText = 'Başlık...';
            document.getElementById('prevNotifBody').innerText = 'Mesaj içeriği burada görünecek...';
            document.getElementById('prevNotifImgContainer').style.display = 'none';
        } else {
            showToast('❌ Hata: ' + data.error, 'error');
            status.innerHTML = `<span style="color:#ef4444">⚠ Hata: ${data.error}</span>`;
        }
    } catch (e) {
        console.error(e);
        showToast('Bağlantı hatası', 'error');
        status.innerHTML = '<span style="color:#ef4444">⚠ Bağlantı hatası</span>';
    } finally {
        btn.disabled = false;
        btn.innerHTML = '<span class="material-icons-round">send</span> BİLDİRİMİ GÖNDER';
    }
};


