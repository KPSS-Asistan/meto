/**
 * Users API Routes
 * Firebase Admin SDK ile kullanıcı yönetimi
 */
const path = require('path');
const https = require('https');
const fs = require('fs');
const { sendJSON, parseBody } = require('../utils/helper');
const { FEEDBACK_FILE, REPORTS_FILE } = require('../config');

// Firebase Admin SDK
const { admin, db: firebaseDb } = require('../firebase-admin');
let db = firebaseDb;

function normalizePlatform(value) {
    const platform = (value || '').toString().trim().toLowerCase();
    if (platform.includes('android')) return 'Android';
    if (platform.includes('ios') || platform.includes('iphone') || platform.includes('ipad')) return 'iOS';
    if (platform.includes('web')) return 'Web';
    return '';
}

function normalizeLoginMethod(providerId, email) {
    const value = (providerId || '').toString().trim().toLowerCase();
    if (!value) return email ? 'E-posta/Şifre' : 'Bilinmiyor';
    if (value === 'password') return 'E-posta/Şifre';
    if (value === 'google.com') return 'Google';
    if (value === 'apple.com') return 'Apple';
    if (value === 'phone') return 'Telefon';
    if (value === 'anonymous') return 'Misafir';
    if (value === 'custom') return 'Özel Giriş';
    return value.replace('.com', '').replace('.', ' ').replace(/\b\w/g, c => c.toUpperCase());
}

async function collectPlatformHints() {
    const hints = {};

    const ingestRecord = (data) => {
        const uid = data.userId || data.uid;
        const platform = normalizePlatform(data.platform);
        if (!uid || !platform) return;
        if (!hints[uid]) hints[uid] = platform;
    };

    const ingestFile = (filePath) => {
        try {
            if (!fs.existsSync(filePath)) return;
            const raw = fs.readFileSync(filePath, 'utf8');
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) {
                parsed.forEach(ingestRecord);
            }
        } catch (e) {
            // Dosya yoksa ya da JSON bozuksa sessizce geç
        }
    };

    ingestFile(FEEDBACK_FILE);
    ingestFile(REPORTS_FILE);

    if (!db) return hints;

    const sources = [
        { collection: 'feedbacks', dateField: 'createdAt' },
        { collection: 'reports', dateField: 'createdAt' },
        { collection: 'feedback', dateField: 'receivedAt' },
        { collection: 'report', dateField: 'receivedAt' }
    ];

    for (const source of sources) {
        try {
            const snap = await db.collection(source.collection).orderBy(source.dateField, 'desc').limit(500).get();
            snap.forEach(doc => {
                ingestRecord(doc.data());
            });
        } catch (e) {
            // Koleksiyon veya index yoksa sessizce geç
        }
    }

    return hints;
}

// ─── RevenueCat REST API Helpers ───────────────────────────────────────────
// Gerekli .env değişkenleri:
//   REVENUECAT_SECRET_KEY   → RevenueCat Dashboard > Project > API Keys > Secret Key (sk_...)
//   REVENUECAT_ENTITLEMENT_ID → Entitlement identifier (varsayılan: "premium")

function rcRequest(method, path, body) {
    return new Promise((resolve, reject) => {
        const secretKey = process.env.REVENUECAT_SECRET_KEY;
        if (!secretKey) {
            return resolve({ skipped: true, reason: 'REVENUECAT_SECRET_KEY tanımlı değil' });
        }
        const payload = body ? JSON.stringify(body) : null;
        const options = {
            hostname: 'api.revenuecat.com',
            path,
            method,
            headers: {
                'Authorization': `Bearer ${secretKey}`,
                'Content-Type': 'application/json',
                ...(payload ? { 'Content-Length': Buffer.byteLength(payload) } : {})
            }
        };
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({ statusCode: res.statusCode, body: data });
            });
        });
        req.on('error', reject);
        if (payload) req.write(payload);
        req.end();
    });
}

