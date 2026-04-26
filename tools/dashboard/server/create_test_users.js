const admin = require('firebase-admin');
const path = require('path');

const serviceAccountPath = path.resolve(__dirname, '../../serviceAccountKey.json');
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function createOrUpdateUser(email, password, isPremium, displayName) {
    let userRecord;
    try {
        userRecord = await auth.getUserByEmail(email);
        console.log(`User ${email} already exists. Updating password...`);
        await auth.updateUser(userRecord.uid, { password, displayName });
    } catch (error) {
        if (error.code === 'auth/user-not-found') {
            console.log(`Creating new user ${email}...`);
            userRecord = await auth.createUser({
                email,
                password,
                displayName,
                emailVerified: true
            });
        } else {
            throw error;
        }
    }

    // Update Firestore
    await db.collection('users').doc(userRecord.uid).set({
        email,
        displayName,
        isPremium,
        is_premium: isPremium, // for flutter app
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        platform: 'PlayStoreReview',
        isTestAccount: true
    }, { merge: true });

    console.log(`✅ Successfully configured ${email} (Premium: ${isPremium})`);
}

async function main() {
    try {
        console.log('Starting test account generation...');
        await createOrUpdateUser('premium.test@kpssasistan.com', 'Test123456', true, 'Premium Test User');
        await createOrUpdateUser('free.test@kpssasistan.com', 'Test123456', false, 'Free Test User');
        console.log('🎉 All test accounts created and configured successfully!');
    } catch (error) {
        console.error('❌ Error generating test accounts:', error);
    } finally {
        process.exit(0);
    }
}

main();
