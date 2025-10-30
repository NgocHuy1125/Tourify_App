import 'package:flutter/material.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    const categories = [
      {
        'label': 'Vui chơi & Trải nghiệm',
        'image': 'assets/images/kkc-icon.png',
      },
      {
        'label': 'Di chuyển',
        'image': 'assets/images/xb-icon.png',
      },
      {
        'label': 'Thuê xe tự lái',
        'image': 'assets/images/oto-icon.png',
      },
      {
        'label': 'Khách sạn',
        'image': 'assets/images/ks-icon.png',
      },
      {
        'label': 'eSIM',
        'image': 'assets/images/vtq-icon.png',
      },
      {
        'label': 'Tất cả mục',
        'image': 'assets/images/kkc-icon.png',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            categories
                .map(
                  (category) => Expanded(
                    child: _CategoryIcon(
                      imagePath: category['image']!,
                      label: category['label']!,
                      onTap: () =>
                          debugPrint('Chọn danh mục ${category['label']}'),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _CategoryIcon({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