// RevenueCat duration map: premiumType → RevenueCat duration string
const RC_DURATION_MAP = {
    monthly: 'monthly',
    quarterly: 'three_month',
    yearly: 'yearly'
};

async function grantRevenueCatEntitlement(uid, premiumType) {
    const entitlementId = process.env.REVENUECAT_ENTITLEMENT_ID || 'premium';
    const duration = RC_DURATION_MAP[premiumType] || 'monthly';
    const result = await rcRequest(
        'POST',
        `/v1/subscribers/${encodeURIComponent(uid)}/entitlements/${encodeURIComponent(entitlementId)}/promotional`,
        { duration }
    );
    if (result.skipped) {
        console.log('⚠️ RevenueCat atlandı:', result.reason);
    } else if (result.statusCode >= 200 && result.statusCode < 300) {
        console.log(`✅ RevenueCat entitlement verildi (uid=${uid}, duration=${duration})`);
    } else {
        console.error(`❌ RevenueCat entitlement hatası (${result.statusCode}):`, result.body);
    }
    return result;
}

async function revokeRevenueCatEntitlement(uid) {
    const entitlementId = process.env.REVENUECAT_ENTITLEMENT_ID || 'premium';
    const result = await rcRequest(
        'DELETE',
        `/v1/subscribers/${encodeURIComponent(uid)}/entitlements/${encodeURIComponent(entitlementId)}`
    );
    if (result.skipped) {
        console.log('⚠️ RevenueCat atlandı:', result.reason);
    } else if (result.statusCode >= 200 && result.statusCode < 300) {
        console.log(`✅ RevenueCat entitlement kaldırıldı (uid=${uid})`);
    } else {
        console.error(`❌ RevenueCat revoke hatası (${result.statusCode}):`, result.body);
    }
    return result;
}
// ───────────────────────────────────────────────────────────────────────────

// Mock users for development without Firebase
const MOCK_USERS = [
    {
        uid: 'mock_user_001',
        email: 'test@example.com',
        displayName: 'Test Kullanıcı',
        photoURL: null,
        isPremium: true,
        premiumType: 'gold',
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        lastLogin: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
        platform: 'Android',
        stats: { totalQuestions: 150, correctAnswers: 120, streak: 5 }
    },
    {
        uid: '6378226cilingir@gmail.com',
        email: '6378226cilingir@gmail.com',
        displayName: 'Mert Çilingir',
        photoURL: null,
        isPremium: false,
        premiumType: null,
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        lastLogin: new Date().toISOString(),
        platform: 'Android',
        stats: { totalQuestions: 50, correctAnswers: 35, streak: 2 }
    },
    {
        uid: 'mock_user_002',
        email: 'demo@kpss.app',
        displayName: 'Demo Kullanıcı',
        photoURL: null,
        isPremium: false,
        premiumType: null,
        createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
        lastLogin: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
        platform: 'iOS',
        stats: { totalQuestions: 50, correctAnswers: 35, streak: 2 }
    },
    {
        uid: 'mock_user_003',
        email: 'admin@localhost',
        displayName: 'Local Admin',
        photoURL: null,
        isPremium: true,
        premiumType: 'platinum',
        createdAt: new Date().toISOString(),
        lastLogin: new Date().toISOString(),
        platform: 'Web',
        stats: { totalQuestions: 0, correctAnswers: 0, streak: 0 }
    }
];

