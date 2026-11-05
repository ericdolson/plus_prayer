#!/usr/bin/env node
// Generates platform code from design/tokens.json (W3C Design Tokens, DTCG 2025.10).
//
//   node design/generate/index.mjs           write the outputs
//   node design/generate/index.mjs --check   exit 1 if an output is stale (CI)
//
// Outputs:
//   apps/ios/PlusPrayer/Theme/Tokens.generated.swift
//   (Kotlin for apps/android/ is added when that app starts.)
//
// No dependencies on purpose: the mapping is ours (paired light/dark roles
// into one dynamic color, Roca roles scaled relative to an iOS text style).

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const tokensPath = join(root, "design", "tokens.json");
const swiftPath = join(root, "apps", "ios", "PlusPrayer", "Theme", "Tokens.generated.swift");
const NS = "dev.hammock.plusprayer";

const tokens = JSON.parse(readFileSync(tokensPath, "utf8"));

// ---------------------------------------------------------------- resolve

function lookup(path) {
  let node = tokens;
  for (const key of path.split(".")) {
    if (node == null || !(key in node)) throw new Error(`Unresolved alias {${path}}`);
    node = node[key];
  }
  if (!node || !("$value" in node)) throw new Error(`{${path}} is not a token`);
  return node;
}

/** A token's value with aliases followed (whole-value and per-field). */
function resolve(value, seen = []) {
  if (typeof value === "string") {
    const m = value.match(/^\{([^}]+)\}$/);
    if (!m) return value;
    if (seen.includes(m[1])) throw new Error(`Alias cycle: ${[...seen, m[1]].join(" → ")}`);
    return resolve(lookup(m[1]).$value, [...seen, m[1]]);
  }
  if (Array.isArray(value)) return value.map((v) => resolve(v, seen));
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, resolve(v, seen)]));
  }
  return value;
}

const children = (group) => Object.keys(group).filter((k) => !k.startsWith("$"));

// ---------------------------------------------------------------- validate

const darkRoles = children(tokens.color.dark);
const lightRoles = children(tokens.color.light);
const darkOnly = darkRoles.filter((r) => !lightRoles.includes(r));
const lightOnly = lightRoles.filter((r) => !darkRoles.includes(r));
if (lightOnly.length) throw new Error(`Light-only color roles: ${lightOnly.join(", ")}`);
const toneKeys = children(tokens.color.avatarTone);
if (toneKeys.length !== 16 || toneKeys.some((k, i) => k !== String(i))) {
  throw new Error("color.avatarTone must hold exactly 0…15, in order");
}
const days = children(tokens.color.wax);
if (days.length !== 7) throw new Error("color.wax must hold 7 weekdays (sealVariant 0 = Sunday)");

// ---------------------------------------------------------------- helpers

const hex = (c) => {
  if (!c || c.colorSpace !== "srgb") throw new Error(`Expected an sRGB color, got ${JSON.stringify(c)}`);
  return "0x" + c.hex.replace("#", "").toUpperCase();
};
const alpha = (c) => c.alpha ?? 1;
const num = (n) => (Number.isInteger(n) ? `${n}` : `${+n.toFixed(4)}`);
const px = (d) => {
  if (d.unit !== "px") throw new Error(`Only px dimensions are supported, got ${d.unit}`);
  return num(d.value);
};
const seconds = (d) => {
  if (d.unit !== "ms") throw new Error(`Durations must be in ms, got ${d.unit}`);
  return num(d.value / 1000);
};
const doc = (node, indent) =>
  node.$description ? `${indent}/// ${node.$description.replace(/\n/g, " ")}\n` : "";
const SWIFT_KEYWORDS = new Set(["default", "in", "is", "as", "case", "class", "enum", "func", "let", "var", "static", "struct", "protocol", "return", "self", "Self", "super", "true", "false", "nil", "repeat", "where", "while", "for", "if", "else", "switch", "import", "init", "operator", "extension", "public", "private", "internal", "fileprivate", "throws", "rethrows", "try", "catch", "do", "break", "continue", "defer", "guard", "inout", "subscript", "typealias", "associatedtype", "deinit", "fallthrough"]);
const ident = (k) => (/^[0-9]/.test(k) ? `_${k}` : SWIFT_KEYWORDS.has(k) ? `\`${k}\`` : k);

/** sRGB hex → blended toward black (avatar tones' dark dim). */
const dim = (hexStr, amount) => {
  const v = parseInt(hexStr.replace("#", ""), 16);
  const ch = [(v >> 16) & 255, (v >> 8) & 255, v & 255].map((x) => Math.round(x * (1 - amount)));
  return "0x" + ch.map((x) => x.toString(16).padStart(2, "0")).join("").toUpperCase();
};
/** Linear blend of two sRGB hexes (the wax body's dark lift toward its sheen). */
const lerpHex = (a, b, t) => {
  const p = (h) => {
    const v = parseInt(h.replace("#", ""), 16);
    return [(v >> 16) & 255, (v >> 8) & 255, v & 255];
  };
  const [x, y] = [p(a), p(b)];
  return "0x" + x.map((xi, i) => Math.round(xi + (y[i] - xi) * t).toString(16).padStart(2, "0")).join("").toUpperCase();
};

