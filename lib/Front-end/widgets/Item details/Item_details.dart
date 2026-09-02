import 'package:flutter/material.dart';

import '../../Dimensions/responsive_dimensions.dart';
import '../../utils/image_resolver.dart';

class ItemDetailsPage extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int price;
  final double rating;

  const ItemDetailsPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: EdgeInsets.all(AppDimensions.padding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                ImageResolver.resolveUrl(imageUrl),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.titleFont(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(rating.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Price: Tk $price',
              style: TextStyle(
                fontSize: AppDimensions.titleFont(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Product description goes here. This is a demo item details screen.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