async function handleUserRoutes(req, res, pathname) {

    // GET /users veya /api/users - Tüm kullanıcıları listele
    if ((pathname === '/users' || pathname === '/api/users') && req.method === 'GET') {
        try {
            if (!admin || !db) {
                // Return mock users when Firebase is not configured
                console.log('⚠️ Firebase not configured, returning mock users');
                return sendJSON(res, {
                    success: true,
                    count: MOCK_USERS.length,
                    users: MOCK_USERS,
                    note: 'Mock data - Firebase not configured'
                });
            }

            // 1. Önce Auth'daki tüm kullanıcıları çek (Maksimum 1000)
            const listUsersResult = await admin.auth().listUsers(1000);
            const authUsers = listUsersResult.users;

            // 2. Ardından Firestore'daki detayları al (isPremium, istatistikler vb.)
            const usersSnapshot = await db.collection('users').get();
            const firestoreData = {};
            usersSnapshot.forEach(doc => {
                firestoreData[doc.id] = doc.data();
            });

            const platformHints = await collectPlatformHints();

            // 3. Verileri birleştir
            const users = authUsers.map(userRecord => {
                const fsData = firestoreData[userRecord.uid] || {};
                const hasEmail = !!userRecord.email;
                const providerIds = (userRecord.providerData || []).map(p => p.providerId).filter(Boolean);
                const isAnonymousProvider = providerIds.includes('anonymous');
                const inferredGuest = !hasEmail || isAnonymousProvider || fsData.isGuest === true || fsData.userType === 'guest';
                const platformFromData = normalizePlatform(fsData.platform);
                const platform = platformFromData || platformHints[userRecord.uid] || 'Bilinmiyor';
                const primaryProvider = providerIds[0] || (inferredGuest ? 'anonymous' : (hasEmail ? 'password' : 'custom'));
                const loginMethod = normalizeLoginMethod(primaryProvider, hasEmail);

                // İsim için tüm olası alanları sırayla dene
                const resolvedName =
                    userRecord.displayName ||
                    fsData.displayName ||
                    fsData.name ||
                    fsData.fullName ||
                    fsData.adSoyad ||
                    fsData.ad ||
                    fsData.isim ||
                    fsData.kullaniciAdi ||
                    fsData.username ||
                    (fsData.firstName && fsData.lastName ? `${fsData.firstName} ${fsData.lastName}` : null) ||
                    fsData.firstName ||
                    // Son çare: e-posta'nın @ öncesi kısmını capitalize et
                    (userRecord.email ? userRecord.email.split('@')[0].replace(/[._-]/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) : null) ||
                    'İsimsiz';

                return {
                    uid: userRecord.uid,
                    email: userRecord.email || 'N/A',
                    displayName: resolvedName,
                    photoURL: userRecord.photoURL,
                    isGuest: inferredGuest,
                    accountType: inferredGuest ? 'guest' : 'email',
                    loginMethod,
                    authProviders: providerIds,
                    isPremium: fsData.isPremium || false,
                    premiumType: fsData.premiumType || null,
                    createdAt: userRecord.metadata.creationTime,
                    lastLogin: userRecord.metadata.lastSignInTime,
                    platform,
                    stats: {
                        totalQuestions: fsData.totalQuestionsSolved || 0,
                        correctAnswers: fsData.correctAnswers || 0,
                        streak: fsData.currentStreak || 0
                    }
                };
            });

            // Son giriş tarihine göre sırala (En yeni en üstte)
            users.sort((a, b) => new Date(b.lastLogin).getTime() - new Date(a.lastLogin).getTime());

            return sendJSON(res, {
                success: true,
                count: users.length,
                users
            });

        } catch (e) {
            console.error('Users fetch error:', e);
            // Return mock users on error
            return sendJSON(res, {
                success: true,
                count: MOCK_USERS.length,
                users: MOCK_USERS,
                note: 'Mock data due to error: ' + e.message
            });
        }
    }

    // GET /users/:uid - Tek kullanıcı detayı
    if (pathname.startsWith('/users/') && req.method === 'GET' && !pathname.includes('/details')) {
        const uid = pathname.split('/')[2];

        if (!uid) {
            return sendJSON(res, { error: 'UID gerekli' }, 400);
        }

        try {
            if (!db) {
                return sendJSON(res, { error: 'Firebase bağlantısı yok' }, 500);
            }

            const userDoc = await db.collection('users').doc(uid).get();

            if (!userDoc.exists) {
                return sendJSON(res, { error: 'Kullanıcı bulunamadı' }, 404);
            }

            const data = userDoc.data();
            const platform = normalizePlatform(data.platform) || 'Bilinmiyor';
            return sendJSON(res, {
                success: true,
                user: {
                    uid: userDoc.id,
                    email: data.email || 'N/A',
                    displayName: data.displayName || data.name || 'Anonim',
                    isPremium: data.isPremium || false,
                    premiumType: data.premiumType || null,
                    createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
                    lastLogin: data.lastLogin ? data.lastLogin.toDate().toISOString() : null,
                    platform,
                    ...data
                }
            });

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /users/:uid/details - Detaylı kullanıcı bilgileri + istatistikler
    if (pathname.startsWith('/users/') && pathname.endsWith('/details') && req.method === 'GET') {
        const uid = pathname.split('/')[2];

        if (!uid) {
            return sendJSON(res, { error: 'UID gerekli' }, 400);
        }

        try {
            if (!db) {
                return sendJSON(res, { error: 'Firebase bağlantısı yok' }, 500);
            }

            // 1. Auth bilgileri
            let authUser;
            try {
                authUser = await admin.auth().getUser(uid);
            } catch (e) {
                authUser = null;
            }

            // 2. Firestore kullanıcı dokümanı
            const userDoc = await db.collection('users').doc(uid).get();
            const userData = userDoc.exists ? userDoc.data() : {};

            // 3. İstatistikler - solvedQuestions koleksiyonu
            let solvedQuestions = [];
            try {
                const solvedSnapshot = await db.collection('users').doc(uid).collection('solvedQuestions')
                    .orderBy('solvedAt', 'desc')
                    .limit(50)
                    .get();
                solvedSnapshot.forEach(doc => {
                    solvedQuestions.push({
                        questionId: doc.id,
                        ...doc.data(),
                        solvedAt: doc.data().solvedAt?.toDate?.() || doc.data().solvedAt
                    });
                });
            } catch (e) {
                // solvedQuestions olmayabilir
            }

            // 4. Aktivite logları
            let activities = [];
            try {
                const activitySnapshot = await db.collection('users').doc(uid).collection('activity')
                    .orderBy('timestamp', 'desc')
                    .limit(30)
                    .get();
                activitySnapshot.forEach(doc => {
                    activities.push({
                        id: doc.id,
                        ...doc.data(),
                        timestamp: doc.data().timestamp?.toDate?.() || doc.data().timestamp
                    });
                });
            } catch (e) {
                // activity koleksiyonu olmayabilir
            }

            // 5. Premium geçmişi
            let premiumHistory = [];
            try {
                const premiumSnapshot = await db.collection('users').doc(uid).collection('premiumHistory')
                    .orderBy('changedAt', 'desc')
                    .get();
                premiumSnapshot.forEach(doc => {
                    premiumHistory.push({
                        id: doc.id,
                        ...doc.data(),
                        changedAt: doc.data().changedAt?.toDate?.() || doc.data().changedAt
                    });
                });
            } catch (e) {
                // premiumHistory olmayabilir
            }

            // İstatistik hesapla
            const totalSolved = solvedQuestions.length;
            const correctAnswers = solvedQuestions.filter(q => q.isCorrect === true).length;
            const wrongAnswers = solvedQuestions.filter(q => q.isCorrect === false).length;
            const accuracyRate = totalSolved > 0 ? Math.round((correctAnswers / totalSolved) * 100) : 0;

            // Konu bazlı çözüm sayıları
            const topicStats = {};
            solvedQuestions.forEach(q => {
                const topic = q.topicName || q.topicId || 'Bilinmiyor';
                if (!topicStats[topic]) {
                    topicStats[topic] = { solved: 0, correct: 0 };
                }
                topicStats[topic].solved++;
                if (q.isCorrect) topicStats[topic].correct++;
            });

            // Premium durumu
            const isPremium = userData.isPremium || userData.is_premium || false;
            const premiumStart = userData.premiumStartDate?.toDate?.() || userData.premiumStartDate;
            const premiumEnd = userData.premiumEndDate?.toDate?.() || userData.premiumEndDate;
            const platform = normalizePlatform(userData.platform) || 'Bilinmiyor';
            const providerIds = (authUser?.providerData || []).map(p => p.providerId).filter(Boolean);
            const loginMethod = normalizeLoginMethod(providerIds[0], !!(authUser?.email || userData.email));
            let premiumDaysLeft = null;
            if (isPremium && premiumEnd) {
                premiumDaysLeft = Math.max(0, Math.ceil((new Date(premiumEnd) - new Date()) / (1000 * 60 * 60 * 24)));
            }

            return sendJSON(res, {
                success: true,
                user: {
                    uid: uid,
                    email: authUser?.email || userData.email || 'N/A',
                    displayName: authUser?.displayName || userData.displayName || userData.name || 'Anonim',
                    photoURL: authUser?.photoURL || userData.photoURL,

                    // Kayıt & Giriş bilgileri
                    createdAt: authUser?.metadata?.creationTime || (userData.createdAt?.toDate?.() || userData.createdAt),
                    lastLogin: authUser?.metadata?.lastSignInTime || (userData.lastLogin?.toDate?.() || userData.lastLogin),
                    platform: platform,
                    loginMethod: loginMethod,
                    authProviders: providerIds,

                    // Premium bilgileri
                    isPremium: isPremium,
                    premiumType: userData.premiumType || userData.premium_type || null,
                    premiumStartDate: premiumStart,
                    premiumEndDate: premiumEnd,
                    premiumDaysLeft: premiumDaysLeft,
                    premiumHistory: premiumHistory,

                    // İstatistikler
                    stats: {
                        totalQuestionsSolved: userData.totalQuestionsSolved || totalSolved,
                        correctAnswers: userData.correctAnswers || correctAnswers,
                        wrongAnswers: userData.wrongAnswers !== undefined ? userData.wrongAnswers : wrongAnswers,
                        accuracyRate: accuracyRate,
                        currentStreak: userData.currentStreak || 0,
                        longestStreak: userData.longestStreak || 0,
                        totalStudyTime: userData.totalStudyTime || 0, // dakika
                    },

                    // Detaylı konu istatistikleri
                    topicStats: Object.entries(topicStats)
                        .map(([topic, data]) => ({
                            topic,
                            solved: data.solved,
                            correct: data.correct,
                            accuracy: Math.round((data.correct / data.solved) * 100)
                        }))
                        .sort((a, b) => b.solved - a.solved),

                    // Son aktiviteler
                    recentActivity: solvedQuestions.slice(0, 20).map(q => ({
                        type: 'question_solved',
                        questionId: q.questionId,
                        topicId: q.topicId,
                        topicName: q.topicName,
                        isCorrect: q.isCorrect,
                        timestamp: q.solvedAt,
                        timeSpent: q.timeSpent || null
                    })),

                    // Sistem aktiviteleri
                    systemActivities: activities
                }
            });

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /users/premium veya /api/users/premium - Premium durumunu güncelle
    if ((pathname === '/users/premium' || pathname === '/api/users/premium') && req.method === 'POST') {
        try {
            const body = await parseBody(req);
            const { uid, isPremium, premiumType } = body;

            if (!uid) {
                return sendJSON(res, { error: 'UID gerekli' }, 400);
            }

            // Mock update for development
            if (!db) {
                const userIndex = MOCK_USERS.findIndex(u => u.uid === uid);
                if (userIndex >= 0) {
                    MOCK_USERS[userIndex].isPremium = Boolean(isPremium);
                    MOCK_USERS[userIndex].premiumType = premiumType || (isPremium ? 'gold' : null);
                }
                return sendJSON(res, {
                    success: true,
                    message: `Kullanıcı ${isPremium ? 'premium yapıldı' : 'premium iptal edildi'} (Mock)`,
                    uid,
                    isPremium
                });
            }

            // Build update data
            const updateData = {
                is_premium: Boolean(isPremium),
                isPremium: Boolean(isPremium),
                premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            };

            // Handle premium type
            if (isPremium) {
                // Set type if provided, otherwise keep existing (don't overwrite)
                if (premiumType) {
                    updateData.premiumType = premiumType;
                }
            } else {
                // Clear premium type and dates when cancelling
                updateData.premiumType = admin.firestore.FieldValue.delete();
                updateData.premiumEndDate = admin.firestore.FieldValue.delete();
                updateData.premiumStartDate = admin.firestore.FieldValue.delete();
            }

            // Handle dates if provided
            const { premiumStartDate, premiumEndDate } = body;
            if (premiumStartDate) {
                updateData.premiumStartDate = admin.firestore.Timestamp.fromDate(new Date(premiumStartDate));
            }
            if (premiumEndDate) {
                updateData.premiumEndDate = admin.firestore.Timestamp.fromDate(new Date(premiumEndDate));
            }

            // Use set with merge to create doc if not exists
            await db.collection('users').doc(uid).set(updateData, { merge: true });

            // Add to premium history
            try {
                await db.collection('users').doc(uid).collection('premiumHistory').add({
                    isPremium: Boolean(isPremium),
                    action: isPremium ? 'Premium aktif edildi' : 'Premium iptal edildi',
                    changedAt: admin.firestore.FieldValue.serverTimestamp(),
                    adminName: 'Admin', // Can be enhanced with actual admin name
                    premiumStartDate: premiumStartDate ? admin.firestore.Timestamp.fromDate(new Date(premiumStartDate)) : null,
                    premiumEndDate: premiumEndDate ? admin.firestore.Timestamp.fromDate(new Date(premiumEndDate)) : null
                });
            } catch (e) {
                // Non-critical, continue
            }

            // RevenueCat entitlement sync (uygulamanın görmesi için)
            try {
                if (isPremium) {
                    await grantRevenueCatEntitlement(uid, premiumType || 'monthly');
                } else {
                    await revokeRevenueCatEntitlement(uid);
                }
            } catch (rcErr) {
                console.error('RevenueCat sync hatası (kritik değil):', rcErr.message);
            }

            return sendJSON(res, {
                success: true,
                message: `Kullanıcı ${isPremium ? 'premium yapıldı' : 'premium iptal edildi'}`,
                uid,
                isPremium
            });

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /users/:uid/note - Admin notu ekle/güncelle
    if (pathname.startsWith('/users/') && pathname.endsWith('/note') && req.method === 'POST') {
        const uid = pathname.split('/')[2];
        if (!uid) {
            return sendJSON(res, { error: 'UID gerekli' }, 400);
        }

        try {
            const body = await parseBody(req);
            const { note } = body;

            if (!db) {
                return sendJSON(res, { success: true, note, message: 'Mock: Not kaydedildi' });
            }

            await db.collection('users').doc(uid).set({
                adminNote: note || '',
                adminNoteUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            return sendJSON(res, {
                success: true,
                message: 'Not kaydedildi'
            });
        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // DELETE /users/:uid - Kullanıcı sil
    if (pathname.startsWith('/users/') && req.method === 'DELETE') {
        const uid = pathname.split('/')[2];

        if (!uid) {
            return sendJSON(res, { error: 'UID gerekli' }, 400);
        }

        try {
            // Mock delete for development
            if (!admin || !db) {
                const userIndex = MOCK_USERS.findIndex(u => u.uid === uid);
                if (userIndex >= 0) {
                    MOCK_USERS.splice(userIndex, 1);
                }
                return sendJSON(res, {
                    success: true,
                    message: 'Kullanıcı silindi (Mock)',
                    uid
                });
            }

            // Auth'dan sil
            try {
                await admin.auth().deleteUser(uid);
            } catch (authErr) {
                console.log('Auth delete error (might not exist):', authErr.message);
            }

            // Firestore'dan sil
            await db.collection('users').doc(uid).delete();

            return sendJSON(res, {
                success: true,
                message: 'Kullanıcı silindi',
                uid
            });

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // POST /webhooks/revenuecat - RevenueCat subscription webhook
    if (pathname === '/webhooks/revenuecat' && req.method === 'POST') {
        try {
            const event = await parseBody(req);

            // RevenueCat event yapısı kontrolü
            if (!event || !event.event) {
                return sendJSON(res, { error: 'Invalid webhook payload' }, 400);
            }

            const { event: eventData } = event;
            const {
                type, // INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION, etc.
                app_user_id, // Firebase UID
                product_id, // com.kpss.premium.monthly, com.kpss.premium.yearly, etc.
                expiration_at_ms,
                purchased_at_ms,
                store, // app_store, play_store, stripe
                is_trial_conversion,
                cancel_reason
            } = eventData;

            if (!app_user_id) {
                return sendJSON(res, { error: 'User ID required' }, 400);
            }

            // Mock mode - just log and return success
            if (!db) {
                console.log('📱 RevenueCat Webhook (Mock):', {
                    type,
                    userId: app_user_id,
                    product: product_id,
                    store
                });
                return sendJSON(res, { success: true, message: 'Webhook received (Mock)' });
            }

            // Calculate premium dates based on event type
            const now = new Date();
            let premiumStartDate = now;
            let premiumEndDate = null;
            let isPremium = false;
            let premiumType = 'monthly';

            // Determine duration from product_id
            if (product_id) {
                if (product_id.includes('yearly') || product_id.includes('annual')) {
                    premiumType = 'yearly';
                } else if (product_id.includes('3month') || product_id.includes('quarterly')) {
                    premiumType = 'quarterly';
                } else if (product_id.includes('monthly')) {
                    premiumType = 'monthly';
                }
            }

            // Calculate end date based on expiration
            if (expiration_at_ms) {
                premiumEndDate = new Date(expiration_at_ms);
            } else {
                // Fallback calculation based on product type
                premiumEndDate = new Date(now);
                if (premiumType === 'monthly') {
                    premiumEndDate.setMonth(premiumEndDate.getMonth() + 1);
                } else if (premiumType === 'quarterly') {
                    premiumEndDate.setMonth(premiumEndDate.getMonth() + 3);
                } else if (premiumType === 'yearly') {
                    premiumEndDate.setFullYear(premiumEndDate.getFullYear() + 1);
                }
            }

            // Handle different event types
            switch (type) {
                case 'INITIAL_PURCHASE':
                case 'RENEWAL':
                case 'UNCANCELLATION':
                    isPremium = true;
                    break;

                case 'CANCELLATION':
                    // Don't immediately remove premium - let it expire naturally
                    isPremium = true; // Still premium until expiration
                    break;

                case 'EXPIRATION':
                case 'SUBSCRIPTION_PAUSED':
                    isPremium = false;
                    break;

                case 'PRODUCT_CHANGE':
                    // Handle upgrade/downgrade
                    isPremium = true;
                    break;

                default:
                    // For unknown events, maintain current status
                    break;
            }

            // Update user in Firestore
            const userRef = db.collection('users').doc(app_user_id);
            const updateData = {
                isPremium: isPremium,
                is_premium: isPremium, // Flutter compatibility
                premiumType: premiumType,
                premiumStartDate: admin.firestore.Timestamp.fromDate(premiumStartDate),
                premiumEndDate: premiumEndDate ? admin.firestore.Timestamp.fromDate(premiumEndDate) : null,
                premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),

                // RevenueCat specific data
                revenueCat: {
                    lastEventType: type,
                    lastEventAt: admin.firestore.Timestamp.fromDate(now),
                    productId: product_id,
                    store: store,
                    expirationAt: expiration_at_ms ? admin.firestore.Timestamp.fromDate(new Date(expiration_at_ms)) : null,
                    isTrialConversion: is_trial_conversion || false,
                    cancelReason: cancel_reason || null
                }
            };

            await userRef.set(updateData, { merge: true });

            // Add to premium history
            try {
                await userRef.collection('premiumHistory').add({
                    action: type === 'INITIAL_PURCHASE' ? 'Satın alma (RevenueCat)' :
                        type === 'RENEWAL' ? 'Yenileme (RevenueCat)' :
                            type === 'CANCELLATION' ? 'İptal (RevenueCat)' :
                                type === 'EXPIRATION' ? 'Süre doldu (RevenueCat)' : 'RevenueCat Olayı',
                    isPremium: isPremium,
                    source: 'revenuecat',
                    eventType: type,
                    productId: product_id,
                    store: store,
                    premiumStartDate: admin.firestore.Timestamp.fromDate(premiumStartDate),
                    premiumEndDate: premiumEndDate ? admin.firestore.Timestamp.fromDate(premiumEndDate) : null,
                    changedAt: admin.firestore.FieldValue.serverTimestamp(),
                    adminName: 'RevenueCat'
                });
            } catch (historyErr) {
                console.log('Premium history error:', historyErr.message);
            }

            console.log('✅ RevenueCat webhook processed:', {
                userId: app_user_id,
                type,
                isPremium,
                endDate: premiumEndDate
            });

            return sendJSON(res, {
                success: true,
                message: `Premium ${isPremium ? 'activated' : 'deactivated'}`,
                userId: app_user_id,
                type,
                premiumEndDate: premiumEndDate?.toISOString()
            });

        } catch (e) {
            console.error('RevenueCat webhook error:', e);
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    // GET /users/:uid/premium-status - Check and update premium status
    if (pathname.startsWith('/users/') && pathname.endsWith('/premium-status') && req.method === 'GET') {
        const uid = pathname.split('/')[2];

        if (!uid) {
            return sendJSON(res, { error: 'UID gerekli' }, 400);
        }

        try {
            if (!db) {
                return sendJSON(res, { success: true, isPremium: false, message: 'Mock mode' });
            }

            const userDoc = await db.collection('users').doc(uid).get();
            if (!userDoc.exists) {
                return sendJSON(res, { error: 'Kullanıcı bulunamadı' }, 404);
            }

            const userData = userDoc.data();
            const now = new Date();
            const endDate = userData.premiumEndDate?.toDate?.() || userData.premiumEndDate;

            let isPremium = userData.isPremium || false;
            let daysLeft = 0;

            // Check if premium expired
            if (isPremium && endDate) {
                if (endDate < now) {
                    // Premium expired - update status
                    isPremium = false;
                    await db.collection('users').doc(uid).set({
                        isPremium: false,
                        is_premium: false,
                        premiumExpiredAt: admin.firestore.Timestamp.fromDate(now),
                        updatedAt: admin.firestore.FieldValue.serverTimestamp()
                    }, { merge: true });

                    // Add expiration to history
                    await db.collection('users').doc(uid).collection('premiumHistory').add({
                        action: 'Süre doldu (Otomatik kontrol)',
                        isPremium: false,
                        changedAt: admin.firestore.FieldValue.serverTimestamp(),
                        adminName: 'Sistem'
                    });
                } else {
                    // Calculate remaining days
                    daysLeft = Math.ceil((endDate - now) / (1000 * 60 * 60 * 24));
                }
            }

            return sendJSON(res, {
                success: true,
                isPremium,
                daysLeft,
                premiumEndDate: endDate?.toISOString() || null,
                premiumType: userData.premiumType || null,
                revenueCat: userData.revenueCat || null
            });

        } catch (e) {
            return sendJSON(res, { error: e.message }, 500);
        }
    }

    return false;
}

module.exports = handleUserRoutes;
