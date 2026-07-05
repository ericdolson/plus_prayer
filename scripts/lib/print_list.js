import PDFDocument from 'pdfkit';
import fs from 'fs';

// Generates a printable letter-size PDF: bold title, subtitle, then names
// flowing as justified comma-separated text.
//
// options:
//   outputPath  – absolute path to write the PDF
//   title       – bold heading (e.g. "Missing Children")
//   subtitle    – lighter subheading (e.g. "July 3, 2026 · 4,604 souls")
//   names       – string[] joined with ", "

export function writePdf({ outputPath, title, subtitle, names }) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 72, size: 'LETTER' });
    const stream = fs.createWriteStream(outputPath);
    doc.pipe(stream);

    doc.font('Helvetica-Bold').fontSize(12).text(title, { align: 'center' });
    doc.font('Helvetica').fontSize(10).text(subtitle, { align: 'center' });
    doc.moveDown(1.5);
    doc.font('Helvetica').fontSize(10).text(names.join(', '), { align: 'justify', lineGap: 3 });

    doc.end();
    stream.on('finish', resolve);
    stream.on('error', reject);
  });
}

export function timestamp() {
  return new Date().toISOString().replace(/:/g, '-').slice(0, 19);
}

export function dateLabel(date = new Date()) {
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
}
