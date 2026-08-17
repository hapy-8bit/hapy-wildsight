import { OrganismCategory, PetSafety, Species } from '../models/Species';

export class MockSpeciesData {
  static all(): Species[] {
    return [MockSpeciesData.crapeMyrtle(), MockSpeciesData.ginkgo(), MockSpeciesData.nephrolepis()];
  }

  static byId(id: string): Species | undefined {
    return MockSpeciesData.all().find((species: Species) => species.id === id);
  }

  static crapeMyrtle(): Species {
    const species = new Species();
    species.id = 'sp_crape_myrtle';
    species.category = OrganismCategory.PLANT;
    species.chineseName = '紫薇';
    species.scientificName = 'Lagerstroemia indica';
    species.aliases = ['百日红', '痒痒树'];
    species.family = '千屈菜科';
    species.genus = '紫薇属';
    species.description = '夏日常见的开花乔木，花序轻盈，树皮会自然斑驳脱落。';
    species.distribution = '原产东亚，在中国多地庭园、公园及道路绿化中常见。';
    species.features = ['圆锥花序，花瓣边缘褶皱', '树皮光滑斑驳', '花期长，盛夏仍可见'];
    species.floweringPeriod = '6–9 月';
    species.toxicity = '未见常见毒性记录';
    species.petSafety = PetSafety.UNKNOWN;
    species.coverPhotoUri = 'https://images.unsplash.com/photo-1497250681960-ef046c08a56e?auto=format&fit=crop&w=1200&q=85';
    return species;
  }

  static ginkgo(): Species {
    const species = new Species();
    species.id = 'sp_ginkgo';
    species.category = OrganismCategory.PLANT;
    species.chineseName = '银杏';
    species.scientificName = 'Ginkgo biloba';
    species.aliases = ['白果树'];
    species.family = '银杏科';
    species.genus = '银杏属';
    species.description = '古老的孑遗植物，扇形叶片在秋天转为明亮的金黄。';
    species.distribution = '中国广泛栽培，城市道路、校园与寺院中常见。';
    species.features = ['扇形叶片', '叶脉二叉分枝', '秋季叶色金黄'];
    species.floweringPeriod = '4–5 月';
    species.toxicity = '种子外种皮可能刺激皮肤';
    species.petSafety = PetSafety.CAUTION;
    species.coverPhotoUri = 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?auto=format&fit=crop&w=1200&q=85';
    return species;
  }

  static nephrolepis(): Species {
    const species = new Species();
    species.id = 'sp_nephrolepis';
    species.category = OrganismCategory.PLANT;
    species.chineseName = '肾蕨';
    species.scientificName = 'Nephrolepis cordifolia';
    species.aliases = ['蜈蚣草'];
    species.family = '肾蕨科';
    species.genus = '肾蕨属';
    species.description = '羽状复叶层层展开，在潮湿、半阴的环境里常能看见。';
    species.distribution = '温暖湿润地区常见，可在林缘、石墙与园林阴湿处观察到。';
    species.features = ['羽状叶片', '叶轴细长弯曲', '喜阴湿环境'];
    species.floweringPeriod = '不开花，以孢子繁殖';
    species.toxicity = '无明确常见毒性记录';
    species.petSafety = PetSafety.SAFE;
    species.coverPhotoUri = 'https://images.unsplash.com/photo-1485955900006-10f4d324d411?auto=format&fit=crop&w=1200&q=85';
    return species;
  }

  static identificationAlternatives(): Species[] {
    return [
      MockSpeciesData.createAlternative('sp_lagerstroemia_speciosa', '大花紫薇', 'Lagerstroemia speciosa', '千屈菜科', '紫薇属'),
      MockSpeciesData.createAlternative('sp_lagerstroemia_floribunda', '南洋紫薇', 'Lagerstroemia floribunda', '千屈菜科', '紫薇属'),
      MockSpeciesData.createAlternative('sp_lagerstroemia_fauriei', '福建紫薇', 'Lagerstroemia fauriei', '千屈菜科', '紫薇属')
    ];
  }

  private static createAlternative(id: string, chineseName: string, scientificName: string, family: string, genus: string): Species {
    const species = new Species();
    species.id = id;
    species.category = OrganismCategory.PLANT;
    species.chineseName = chineseName;
    species.scientificName = scientificName;
    species.family = family;
    species.genus = genus;
    return species;
  }
}
