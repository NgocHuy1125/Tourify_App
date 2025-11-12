import 'package:flutter/material.dart';

import 'package:tourify_app/features/home/model/home_models.dart';
import 'package:tourify_app/features/home/view/all_tours_screen.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.categories,
    this.isLoading = false,
  });

  final List<CategoryItem> categories;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final items = categories.take(6).toList();
    final showSkeleton = isLoading && items.isEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child:
          showSkeleton
              ? const _CategorySkeleton()
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(6, (index) {
                  final item =
                      index < items.length
                          ? items[index]
                          : const CategoryItem(id: '', name: 'Đang cập nhật');
                  final hasCategory = item.id.isNotEmpty;
                  return Expanded(
                    child: _CategoryIcon(
                      imageUrl: item.coverImage ?? item.imageUrl,
                      label: item.name,
                      onTap:
                          hasCategory
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AllToursScreen(
                                        category: item,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                    ),
                  );
                }),
              ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.imageUrl,
    required this.label,
    this.onTap,
  });

  final String? imageUrl;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                imageUrl == null || imageUrl!.isEmpty
                    ? Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.category_outlined, size: 24),
                    )
                    : Image.network(
                      imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.category_outlined, size: 24),
                          ),
                    ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
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

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        6,
        (_) => Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
