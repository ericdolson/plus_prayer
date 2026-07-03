// Usage: node publishing/collect_participants.js [--days N]
//
// Fetches all 🙏 comments across Zernio posts from the last N days (default 60),
// deduplicates by commenter, and generates a printable PDF participant list.
// 60-day default catches algorithm-surfaced old posts without scanning all time.
//
// Requires: ZERNIO_API_KEY environment variable

import PDFDocument from 'pdfkit';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BASE_URL = 'https://zernio.com/api';
const PRAY_EMOJI = '🙏';

const API_KEY = process.env.ZERNIO_API_KEY;
if (!API_KEY) {
  console.error('ZERNIO_API_KEY environment variable is required');
  process.exit(1);
}

const daysArg = process.argv.indexOf('--days');
const LOOKBACK_DAYS = daysArg !== -1 ? Number(process.argv[daysArg + 1]) : 60;

// ─── API helpers ─────────────────────────────────────────────────────────────

async function apiGet(urlPath, params = {}) {
  const url = new URL(`${BASE_URL}${urlPath}`);
  for (const [k, v] of Object.entries(params)) {
    if (v != null && v !== '') url.searchParams.set(k, String(v));
  }
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${API_KEY}`, Accept: 'application/json' },
  });
  if (!res.ok) throw new Error(`API ${res.status} ${url.pathname}: ${await res.text()}`);
  return res.json();
}

async function fetchAllPages(fetcher) {
  const items = [];
  let cursor = null;
  do {
    const data = await fetcher(cursor);
    // API may return data under various keys — try the common ones
    const page = data.data ?? data.items ?? data.comments ?? data.posts ?? [];
    items.push(...page);
    cursor = data.cursor ?? data.nextCursor ?? null;
  } while (cursor);
  return items;
}

// ─── Data fetching ────────────────────────────────────────────────────────────

async function fetchPostsWithComments(since) {
  return fetchAllPages(cursor =>
    apiGet('/v1/inbox/comments', {
      since,
      limit: 50,
      cursor,
      sortBy: 'date',
      sortOrder: 'desc',
    })
  );
}

async function fetchCommentsForPost(postId, accountId) {
  return fetchAllPages(cursor =>
    apiGet(`/v1/inbox/comments/${postId}`, { accountId, limit: 25, cursor })
  );
}

// ─── Comment parsing ──────────────────────────────────────────────────────────

function hasPrayEmoji(comment) {
  const text = comment.text ?? comment.message ?? comment.body ?? comment.content ?? '';
  return text.includes(PRAY_EMOJI);
}

function commenterKey(comment) {
  // Stable dedup key — prefer platform username/ID over display name
  return (
    comment.username ??
    comment.authorUsername ??
    comment.handle ??
    comment.authorId ??
    comment.userId ??
    comment.from?.username ??
    comment.from?.id ??
    comment.id
  );
}

function commenterName(comment) {
  return (
    comment.authorName ??
    comment.displayName ??
    comment.name ??
    comment.from?.name ??
    comment.username ??
    comment.authorUsername ??
    'Unknown'
  );
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function collect() {
  const since = new Date(Date.now() - LOOKBACK_DAYS * 86_400_000).toISOString();
  console.log(`Looking back ${LOOKBACK_DAYS} days (since ${since.slice(0, 10)})...`);

  const posts = await fetchPostsWithComments(since);
  console.log(`Found ${posts.length} posts with comment activity`);

  if (posts.length > 0) {
    console.log('Sample post shape:', JSON.stringify(posts[0], null, 2).slice(0, 300));
  }

  const seen = new Map(); // key → display name
  let totalComments = 0;

  for (const post of posts) {
    const postId = post.id ?? post.postId;
    const accountId = post.accountId ?? post.account?.id;

    if (!postId || !accountId) {
      console.warn('Skipping post — missing id or accountId:', JSON.stringify(post).slice(0, 120));
      continue;
    }

    let comments;
    try {
      comments = await fetchCommentsForPost(postId, accountId);
    } catch (err) {
      console.warn(`  Could not fetch comments for post ${postId}: ${err.message}`);
      continue;
    }

    if (comments.length > 0 && totalComments === 0) {
      console.log('Sample comment shape:', JSON.stringify(comments[0], null, 2).slice(0, 300));
    }

    for (const comment of comments) {
      totalComments++;
      if (hasPrayEmoji(comment)) {
        const key = commenterKey(comment);
        if (key && !seen.has(key)) {
          seen.set(key, commenterName(comment));
        }
      }
    }
  }

  console.log(`\nScanned ${totalComments} comments across ${posts.length} posts`);
  console.log(`Found ${seen.size} unique 🙏 participants`);

  if (seen.size === 0) {
    console.log('No participants found — no PDF generated.');
    return;
  }

  const names = [...seen.values()];
  const now = new Date();
  const timestamp = now.toISOString().replace(/:/g, '-').slice(0, 19);
  const dateLabel = now.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });

  const outputDir = path.join(__dirname, 'output');
  fs.mkdirSync(outputDir, { recursive: true });
  const outputPath = path.join(outputDir, `participants_${timestamp}.pdf`);

  await writePdf({ outputPath, names, dateLabel });
  console.log(`\nSaved: ${outputPath}`);
}

function writePdf({ outputPath, names, dateLabel }) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 72, size: 'LETTER' });
    const stream = fs.createWriteStream(outputPath);
    doc.pipe(stream);

    doc.font('Helvetica-Bold').fontSize(16).text('Next List — Participants', { align: 'center' });
    doc.font('Helvetica').fontSize(10).text(`${dateLabel} · ${names.length} souls`, { align: 'center' });
    doc.moveDown(1.5);
    doc.font('Helvetica').fontSize(10).text(names.join(', '), { align: 'justify', lineGap: 3 });

    doc.end();
    stream.on('finish', resolve);
    stream.on('error', reject);
  });
}

collect().catch(err => {
  console.error(err);
  process.exit(1);
});
