import 'package:flutter/material.dart';
import 'section_header.dart';

class DestinationCarousel extends StatelessWidget {
  final String title;
  const DestinationCarousel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final destinations = [
      {
        'name': 'TP. HCM',
        'image':
            'https://res.klook.com/image/upload/fl_lossy.progressive,w_96,h_96,c_fill,q_85/cities/gagpmpohflexp1kfy9vr.webp',
      },
      {
        'name': 'Đà Nẵng',
        'image':
            'https://res.klook.com/image/upload/fl_lossy.progressive,w_96,h_96,c_fill,q_85/cities/rxqumcihtzatvhcnbedi.webp',
      },
      {
        'name': 'Hà Nội',
        'image':
            'https://res.klook.com/image/upload/fl_lossy.progressive,w_96,h_96,c_fill,q_85/cities/ysnkhkzabobjbg72x3sz.webp',
      },
      {
        'name': 'Phú Quốc',
        'image':
            'https://res.klook.com/image/upload/fl_lossy.progressive,w_96,h_96,c_fill,q_85/cities/fdopxuk1tinxvtylpax8.webp',
      },
    ];

    return Column(
      children: [
        SectionHeader(
          title: title,
          onSeeMore: () => debugPrint('Xem thêm điểm đến'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return _DestinationPill(
                name: dest['name']!,
                imageUrl: dest['image']!,
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: destinations.length,
          ),
        ),
      ],
    );
  }
}

class _DestinationPill extends StatelessWidget {
  final String name;
  final String imageUrl;

  const _DestinationPill({required this.name, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => debugPrint('Chọn điểm đến: $name'),
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child: Image.network(
                imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
