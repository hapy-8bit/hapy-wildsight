import { createHash } from 'node:crypto';
import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';

const RETAINED_DAYS = 3;

/**
 * Small, process-local persistent counter for one WildSight backend instance.
 * The store contains only SHA-256 hashes, UTC dates and counts; it is not a
 * user account or a device fingerprint database.
 */
export class DailyUsageStore {
  constructor(filePath, limit) {
    this.filePath = filePath;
    this.limit = limit;
    this.queue = Promise.resolve();
  }

  static hashInstallationId(installationId) {
    return createHash('sha256').update(installationId).digest('hex');
  }

  async reserve(installationHash, now = new Date()) {
    return this.exclusive(async () => {
      const state = await this.readState();
      const date = DailyUsageStore.dateKey(now);
      this.prune(state, date);
      const day = state.days[date] ?? {};
      const count = Number(day[installationHash] ?? 0);
      if (count >= this.limit) {
        return { allowed: false, count, remaining: 0 };
      }
      day[installationHash] = count + 1;
      state.days[date] = day;
      await this.writeState(state);
      return { allowed: true, count: count + 1, remaining: this.limit - count - 1 };
    });
  }

  async release(installationHash, now = new Date()) {
    return this.exclusive(async () => {
      const state = await this.readState();
      const date = DailyUsageStore.dateKey(now);
      const day = state.days[date];
      const count = Number(day?.[installationHash] ?? 0);
      if (count <= 0) {
        return;
      }
      if (count === 1) {
        delete day[installationHash];
      } else {
        day[installationHash] = count - 1;
      }
      await this.writeState(state);
    });
  }

  async exclusive(action) {
    const next = this.queue.then(action, action);
    this.queue = next.catch(() => undefined);
    return next;
  }

  async readState() {
    try {
      const text = await readFile(this.filePath, 'utf8');
      const parsed = JSON.parse(text);
      if (typeof parsed === 'object' && parsed !== null && typeof parsed.days === 'object' && parsed.days !== null) {
        return { version: 1, days: parsed.days };
      }
    } catch (error) {
      if (error?.code !== 'ENOENT') {
        // A corrupt optional counter file must not take down identification.
      }
    }
    return { version: 1, days: {} };
  }

  async writeState(state) {
    await mkdir(path.dirname(this.filePath), { recursive: true });
    const temporaryPath = `${this.filePath}.tmp`;
    await writeFile(temporaryPath, JSON.stringify(state), { encoding: 'utf8', mode: 0o600 });
    await rename(temporaryPath, this.filePath);
  }

  prune(state, currentDate) {
    const threshold = new Date(`${currentDate}T00:00:00.000Z`);
    threshold.setUTCDate(threshold.getUTCDate() - RETAINED_DAYS);
    for (const date of Object.keys(state.days)) {
      if (new Date(`${date}T00:00:00.000Z`) < threshold) {
        delete state.days[date];
      }
    }
  }

  static dateKey(now) {
    return now.toISOString().slice(0, 10);
  }
}
