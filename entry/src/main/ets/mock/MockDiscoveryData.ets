import { Discovery } from '../models/Discovery';

export class MockDiscoveryData {
  /** A clean first-launch collection. Records are created through the discovery flow. */
  static fresh(): Discovery[] {
    return [];
  }

  /** Reference archive retained for UI development; it is not loaded on a clean launch. */
  static all(): Discovery[] {
    return [
      MockDiscoveryData.create('disc_0042', 'OBS.0042', 'sp_crape_myrtle', '2026-08-14T09:32:00', '杭州 · 北山街', '多云', 28, 0.92, '晨光落在刚开的花序上。', 'https://images.unsplash.com/photo-1497250681960-ef046c08a56e?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0036', 'OBS.0036', 'sp_crape_myrtle', '2026-07-12T16:08:00', '杭州 · 西湖边', '晴', 31, 0.89, '第一次留意到树皮的纹理。', 'https://images.unsplash.com/photo-1463936575829-25148e1db1b8?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0028', 'OBS.0028', 'sp_crape_myrtle', '2026-06-27T18:20:00', '上海 · 世纪公园', '阴', 26, 0.86, '风把花枝吹得很轻。', 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0019', 'OBS.0019', 'sp_crape_myrtle', '2026-06-18T11:14:00', '杭州 · 植物园', '晴', 29, 0.84, '在植物园的夏天。', 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0031', 'OBS.0031', 'sp_ginkgo', '2026-08-03T10:12:00', '杭州 · 浙江大学', '晴', 30, 0.95, '还未转黄的扇形叶。', 'https://images.unsplash.com/photo-1473445361085-b9a07f55608b?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0012', 'OBS.0012', 'sp_ginkgo', '2025-11-18T15:40:00', '杭州 · 北山街', '晴', 18, 0.93, '风落下一整条金色的路。', 'https://images.unsplash.com/photo-1542353436-312f0e1f67ff?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0040', 'OBS.0040', 'sp_nephrolepis', '2026-08-11T08:50:00', '杭州 · 玉泉山', '小雨', 25, 0.88, '雨后石墙边的蕨。', 'https://images.unsplash.com/photo-1466781783364-36c955e42a18?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0021', 'OBS.0021', 'sp_nephrolepis', '2026-05-06T14:25:00', '杭州 · 虎跑', '阴', 22, 0.82, '沿着湿润石阶展开。', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=1200&q=85'),
      MockDiscoveryData.create('disc_0008', 'OBS.0008', 'sp_nephrolepis', '2026-04-10T13:06:00', '杭州 · 九溪', '多云', 19, 0.79, '第一张观察照片。', 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1200&q=85')
    ];
  }

  static forSpecies(speciesId: string): Discovery[] {
    return MockDiscoveryData.all()
      .filter((discovery: Discovery) => discovery.speciesId === speciesId)
      .sort((left: Discovery, right: Discovery) => right.discoveredAt.getTime() - left.discoveredAt.getTime());
  }

  private static create(id: string, observationCode: string, speciesId: string, date: string,
    locationName: string, weather: string, temperature: number, confidence: number, note: string, photoUri: string): Discovery {
    const discovery = new Discovery();
    discovery.id = id;
    discovery.observationCode = observationCode;
    discovery.speciesId = speciesId;
    discovery.photoUri = photoUri;
    discovery.identifiedAt = new Date(date);
    discovery.discoveredAt = new Date(date);
    discovery.locationName = locationName;
    discovery.weather = weather;
    discovery.temperature = temperature;
    discovery.confidence = confidence;
    discovery.note = note;
    discovery.createdAt = new Date(date);
    discovery.updatedAt = new Date(date);
    return discovery;
  }
}
