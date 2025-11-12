import 'package:flutter/material.dart';

import 'package:tourify_app/features/home/model/home_models.dart';

import 'section_header.dart';

class DestinationCarousel extends StatelessWidget {
  const DestinationCarousel({
    super.key,
    required this.title,
    required this.destinations,
    this.isLoading = false,
  });

  final String title;
  final List<DestinationHighlight> destinations;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(
          title: title,
          onSeeMore: () => debugPrint('Xem thêm điểm đến'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 102,
          child:
              isLoading && destinations.isEmpty
                  ? const _DestinationSkeleton()
                  : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      if (destinations.isEmpty) {
                        return const _DestinationPill(
                          name: 'Đang cập nhật',
                          imageUrl: '',
                        );
                      }
                      final dest = destinations[index];
                      return _DestinationPill(
                        name: dest.name,
                        imageUrl: dest.imageUrl,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: destinations.isEmpty ? 6 : destinations.length,
                  ),
        ),
      ],
    );
  }
}

class _DestinationPill extends StatelessWidget {
  const _DestinationPill({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => debugPrint('Chọn điểm đến: $name'),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipOval(
              child:
                  imageUrl.isEmpty
                      ? Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined),
                      )
                      : Image.network(
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
                              child: const Icon(Icons.image_not_supported),
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

class _DestinationSkeleton extends StatelessWidget {
  const _DestinationSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder:
          (_, __) => Container(
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemCount: 6,
    );
  }
}
