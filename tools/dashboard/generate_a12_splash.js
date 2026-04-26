/**
 * Android 12+ splash ikon alanı daire ile kırpıldığı için 960×960 tuval üzerinde
 * markayı güvenli daire içine sığdırır (flutter_native_splash README: ~640px çap).
 *
 * Çalıştırma (repo kökünden, `sharp` yüklü olmalı):
 *   npm install sharp
 *   node tools/dashboard/generate_a12_splash.js
 */
const path = require('path');
const sharp = require('sharp');

const ROOT = path.join(__dirname, '..', '..');
const SRC = path.join(ROOT, 'assets', 'images', 'kpss_koc_app_icon.png');
const OUT = path.join(ROOT, 'assets', 'images', 'kpss_koc_splash_android12.png');

const CANVAS = 960;
const SAFE_DIAM = 620;
const BG = { r: 21, g: 34, b: 56, alpha: 1 };

async function main() {
    const img = sharp(SRC);
    const meta = await img.metadata();
    const iw = meta.width || CANVAS;
    const ih = meta.height || CANVAS;
    const maxSide = Math.floor((SAFE_DIAM / 2) * Math.sqrt(2)) - 8;
    const scale = Math.min(maxSide / iw, maxSide / ih);
    const rw = Math.max(1, Math.round(iw * scale));
    const rh = Math.max(1, Math.round(ih * scale));
    const resized = await img.resize(rw, rh, { fit: 'inside' }).png().toBuffer();
    const left = Math.round((CANVAS - rw) / 2);
    const top = Math.round((CANVAS - rh) / 2);
    await sharp({
        create: {
            width: CANVAS,
            height: CANVAS,
            channels: 4,
            background: BG,
        },
    })
        .composite([{ input: resized, left, top }])
        .png()
        .toFile(OUT);
    console.log('Wrote', OUT, `(scaled logo ${rw}x${rh} on ${CANVAS}x${CANVAS})`);
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});
