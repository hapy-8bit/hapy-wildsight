import { Context } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';

export class StorageUsage {
  databaseBytes: number = 0;
  cacheBytes: number = 0;
  get totalBytes(): number { return this.databaseBytes + this.cacheBytes; }
}

/** Counts only WildSight's sandbox files. PhotoPicker URIs are never scanned or removed. */
export class StorageUsageService {
  async measure(context: Context): Promise<StorageUsage> {
    const usage = new StorageUsage();
    usage.databaseBytes = await this.bytes(`${context.databaseDir}/wildsight.db`);
    usage.cacheBytes = await this.bytes(`${context.cacheDir}/wildsight`);
    return usage;
  }

  async clearRebuildableCache(context: Context): Promise<number> {
    const path = `${context.cacheDir}/wildsight`;
    const before = await this.bytes(path);
    try { await fileIo.rmdir(path); } catch (_error) { return 0; }
    return before;
  }

  private async bytes(path: string): Promise<number> {
    try { return (await fileIo.stat(path)).size; } catch (_error) { return 0; }
  }

  format(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(bytes < 10 * 1024 * 1024 ? 1 : 0)} MB`;
    return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
  }
}
