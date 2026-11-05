#!/usr/bin/env python3
"""Turn a single-path SVG into a minimal SF Symbols template (v3, Regular-M only).

usage: python3 design/generate/symbol.py <src.svg> <out.svg> <height-in-template-units> <descent>

Current glyphs (apps/ios/PlusPrayer/Assets.xcassets/Symbols/):
  pp.pray  ← app/assets/unbundled/design/icons/praying_hands.svg  86 6
  pp.bloom ← app/assets/img/+prayer_icon.svg                       72 0
Cap height in the template is 70.46 units (Regular-M), so 72 ≈ cap height.
The glyph is scaled to <height>, its bottom placed <descent> units below the
baseline, its left edge on the left margin.
"""
import re, sys

src, out, height, descent = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
svg = open(src).read()
# The drawable path: the one with a d attribute (skip invisible rects).
d = max(re.findall(r'<path[^>]*\sd="([^"]+)"', svg), key=len)

tok = re.findall(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?', d)
ARGS = dict(M=2, L=2, H=1, V=1, C=6, S=4, Q=4, T=2, A=7, Z=0)

def parse(tokens):
    cmds, i, cmd = [], 0, None
    while i < len(tokens):
        t = tokens[i]
        if re.match(r'[A-Za-z]', t):
            cmd = t; i += 1
            if cmd in 'Zz':
                cmds.append((cmd, [])); continue
        n = ARGS[cmd.upper()]
        args = [float(x) for x in tokens[i:i + n]]; i += n
        cmds.append((cmd, args))
        if cmd == 'M': cmd = 'L'
        elif cmd == 'm': cmd = 'l'
    return cmds

cmds = parse(tok)

# The outline's true bounds: sample the curves (control points overshoot).
def cubic(p0, p1, p2, p3, n=24):
    out = []
    for i in range(n + 1):
        t = i / n; u = 1 - t
        out.append((u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0],
                    u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1]))
    return out

pts, cx, cy, sx, sy, lastc = [], 0.0, 0.0, 0.0, 0.0, None
for c, a in cmds:
    rel = c.islower(); C = c.upper()
    ox, oy = (cx, cy) if rel else (0.0, 0.0)
    if C == 'Z':
        cx, cy = sx, sy; lastc = None; continue
    if C == 'H':
        cx = ox + a[0] if rel else a[0]; pts.append((cx, cy)); lastc = None; continue
    if C == 'V':
        cy = oy + a[0] if rel else a[0]; pts.append((cx, cy)); lastc = None; continue
    if C == 'C':
        p1, p2, p3 = (ox + a[0], oy + a[1]), (ox + a[2], oy + a[3]), (ox + a[4], oy + a[5])
        pts += cubic((cx, cy), p1, p2, p3); lastc = p2; cx, cy = p3; continue
    if C == 'S':
        p1 = (2*cx - lastc[0], 2*cy - lastc[1]) if lastc else (cx, cy)
        p2, p3 = (ox + a[0], oy + a[1]), (ox + a[2], oy + a[3])
        pts += cubic((cx, cy), p1, p2, p3); lastc = p2; cx, cy = p3; continue
    if C in 'ML':
        cx, cy = ox + a[0], oy + a[1]; pts.append((cx, cy)); lastc = None
        if C == 'M': sx, sy = cx, cy
        continue
    raise SystemExit(f"unsupported command {c}")

minx = min(p[0] for p in pts); maxx = max(p[0] for p in pts)
miny = min(p[1] for p in pts); maxy = max(p[1] for p in pts)
s = height / (maxy - miny)
tx, ty = -minx * s, descent - maxy * s  # bottom → +descent (below baseline)

def fmt(v): return f"{v:.3f}".rstrip('0').rstrip('.')

parts = []
for c, a in cmds:
    C = c.upper(); rel = c.islower()
    if C == 'Z': parts.append(c); continue
    if C == 'A':
        rx, ry, rot, la, sw, x, y = a
        x, y = (x * s, y * s) if rel else (x * s + tx, y * s + ty)
        parts.append(c + ' '.join(fmt(v) for v in (rx * s, ry * s, rot, la, sw, x, y))); continue
    if C == 'H':
        parts.append(c + fmt(a[0] * s if rel else a[0] * s + tx)); continue
    if C == 'V':
        parts.append(c + fmt(a[0] * s if rel else a[0] * s + ty)); continue
    vals = []
    for k in range(0, len(a), 2):
        x, y = a[k], a[k + 1]
        vals += ([x * s, y * s] if rel else [x * s + tx, y * s + ty])
    parts.append(c + ' '.join(fmt(v) for v in vals))

width = (maxx - minx) * s
L = 1391.0
template = f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!--Generator: hand-built from {src.split('/')[-1]} (design/generate/symbol.py)-->
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
 <!--glyph: "", point size: 100.0, font version: "17.0d1e1", template writer version: "128"-->
 <g id="Notes">
  <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
  <line style="fill:none;stroke:black;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="292" y2="292"/>
  <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13;font-weight:bold;" transform="matrix(1 0 0 1 263 322)">Weight/Scale Variations</text>
  <text id="template-version" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;" transform="matrix(1 0 0 1 3036 1933)">Template v.3.0</text>
 </g>
 <g id="Guides">
  <path d="M263 696L3036 696" id="Baseline-S" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;"/>
  <path d="M263 625.541L3036 625.541" id="Capline-S" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;"/>
  <path d="M263 1126L3036 1126" id="Baseline-M" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;"/>
  <path d="M263 1055.54L3036 1055.54" id="Capline-M" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;"/>
  <path d="M263 1556L3036 1556" id="Baseline-L" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;"/>
  <path d="M263 1485.54L3036 1485.54" id="Capline-L" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;"/>
  <path d="M{fmt(L)} 1030L{fmt(L)} 1150" id="left-margin-Regular-M" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;"/>
  <path d="M{fmt(L + width)} 1030L{fmt(L + width)} 1150" id="right-margin-Regular-M" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;"/>
 </g>
 <g id="Symbols">
  <g id="Regular-M" transform="matrix(1 0 0 1 {fmt(L)} 1126)">
   <path d="{' '.join(parts)}"/>
  </g>
 </g>
</svg>
'''
open(out, 'w').write(template)
print(f"{out}: width {width:.1f}, height {height}, descent {descent}, scale {s:.4f}")
