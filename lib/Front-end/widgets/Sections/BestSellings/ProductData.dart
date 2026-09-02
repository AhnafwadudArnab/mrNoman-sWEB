import '../../../pages/Templates/all_products_template.dart';

class SampleProducts {
  static final List<ProductData> bestSellingProducts = [
    ProductData(
      id: '1',
      name: 'Electric Blender',
      category: 'Kitchen Appliances',
      priceBDT: 3500,
      images: ['assets/prod/blender.jpg'],
      description: 'High-quality electric blender for smooth blending.',
      additionalInfo: {
        'Brand': 'ElectroZoneBD',
        'Warranty': '1 year',
        'stock_quantity': '15',
      },
    ),
    ProductData(
      id: '2',
      name: 'Electric Oven',
      category: 'Kitchen Appliances',
      priceBDT: 8500,
      images: ['assets/prod/oven.jpg'],
      description: 'Multi-function electric oven for baking and grilling.',
      additionalInfo: {
        'Capacity': '25L',
        'Warranty': '2 years',
        'stock_quantity': '8',
      },
    ),
    ProductData(
      id: '3',
      name: 'Rice Cooker',
      category: 'Kitchen Appliances',
      priceBDT: 2200,
      images: ['assets/prod/rice_cooker.jpg'],
      description: 'Automatic rice cooker with keep-warm function.',
      additionalInfo: {
        'Capacity': '1.8L',
        'Warranty': '1 year',
        'stock_quantity': '20',
      },
    ),
    ProductData(
      id: '4',
      name: 'Hair Dryer',
      category: 'Personal Care',
      priceBDT: 1800,
      images: ['assets/prod/hair_drier.jpg'],
      description: 'Professional hair dryer with multiple heat settings.',
      additionalInfo: {
        'Power': '1800W',
        'Warranty': '1 year',
        'stock_quantity': '12',
      },
    ),
  ];
}
