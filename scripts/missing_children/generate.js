import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { writePdf, timestamp, dateLabel } from '../lib/print_list.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const API_URL = 'https://www.namus.gov/api/CaseSets/NamUs/MissingPersons/Search';
const TAKE = 10000;

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

  const outputDir = path.join(__dirname, 'output');
  fs.mkdirSync(outputDir, { recursive: true });
  const outputPath = path.join(outputDir, `missing_children_${timestamp()}.pdf`);

  await writePdf({
    outputPath,
    title: 'Missing Children',
    subtitle: `${dateLabel()} · ${data.results.length} names`,
    names: entries,
  });

  console.log(`Saved: ${outputPath}`);
}

generate().catch(err => {
  console.error(err);
  process.exit(1);
});
