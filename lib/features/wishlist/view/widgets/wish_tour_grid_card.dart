import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tourify_app/features/tour/model/tour_model.dart';

class WishTourGridCard extends StatelessWidget {
  final TourSummary tour;
  final bool isLiked;
  final bool isSelectedForCompare;
  final bool isCompareDisabled;
  final VoidCallback onToggleLike;
  final VoidCallback onTap;
  final VoidCallback onToggleCompare;

  const WishTourGridCard({
    super.key,
    required this.tour,
    required this.isLiked,
    required this.isSelectedForCompare,
    required this.isCompareDisabled,
    required this.onToggleLike,
    required this.onTap,
    required this.onToggleCompare,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final cover =
        tour.mediaCover ?? 'https://via.placeholder.com/180x140?text=Tour';
    final accent = const Color(0xFFFF5B00);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelectedForCompare ? accent : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 11,
                    child: Image.network(
                      cover,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _TypeBadge(type: tour.type),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _CompareChip(
                      selected: isSelectedForCompare,
                      disabled: isCompareDisabled && !isSelectedForCompare,
                      onTap: onToggleCompare,
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: InkWell(
                      onTap: onToggleLike,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tour.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.place_outlined, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tour.destination,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              if (tour.childAgeLimit != null)
                                _InfoChip(
                                  icon: Icons.child_care_outlined,
                                  label: 'Trẻ em ≤ ${tour.childAgeLimit}',
                                ),
                              if (tour.requiresPassport)
                                const _InfoChip(
                                  icon: Icons.badge_outlined,
                                  label: 'Cần hộ chiếu',
                                ),
                              if (tour.requiresVisa)
                                const _InfoChip(
                                  icon: Icons.assignment_ind_outlined,
                                  label: 'Cần visa',
                                ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tour.bookingsCount != null)
                            Text(
                              '${tour.bookingsCount} lượt đặt',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          Text(
                            currency.format(tour.priceFrom),
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isInternational = type.toLowerCase() == 'international';
    final color = isInternational ? Colors.blueAccent : const Color(0xFFFF5B00);
    final label = isInternational ? 'Tour quốc tế' : 'Tour trong nước';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _CompareChip extends StatelessWidget {
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _CompareChip({
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected
            ? const Color(0xFFFF5B00)
            : disabled
            ? Colors.grey.shade400
            : Colors.white.withValues(alpha: 0.85);

    return InkWell(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
          color:
              selected
                  ? const Color(0xFFFF5B00)
                  : Colors.white.withValues(alpha: 0.92),
        ),
        child: Icon(
          selected ? Icons.check : Icons.add,
          size: 18,
          color: selected ? Colors.white : borderColor,
        ),
      ),
    );
  }
}
