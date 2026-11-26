# Writes res/drawable/banner.png: a plain 320x180 tile (dark blue with a lighter "N" bar), no dependencies.
import os, struct, zlib

W, H = 320, 180
bg, fg = (18, 24, 48), (120, 160, 255)

def pixel(x, y):
    # A simple block "N" in the middle so the tile is recognisable.
    in_box = 120 <= x < 200 and 50 <= y < 130
    if not in_box: return bg
    lx, ly = x - 120, y - 50
    if lx < 14 or lx >= 66 or abs(lx - ly * 80 / 80) < 10: return fg
    return bg

raw = b''.join(b'\x00' + bytes(c for x in range(W) for c in pixel(x, y)) for y in range(H))

def chunk(t, d): return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)

png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0)) \
    + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b'')
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'res', 'drawable', 'banner.png')
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, 'wb').write(png)
assert open(out, 'rb').read(8) == b'\x89PNG\r\n\x1a\n'
print('wrote', out, len(png), 'bytes')
