#!/usr/bin/env node

/*
 * Read-only source audit for the 100-species production batch.
 *
 * iPlant renders its morphology and ecology sections through its public
 * plantinfo endpoint, so a successful HTML fetch alone does not establish
 * that the direct page contains usable taxon-specific facts. This script
 * verifies the page and extracts the populated sections without changing any
 * knowledge JSON. It is intentionally dependency-free and rate-limited.
 *
 * Usage: node scripts/audit-iplant-source-data.js [--all] [--json]
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const speciesDirectory = path.join(root, 'data', 'plant-knowledge', 'species');
const userAgent = 'Mozilla/5.0';
const execFileAsync = promisify(execFile);
const wantedSections = [
  ['morphology', 11],
  ['ecology', 12],
];

function decodeDescriptor(value) {
  return Buffer.from(value, 'base64').toString('utf8').replace(/\s+/g, ' ').trim();
}

async function request(url, options = {}) {
  let lastError;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      const response = await fetch(url, {
        ...options,
        headers: { 'user-agent': userAgent, ...(options.headers || {}) },
        signal: AbortSignal.timeout(30_000),
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      return response;
    } catch (error) {
      lastError = error;
    }
  }
  // iPlant currently rejects Node's fetch TLS fingerprint with 403 while
  // accepting its public pages from curl. Use curl as the documented fallback
  // without invoking a shell or interpolating any source data into a command.
  try {
    const args = ['-sSL', '--max-time', '30', '--retry', '2', '-A', userAgent];
    if (options.method === 'POST') {
      args.push('-X', 'POST');
      if (options.headers?.['content-type']) args.push('-H', `content-type: ${options.headers['content-type']}`);
      args.push('--data', String(options.body || ''));
    }
    args.push(url);
    const { stdout } = await execFileAsync('curl', args, { maxBuffer: 8 * 1024 * 1024 });
    return {
      text: async () => stdout,
      json: async () => JSON.parse(stdout),
    };
  } catch (curlError) {
    throw new Error(`${lastError?.message || 'fetch failed'}; curl fallback: ${curlError.message}`);
  }
}

async function auditOne(record) {
  const pageRef = record.internalSourceRefs.find((ref) => /iplant\.cn\/info\//.test(ref.url));
  if (!pageRef) return { id: record.id, status: 'no-iplant-source' };

  try {
    const page = await request(pageRef.url);
    const html = await page.text();
    const spid = html.match(/var spno = "(\d+)"/u)?.[1];
    if (!spid) return { id: record.id, status: 'missing-iplant-id', url: pageRef.url };

    const sections = {};
    for (const [sectionName, typeid] of wantedSections) {
      const form = new URLSearchParams({ spid, type: 'descjarr', typeid: String(typeid), subcount: '99' });
      const response = await request('https://www.iplant.cn/ashx/plantinfo.ashx', {
        method: 'POST',
        headers: { 'content-type': 'application/x-www-form-urlencoded' },
        body: form,
      });
      const items = await response.json();
      sections[sectionName] = items
        .filter((item) => item.hasdesc && item.desc)
        .map((item) => ({ field: item.t, text: decodeDescriptor(item.desc) }));
    }

    return {
      id: record.id,
      chineseName: record.identity.acceptedChineseName,
      scientificName: record.identity.scientificName,
      status: 'ok',
      url: pageRef.url,
      acceptedChineseNameFound: html.includes(record.identity.acceptedChineseName),
      sections,
    };
  } catch (error) {
    return { id: record.id, status: 'request-failed', error: error.message, url: pageRef.url };
  }
}

async function mapWithConcurrency(items, limit, callback) {
  const result = [];
  let nextIndex = 0;
  async function worker() {
    while (nextIndex < items.length) {
      const index = nextIndex;
      nextIndex += 1;
      result[index] = await callback(items[index]);
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return result;
}

async function main() {
  const includeAll = process.argv.includes('--all');
  const asJson = process.argv.includes('--json');
  const requestedId = process.argv.find((argument) => argument.startsWith('--id='))?.slice('--id='.length);
  const records = fs.readdirSync(speciesDirectory)
    .filter((file) => file.endsWith('.json'))
    .sort()
    .map((file) => JSON.parse(fs.readFileSync(path.join(speciesDirectory, file), 'utf8')))
    .filter((record) => (includeAll || /本批.*已审核物种/u.test(record.knowledge?.summary || ''))
      && (!requestedId || record.id === requestedId));

  if (requestedId && records.length !== 1) throw new Error(`Expected exactly one record for --id=${requestedId}`);

  const results = await mapWithConcurrency(records, 4, auditOne);
  const summary = results.reduce((counts, result) => {
    counts[result.status] = (counts[result.status] || 0) + 1;
    return counts;
  }, {});

  if (asJson) {
    process.stdout.write(`${JSON.stringify({ auditedAt: new Date().toISOString(), summary, results }, null, 2)}\n`);
    return;
  }
  console.log(`iPlant source audit: ${records.length} records`, summary);
  for (const result of results.filter((item) => item.status !== 'ok')) {
    console.log(`${result.id}: ${result.status}${result.error ? ` (${result.error})` : ''}`);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

export { auditOne };