// ---------------------------------------------------------------- Swift

function swiftColor(light, dark) {
  if (!light) return `Color(dark: ${hex(dark)}, darkAlpha: ${num(alpha(dark))})`;
  const la = alpha(light), da = alpha(dark);
  const alphas = la === 1 && da === 1 ? "" : `, lightAlpha: ${num(la)}, darkAlpha: ${num(da)}`;
  return `Color(light: ${hex(light)}, dark: ${hex(dark)}${alphas})`;
}

function swiftColors() {
  let out = "";
  for (const role of darkRoles) {
    const darkNode = tokens.color.dark[role];
    const lightNode = tokens.color.light[role];
    const dark = resolve(darkNode.$value);
    const light = lightNode ? resolve(lightNode.$value) : null;
    out += doc(darkNode, "        ");
    if (!lightNode) out += "        /// Dark theme only; clear in light.\n";
    out += `        static let ${role} = ${swiftColor(light, dark)}\n`;
  }
  const onAvatar = resolve(tokens.color.onAvatar.$value);
  out += doc(tokens.color.onAvatar, "        ");
  out += `        static let onAvatar = Color(light: ${hex(onAvatar)}, dark: ${hex(onAvatar)}, lightAlpha: ${num(alpha(onAvatar))}, darkAlpha: ${num(alpha(onAvatar))})\n`;
  const shadow = resolve(tokens.color.shadow.$value);
  out += doc(tokens.color.shadow, "        ");
  out += `        static let shadow = Color(light: ${hex(shadow)}, dark: ${hex(shadow)})\n`;

  // Avatar tones: same palette, dark blended slightly toward black.
  const dimBy = resolve(tokens.number.avatarDarkDim.$value);
  out += `\n${doc(tokens.color.avatarTone, "        ")}`;
  out += `        static let avatarTones: [Color] = [\n`;
  for (const k of toneKeys) {
    const t = tokens.color.avatarTone[k];
    const v = resolve(t.$value);
    out += `            Color(light: ${hex(v)}, dark: ${dim(v.hex, dimBy)}), // ${k} ${t.$description ?? ""}\n`;
  }
  out += `        ]\n`;

  // Wax by sealVariant (0 = Sunday).
  out += `\n${doc(tokens.color.wax, "        ")}`;
  out += `        enum wax {\n`;
  const lifts = tokens.number.waxDarkLift;
  const rimOpacity = resolve(tokens.number.waxDarkRimOpacity.$value);
  const lines = { base: [], sheen: [], body: [], rim: [] };
  for (const day of days) {
    const w = tokens.color.wax[day];
    const base = resolve(w.base.$value), sheen = resolve(w.sheen.$value);
    const lift = resolve(lifts[day].$value);
    const label = ` // ${w.$description ?? day}`;
    lines.base.push(`                Color(light: ${hex(base)}, dark: ${hex(base)}),${label}`);
    lines.sheen.push(`                Color(light: ${hex(sheen)}, dark: ${hex(sheen)}),${label}`);
    lines.body.push(`                Color(light: ${hex(base)}, dark: ${lerpHex(base.hex, sheen.hex, lift)}),${label}`);
    lines.rim.push(`                Color(dark: ${hex(sheen)}, darkAlpha: ${num(rimOpacity)}),${label}`);
  }
  out += `            /// The wax itself, by sealVariant.\n            static let base: [Color] = [\n${lines.base.join("\n")}\n            ]\n`;
  out += `            /// Its highlight: the stamp's relief maps face → base, highlights → sheen.\n            static let sheen: [Color] = [\n${lines.sheen.join("\n")}\n            ]\n`;
  out += `            /// The seal's body: the wax, lifted toward its sheen in dark theme where it needs it.\n            static let body: [Color] = [\n${lines.body.join("\n")}\n            ]\n`;
  out += `            /// Dark theme only (clear in light): the rim light along the seal's edge.\n            static let rim: [Color] = [\n${lines.rim.join("\n")}\n            ]\n`;
  out += `        }\n`;
  return out;
}

function swiftNumbers(group, indent, skip = []) {
  let out = "";
  for (const k of children(group)) {
    if (skip.includes(k)) continue;
    const node = group[k];
    if ("$value" in node) {
      out += doc(node, indent) + `${indent}static let ${ident(k)}: Double = ${num(resolve(node.$value))}\n`;
    } else {
      out += doc(node, indent) + `${indent}enum ${ident(k)} {\n${swiftNumbers(node, indent + "    ")}${indent}}\n`;
    }
  }
  return out;
}

function swiftDimensions(group, indent) {
  let out = "";
  for (const k of children(group)) {
    const node = group[k];
    if ("$value" in node) {
      out += doc(node, indent) + `${indent}static let ${ident(k)}: CGFloat = ${px(resolve(node.$value))}\n`;
    } else {
      out += doc(node, indent) + `${indent}enum ${ident(k)} {\n${swiftDimensions(node, indent + "    ")}${indent}}\n`;
    }
  }
  return out;
}

