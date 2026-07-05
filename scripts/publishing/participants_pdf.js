// Usage: node publishing/participants_pdf.js [--list N]
//
// Reads publishing/participants.json and generates a printable PDF of the
// pending participants for the given list number (defaults to the highest
// pending list). Output lands in scripts/publishing/output/.

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { writePdf, timestamp, dateLabel } from '../lib/print_list.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PARTICIPANTS_FILE = path.join(__dirname, '../../publishing/participants.json');

const listArg = process.argv.indexOf('--list');
const requestedList = listArg !== -1 ? String(process.argv[listArg + 1]) : null;

const raw = JSON.parse(fs.readFileSync(PARTICIPANTS_FILE, 'utf8').replace(/^`|`$/g, ''));
const pending = raw.pending ?? {};

const listKeys = Object.keys(pending);
if (listKeys.length === 0) {
  console.log('No pending participants found in participants.json');
  process.exit(0);
}

const listKey = requestedList ?? String(Math.max(...listKeys.map(Number)));
if (!pending[listKey]) {
  console.error(`No pending entry for list ${listKey}. Available: ${listKeys.join(', ')}`);
  process.exit(1);
}

const participants = pending[listKey];
const names = participants.map(p => p.handle ?? p.id ?? 'Unknown');

console.log(`List ${listKey}: ${names.length} participants`);

const outputDir = path.join(__dirname, 'output');
fs.mkdirSync(outputDir, { recursive: true });
const outputPath = path.join(outputDir, `participants_list${listKey}_${timestamp()}.pdf`);

await writePdf({
  outputPath,
  title: `List ${listKey} — Social Prayers`,
  subtitle: `${dateLabel()} · ${names.length} souls`,
  names,
});

console.log(`Saved: ${outputPath}`);
