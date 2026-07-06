/**
 * 生成 AppIcon PNG 图标
 * 用法: node scripts/make-icons.js
 * 生成橘色圆角方形图标
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT_DIR = path.join(__dirname, '..', 'Assets.xcassets', 'AppIcon.appiconset');
const CORNER_RADIUS_RATIO = 0.2237; // iOS 图标圆角比例

function createPNG(width, height, r, g, b) {
  // 构建最小 PNG（使用调色板模式）
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 2;  // color type: RGB
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace
  const ihdrChunk = createChunk('IHDR', ihdr);

  // 像素数据: 圆角矩形 + 渐变
  const rawData = Buffer.alloc(height * (1 + width * 3)); // filter byte + RGB per row

  const cx = width / 2, cy = height / 2;
  const radius = Math.min(width, height) / 2;
  const cornerR = Math.max(radius * CORNER_RADIUS_RATIO, 1);

  for (let y = 0; y < height; y++) {
    const rowOff = y * (1 + width * 3);
    rawData[rowOff] = 0; // filter: none
    for (let x = 0; x < width; x++) {
      const off = rowOff + 1 + x * 3;
      // 判断是否在圆角矩形内
      let inShape = isInRoundedRect(x, y, 0, 0, width, height, cornerR);
      if (inShape) {
        // 渐变从左上到右下
        const t = (x + y) / (width + height);
        const pr = Math.round(r[0] + (r[1] - r[0]) * t);
        const pg = Math.round(g[0] + (g[1] - g[0]) * t);
        const pb = Math.round(b[0] + (b[1] - b[0]) * t);
        rawData[off] = Math.min(255, Math.max(0, pr));
        rawData[off + 1] = Math.min(255, Math.max(0, pg));
        rawData[off + 2] = Math.min(255, Math.max(0, pb));
      } else {
        rawData[off] = 255;
        rawData[off + 1] = 255;
        rawData[off + 2] = 255;
      }
    }
  }

  const compressed = zlib.deflateSync(rawData);
  const idatChunk = createChunk('IDAT', compressed);
  const iendChunk = createChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

function isInRoundedRect(x, y, rx, ry, rw, rh, cr) {
  if (x < rx || x >= rx + rw || y < ry || y >= ry + rh) return false;
  // 四个角
  if (x < rx + cr && y < ry + cr) {
    const dx = rx + cr - x, dy = ry + cr - y;
    return Math.sqrt(dx * dx + dy * dy) <= cr;
  }
  if (x >= rx + rw - cr && y < ry + cr) {
    const dx = x - (rx + rw - cr), dy = ry + cr - y;
    return Math.sqrt(dx * dx + dy * dy) <= cr;
  }
  if (x < rx + cr && y >= ry + rh - cr) {
    const dx = rx + cr - x, dy = y - (ry + rh - cr);
    return Math.sqrt(dx * dx + dy * dy) <= cr;
  }
  if (x >= rx + rw - cr && y >= ry + rh - cr) {
    const dx = x - (rx + rw - cr), dy = y - (ry + rh - cr);
    return Math.sqrt(dx * dx + dy * dy) <= cr;
  }
  return true;
}

function createChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeB = Buffer.from(type, 'ascii');
  const crcData = Buffer.concat([typeB, data]);
  const crc = crc32(crcData);
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc, 0);
  return Buffer.concat([len, typeB, data, crcBuf]);
}

// CRC32 查表法
let crcTable = null;
function makeCRCTable() {
  if (crcTable) return crcTable;
  crcTable = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    crcTable[n] = c;
  }
  return crcTable;
}

function crc32(data) {
  const table = makeCRCTable();
  let c = 0xFFFFFFFF;
  for (let i = 0; i < data.length; i++) {
    c = table[(c ^ data[i]) & 0xFF] ^ (c >>> 8);
  }
  return (c ^ 0xFFFFFFFF) >>> 0;
}

// ── 生成所有尺寸 ──
const sizes = [
  { name: 'icon-40.png',   w: 40,  h: 40 },
  { name: 'icon-58.png',   w: 58,  h: 58 },
  { name: 'icon-60.png',   w: 60,  h: 60 },
  { name: 'icon-76.png',   w: 76,  h: 76 },
  { name: 'icon-80.png',   w: 80,  h: 80 },
  { name: 'icon-87.png',   w: 87,  h: 87 },
  { name: 'icon-120.png',  w: 120, h: 120 },
  { name: 'icon-152.png',  w: 152, h: 152 },
  { name: 'icon-167.png',  w: 167, h: 167 },
  { name: 'icon-180.png',  w: 180, h: 180 },
  { name: 'icon-1024.png', w: 1024, h: 1024 },
];

// 猫老大橙配色 #FF6B35 → #FF8C5A
const r = [0xFF, 0xFF];
const g = [0x6B, 0x8C];
const b = [0x35, 0x5A];

console.log('🎨 生成 AppIcon 文件...\n');
for (const s of sizes) {
  const png = createPNG(s.w, s.h, r, g, b);
  const outPath = path.join(OUT_DIR, s.name);
  fs.writeFileSync(outPath, png);
  console.log(`  ✅ ${s.name} (${s.w}x${s.h})`);
}

console.log('\n📦 图标生成完成!');