const SWIFT_WEIGHTS = { 100: ".thin", 200: ".ultraLight", 300: ".light", 400: ".regular", 500: ".medium", 600: ".semibold", 700: ".bold", 800: ".heavy", 900: ".black" };
const ROCA_FACES = { 100: "Roca-Thin", 300: "Roca-Light", 400: "Roca-Regular", 700: "Roca-Bold", 900: "Roca-Black" };

function swiftTypography() {
  let out = "";
  const display = resolve(tokens.font.family.display.$value);
  for (const k of children(tokens.typography)) {
    const node = tokens.typography[k];
    const v = resolve(node.$value);
    const ext = node.$extensions?.[NS] ?? {};
    const style = ext.ios?.textStyle;
    const weight = v.fontWeight;
    out += doc(node, "        ");
    if (v.fontFamily === display) {
      const face = ROCA_FACES[weight];
      if (!face) throw new Error(`No bundled Roca face for weight ${weight} (${k})`);
      if (!style) throw new Error(`Roca role ${k} needs ios.textStyle to scale with Dynamic Type`);
      out += `        static let ${k} = Font.custom("${face}", size: ${px(v.fontSize)}, relativeTo: .${style})\n`;
    } else if (style) {
      let f = `Font.system(.${style}, weight: ${SWIFT_WEIGHTS[weight]})`;
      if (ext.tabularFigures) f += ".monospacedDigit()";
      out += `        static let ${k} = ${f}\n`;
    } else {
      // Tracks a shape's size (avatar initials), not Dynamic Type.
      out += `        static func ${k}(size: CGFloat) -> Font { .system(size: size, weight: ${SWIFT_WEIGHTS[weight]}) }\n`;
    }
  }
  return out;
}

function swiftMotion() {
  let out = "";
  for (const k of children(tokens.duration)) {
    const node = tokens.duration[k];
    out += doc(node, "        ") + `        static let ${k}: TimeInterval = ${seconds(resolve(node.$value))}\n`;
  }
  return out;
}

function swiftEasing() {
  let out = "";
  for (const k of children(tokens.easing)) {
    const node = tokens.easing[k];
    const [a, b, c, d] = resolve(node.$value);
    out += doc(node, "        ");
    out += `        static func ${ident(k)}(_ duration: TimeInterval) -> Animation { .timingCurve(${num(a)}, ${num(b)}, ${num(c)}, ${num(d)}, duration: duration) }\n`;
  }
  return out;
}

function swift() {
  return `// GENERATED from design/tokens.json by design/generate/index.mjs. Do not edit.
// Regenerate: node design/generate/index.mjs
//
// Views read these semantic names only (apps/ios/CLAUDE.md, "Theming").

import SwiftUI
import UIKit

nonisolated enum PP {
    /// Color roles (design-direction §1): blue = do this, gold = held, everything else neutral.
    /// Every color is dynamic: one value per theme, resolved by the trait collection.
    enum color {
${swiftColors()}    }

    enum space {
${swiftDimensions(tokens.space, "        ")}    }

    enum radius {
${swiftDimensions(tokens.radius, "        ")}    }

    enum size {
${swiftDimensions(tokens.size, "        ")}    }

    enum number {
${swiftNumbers(tokens.number, "        ", ["waxDarkLift", "avatarDarkDim"])}    }

    enum type {
${swiftTypography()}    }

    /// Durations in seconds.
    enum duration {
${swiftMotion()}    }

    enum easing {
${swiftEasing()}    }
}

nonisolated extension Color {
    /// One color per theme, resolved from the trait collection.
    init(light: UInt32, dark: UInt32, lightAlpha: Double = 1, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(rgb: dark, alpha: darkAlpha)
                : UIColor(rgb: light, alpha: lightAlpha)
        })
    }

    /// Dark theme only; clear in light.
    init(dark: UInt32, darkAlpha: Double = 1) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(rgb: dark, alpha: darkAlpha) : .clear
        })
    }
}

nonisolated private extension UIColor {
    convenience init(rgb: UInt32, alpha: Double) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: alpha
        )
    }
}
`;
}

// ---------------------------------------------------------------- write / check

const outputs = [[swiftPath, swift()]];
const check = process.argv.includes("--check");
let stale = 0;
for (const [path, content] of outputs) {
  const rel = relative(root, path);
  const current = existsSync(path) ? readFileSync(path, "utf8") : null;
  if (current === content) {
    console.log(`up to date  ${rel}`);
    continue;
  }
  if (check) {
    console.error(`STALE       ${rel} (run: node design/generate/index.mjs)`);
    stale++;
  } else {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, content);
    console.log(`wrote       ${rel}`);
  }
}
if (darkOnly.length) console.log(`note: dark-only roles (clear in light): ${darkOnly.join(", ")}`);
process.exit(stale ? 1 : 0);
