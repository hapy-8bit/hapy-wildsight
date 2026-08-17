import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { DailyUsageStore } from '../src/DailyUsageStore.js';

test('persists daily reservations across store instances and separates installations', async () => {
  const directory = await mkdtemp(path.join(tmpdir(), 'wildsight-usage-'));
  const filePath = path.join(directory, 'usage.json');
  const date = new Date('2026-08-15T08:00:00.000Z');
  const alpha = DailyUsageStore.hashInstallationId('alpha-installation-0001');
  const beta = DailyUsageStore.hashInstallationId('beta-installation-0002');
  try {
    const first = new DailyUsageStore(filePath, 2);
    assert.deepEqual(await first.reserve(alpha, date), { allowed: true, count: 1, remaining: 1 });
    assert.deepEqual(await first.reserve(alpha, date), { allowed: true, count: 2, remaining: 0 });

    const restarted = new DailyUsageStore(filePath, 2);
    assert.deepEqual(await restarted.reserve(alpha, date), { allowed: false, count: 2, remaining: 0 });
    assert.deepEqual(await restarted.reserve(beta, date), { allowed: true, count: 1, remaining: 1 });
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
