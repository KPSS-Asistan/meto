const fs = require('fs');
const path = require('path');
const { TOOLS_DIR } = require('../config');

const NOTIFICATIONS_FILE = path.join(TOOLS_DIR, 'notifications.json');

// Ensure file exists
if (!fs.existsSync(NOTIFICATIONS_FILE)) {
    fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify([], null, 2));
}

// ═══════════════════════════════════════════════════════════════════════════
// Firebase Admin SDK - FCM Push Notifications
// ═══════════════════════════════════════════════════════════════════════════
const { admin } = require('../firebase-admin');
const fcmReady = !!admin;

async function sendFCMNotification(notification) {
    if (!fcmReady || !admin) {
        console.log('🚀 [MOCK FCM] Sending Notification:', JSON.stringify(notification, null, 2));
        return { success: true, messageId: 'mock-' + Date.now(), mock: true };
    }

    const message = {
        topic: notification.topic || 'all',
        notification: {
            title: notification.notification.title,
            body: notification.notification.body,
        },
        data: notification.data || {},
        android: {
            notification: {
                channelId: notification.data?.channelId || 'general',
                sound: 'default',
                priority: 'high',
            },
        },
    };

    // Görsel varsa ekle
    if (notification.notification.image) {
        message.notification.imageUrl = notification.notification.image;
        message.android.notification.imageUrl = notification.notification.image;
    }

    try {
        const response = await admin.messaging().send(message);
        console.log('✅ FCM bildirim gönderildi:', response);
        return { success: true, messageId: response };
    } catch (e) {
        console.error('❌ FCM gönderim hatası:', e.message);
        throw new Error('FCM hatası: ' + e.message);
    }
}

async function sendPersonalizedNotifications(data) {
    const db = admin.firestore();
    const usersSnap = await db.collection('users').where('fcmToken', '!=', '').get();

    let sent = 0;
    let failed = 0;
    const errors = [];

    for (const doc of usersSnap.docs) {
        const user = doc.data();
        const token = user.fcmToken;
        if (!token) continue;

        const name = user.displayName || 'Öğrenci';
        const title = data.title.replace(/\{name\}/g, name);
        const body = data.body.replace(/\{name\}/g, name);

        const message = {
            token,
            notification: { title, body },
            data: {
                channelId: data.channelId || 'general',
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            },
            android: {
                notification: {
                    channelId: data.channelId || 'general',
                    sound: 'default',
                    priority: 'high',
                },
            },
        };

        if (data.imageUrl) {
            message.notification.imageUrl = data.imageUrl;
        }

        try {
            await admin.messaging().send(message);
            sent++;
        } catch (e) {
            failed++;
            if (e.code === 'messaging/registration-token-not-registered') {
                // Token geçersiz — temizle
                await db.collection('users').doc(doc.id).update({ fcmToken: '' });
            }
            errors.push(`${name}: ${e.message}`);
        }
    }

    console.log(`📨 Kişisel bildirim: ${sent} gönderildi, ${failed} hata`);
    return { success: true, sent, failed, total: usersSnap.size };
}

module.exports = async function handleNotificationRoutes(req, res, pathname) {
    // === SEND NOTIFICATION ===
    if (pathname === '/api/notifications/send' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', async () => {
            try {
                const data = JSON.parse(body);

                // Validate
                if (!data.title || !data.body) {
                    throw new Error('Başlık ve mesaj zorunludur');
                }

                const personalized = data.personalized === true;

                // Kişiselleştirilmiş: her kullanıcıya ismiyle gönder
                if (personalized && fcmReady && admin) {
                    const result = await sendPersonalizedNotifications(data);
                    res.writeHead(200, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify(result));
                    return;
                }

                // Topic-based: herkese aynı mesaj
                const result = await sendFCMNotification({
                    topic: data.target || 'all',
                    notification: {
                        title: data.title,
                        body: data.body,
                        image: data.imageUrl || data.image || null
                    },
                    data: {
                        channelId: data.channelId || 'general',
                        click_action: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                });

                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, messageId: result.messageId, mock: result.mock || false }));
            } catch (e) {
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: false, error: e.message }));
            }
        });
        return true;
    }

    // === GET TEMPLATES ===
    if (pathname === '/api/notifications/templates' && req.method === 'GET') {
        try {
            if (fs.existsSync(NOTIFICATIONS_FILE)) {
                const content = fs.readFileSync(NOTIFICATIONS_FILE, 'utf8');
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(content);
            } else {
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end('[]');
            }
        } catch (e) {
            res.writeHead(500);
            res.end(JSON.stringify({ error: e.message }));
        }
        return true;
    }

    // === SAVE TEMPLATE ===
    if (pathname === '/api/notifications/templates' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            try {
                const newTemplate = JSON.parse(body);
                newTemplate.id = Date.now().toString();
                newTemplate.createdAt = new Date().toISOString();

                const templates = JSON.parse(fs.readFileSync(NOTIFICATIONS_FILE, 'utf8'));
                templates.unshift(newTemplate); // Add to top

                fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify(templates, null, 2));

                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, template: newTemplate }));
            } catch (e) {
                res.writeHead(500);
                res.end(JSON.stringify({ success: false, error: e.message }));
            }
        });
        return true;
    }

    // === DELETE TEMPLATE ===
    if (pathname.startsWith('/api/notifications/templates/') && req.method === 'DELETE') {
        const id = pathname.split('/').pop();
        try {
            let templates = JSON.parse(fs.readFileSync(NOTIFICATIONS_FILE, 'utf8'));
            templates = templates.filter(t => t.id !== id);
            fs.writeFileSync(NOTIFICATIONS_FILE, JSON.stringify(templates, null, 2));

            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ success: true }));
        } catch (e) {
            res.writeHead(500);
            res.end(JSON.stringify({ success: false, error: e.message }));
        }
        return true;
    }

    return false;
};
