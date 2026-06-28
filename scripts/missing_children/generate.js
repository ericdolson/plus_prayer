import PDFDocument from 'pdfkit';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const API_URL = 'https://www.namus.gov/api/CaseSets/NamUs/MissingPersons/Search';
const TAKE = 10;

async function fetchMissingChildren() {
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Accept': 'application/json, text/plain, */*',
      'Content-Type': 'application/json;charset=UTF-8',
      'Origin': 'https://www.namus.gov',
      'Referer': 'https://www.namus.gov/MissingPersons/Search',
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
    },
    body: JSON.stringify({
      predicates: [{ field: 'computedMissingMinAge', operator: 'LessThanOrEqualTo', value: 17 }],
      take: TAKE,
      skip: 0,
      projections: ['lastName', 'firstName', 'computedMissingMaxAge'],
      orderSpecifications: [{ field: 'dateOfLastContact', direction: 'Descending' }],
      documentFragments: ['birthDate'],
    }),
  });

  if (!res.ok) throw new Error(`API responded ${res.status}: ${await res.text()}`);
  return res.json();
}

function toTitleCase(str) {
  // word boundary handles spaces, hyphens, apostrophes, etc.
  return str.toLowerCase().replace(/\b\w/g, c => c.toUpperCase());
}

function formatEntry({ firstName, lastName, computedMissingMaxAge }) {
  const first = toTitleCase(firstName.trim());
  const last = toTitleCase(lastName.trim());
  const age = computedMissingMaxAge === 0 ? 'infant' : (computedMissingMaxAge ?? '?');
  return `${first} ${last} (${age})`;
}

async function generate() {
  console.log('Fetching missing children from NamUs...');
  const data = await fetchMissingChildren();
  console.log(`Retrieved ${data.results.length} of ${data.count} total records`);

  const entries = data.results.map(formatEntry);
  const listText = entries.join(', ');

  const now = new Date();
  const timestamp = now.toISOString().replace(/:/g, '-').slice(0, 19);
  const dateLabel = now.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

  const outputDir = path.join(__dirname, 'output');
  fs.mkdirSync(outputDir, { recursive: true });
  const outputPath = path.join(outputDir, `missing_children_${timestamp}.pdf`);

  await writePdf({ outputPath, listText, count: data.results.length, dateLabel });

  console.log(`Saved: ${outputPath}`);
}

function writePdf({ outputPath, listText, count, dateLabel }) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 72, size: 'LETTER' });
    const stream = fs.createWriteStream(outputPath);
    doc.pipe(stream);

    doc
      .font('Helvetica-Bold')
      .fontSize(16)
      .text('Missing Children Prayer List', { align: 'center' });

    doc
      .font('Helvetica')
      .fontSize(10)
      .text(`${dateLabel} · ${count} names`, { align: 'center' });

    doc.moveDown(1.5);

    doc
      .font('Helvetica')
      .fontSize(10)
      .text(listText, { align: 'left', lineGap: 3 });

    doc.end();
    stream.on('finish', resolve);
    stream.on('error', reject);
  });
}

generate().catch(err => {
  console.error(err);
  process.exit(1);
});
