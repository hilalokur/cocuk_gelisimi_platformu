import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;

import 'utils/personalized_content.dart';

class EkGidaScreen extends StatelessWidget {
  final String childId;
  final DateTime birthDate;

  const EkGidaScreen({
    super.key,
    required this.childId,
    required this.birthDate,
  });

  static const _cream = Color(0xFFF7EFE6);
  static const _paper = Color(0xFFFFFBF6);
  static const _brown = Color(0xFF5A352C);
  static const _softBrown = Color(0xFF9B6A55);
  static const _muted = Color(0xFF8C7B72);
  static const _line = Color(0xFFEADFD5);
  static const double _pagePadding = 18;
  static const double _cardGap = 14;
  static const double _cardPadding = 16;
  static const double _cardRadius = 22;
  static const double _iconBox = 46;

  int get _ageInMonths {
    return PersonalizedContent.ageProfile(birthDate).months;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Image.asset('assets/bg1.png', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(color: _cream.withValues(alpha: 0.82)),
          ),
          SafeArea(
            bottom: false,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('foods')
                  .orderBy('month')
                  .snapshots(),
              builder: (context, snapshot) {
                final items = _resolveItems(snapshot);
                final featured = _featuredItem(items);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _pagePadding,
                          8,
                          _pagePadding,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopBar(onBack: () => Navigator.pop(context)),
                            const SizedBox(height: _cardGap),
                            const _HeroHeader(),
                            const SizedBox(height: _cardGap),
                            _PersonalNutritionCard(birthDate: birthDate),
                            const SizedBox(height: _cardGap),
                            _FeaturedRecommendation(
                              item: featured,
                              ageInMonths: _ageInMonths,
                              onTap: () => _openDetails(context, featured),
                            ),
                            const SizedBox(height: _cardGap),
                            const _InfoStrip(),
                            const SizedBox(height: _cardGap),
                            const _SectionTitle(
                              title: 'Aylara Göre Rehber',
                              subtitle:
                                  'Yaşa uygun geçişleri sakin ve düzenli takip edin.',
                            ),
                            const SizedBox(height: _cardGap),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _pagePadding,
                      ),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, index) {
                          if (index == 1 || index == 5) {
                            return Column(
                              children: [
                                const SizedBox(height: _cardGap),
                                _InlineAdviceCard(
                                  advice: _adviceCards[index == 1 ? 0 : 1],
                                ),
                                const SizedBox(height: _cardGap),
                              ],
                            );
                          }
                          return const SizedBox(height: _cardGap);
                        },
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _MonthGuideCard(
                            item: item,
                            isCurrent: item.month == featured.month,
                            onTap: () => _openDetails(context, item),
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          _pagePadding,
                          _cardGap,
                          _pagePadding,
                          28,
                        ),
                        child: Column(
                          children: const [
                            _InlineAdviceCard(
                              advice: _FoodAdvice(
                                icon: Icons.block,
                                title: 'Tuz ve şeker',
                                text:
                                    'İlk yıllarda ilave tuz ve şeker kullanımını sınırlamak daha sağlıklı alışkanlıkları destekler.',
                                color: Color(0xFFF3DED4),
                              ),
                            ),
                            SizedBox(height: _cardGap),
                            _SourceCard(),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_FoodGuideItem> _resolveItems(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.hasError || snapshot.data!.docs.isEmpty) {
      return _fallbackItems;
    }

    final items = snapshot.data!.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _FoodGuideItem.fromMap(data);
        })
        .where((item) => item.title.trim().isNotEmpty)
        .toList();

    return items.isEmpty ? _fallbackItems : items;
  }

  _FoodGuideItem _featuredItem(List<_FoodGuideItem> items) {
    final age = _ageInMonths;
    final monthItems = items.where((item) => item.month >= 0).toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    if (monthItems.isEmpty) {
      return items.first;
    }

    _FoodGuideItem selected = monthItems.first;
    for (final item in monthItems) {
      if (item.month <= age) {
        selected = item;
      }
    }
    return selected;
  }

  void _openDetails(BuildContext context, _FoodGuideItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _line,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryIcon(item: item, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayTitle,
                              style: const TextStyle(
                                color: _brown,
                                fontSize: 22,
                                height: 1.12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Tag(label: item.ageLabel),
                                _Tag(label: item.category),
                                const _Tag(label: 'Sağlık Bakanlığı'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    item.foodInfo,
                    style: const TextStyle(
                      color: Color(0xFF6F5B52),
                      fontSize: 15.5,
                      height: 1.58,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _SourceCard(compact: true),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;

  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.62),
            foregroundColor: EkGidaScreen._brown,
            fixedSize: const Size(42, 42),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          child: const Text(
            'Beslenme',
            style: TextStyle(
              color: EkGidaScreen._brown,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(EkGidaScreen._cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bebek Beslenme Rehberi',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EkGidaScreen._brown,
                    fontSize: 22,
                    height: 1.12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Sağlık Bakanlığı referanslı yaşa uygun beslenme önerileri',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EkGidaScreen._muted,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: EkGidaScreen._iconBox,
            height: EkGidaScreen._iconBox,
            decoration: BoxDecoration(
              color: const Color(0xFFF1DCCB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: EkGidaScreen._softBrown,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedRecommendation extends StatelessWidget {
  final _FoodGuideItem item;
  final int ageInMonths;
  final VoidCallback onTap;

  const _FeaturedRecommendation({
    required this.item,
    required this.ageInMonths,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 166),
      padding: const EdgeInsets.all(EkGidaScreen._cardPadding),
      decoration: BoxDecoration(
        color: EkGidaScreen._brown,
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        boxShadow: [
          BoxShadow(
            color: EkGidaScreen._brown.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryIcon(
                item: item,
                inverted: true,
                size: EkGidaScreen._iconBox,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item.month > 0 ? item.month : ageInMonths}. Ay İçin Önerilenler',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: item.ageLabel, dark: true),
              _Tag(label: item.category, dark: true),
              const _Tag(label: 'T.C. Sağlık Bakanlığı', dark: true),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onTap,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Detayı Oku'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalNutritionCard extends StatelessWidget {
  final DateTime birthDate;

  const _PersonalNutritionCard({required this.birthDate});

  @override
  Widget build(BuildContext context) {
    final profile = PersonalizedContent.ageProfile(birthDate);
    final item = PersonalizedContent.dailyBundle(birthDate).nutrition;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(EkGidaScreen._cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
      ),
      child: Row(
        children: [
          Container(
            width: EkGidaScreen._iconBox,
            height: EkGidaScreen._iconBox,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1DCCB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: EkGidaScreen._softBrown,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.ageText} için beslenme önerisi',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EkGidaScreen._brown,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EkGidaScreen._muted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: EkGidaScreen._brown,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: EkGidaScreen._muted,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MonthGuideCard extends StatelessWidget {
  final _FoodGuideItem item;
  final bool isCurrent;
  final VoidCallback onTap;

  const _MonthGuideCard({
    required this.item,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        child: Ink(
          height: 146,
          padding: const EdgeInsets.all(EkGidaScreen._cardPadding),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: isCurrent ? 0.78 : 0.48),
            borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
            border: Border.all(
              color: isCurrent
                  ? EkGidaScreen._softBrown.withValues(alpha: 0.28)
                  : Colors.white.withValues(alpha: 0.64),
            ),
          ),
          child: Row(
            children: [
              _CategoryIcon(item: item, size: EkGidaScreen._iconBox),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EkGidaScreen._brown,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EkGidaScreen._muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _Tag(label: item.ageLabel),
                        _Tag(label: item.category),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: EkGidaScreen._softBrown,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _MiniInfoCard(
            icon: Icons.water_drop_outlined,
            title: 'Su',
            text: 'Ek gıda ile birlikte küçük yudumlarla desteklenebilir.',
            color: Color(0xFFDCEBF2),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _MiniInfoCard(
            icon: Icons.warning_amber_rounded,
            title: 'Bal',
            text: '1 yaş öncesinde bal verilmemesi önerilir.',
            color: Color(0xFFF3E2C8),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.all(EkGidaScreen._cardPadding),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: EkGidaScreen._brown, size: 23),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EkGidaScreen._brown,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EkGidaScreen._muted,
              fontSize: 11.5,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAdviceCard extends StatelessWidget {
  final _FoodAdvice advice;

  const _InlineAdviceCard({required this.advice});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(EkGidaScreen._cardPadding),
      decoration: BoxDecoration(
        color: advice.color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: Row(
        children: [
          Container(
            width: EkGidaScreen._iconBox,
            height: EkGidaScreen._iconBox,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(advice.icon, color: EkGidaScreen._brown, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  advice.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EkGidaScreen._brown,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EkGidaScreen._muted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final bool compact;

  const _SourceCard({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: compact ? 74 : 86),
      padding: EdgeInsets.all(compact ? 14 : EkGidaScreen._cardPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(EkGidaScreen._cardRadius),
        border: Border.all(color: EkGidaScreen._line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_outlined,
            color: EkGidaScreen._softBrown,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bu içerikler T.C. Sağlık Bakanlığı referans alınarak hazırlanmıştır.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EkGidaScreen._muted,
                fontSize: compact ? 12.5 : 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final _FoodGuideItem item;
  final bool inverted;
  final double size;

  const _CategoryIcon({
    required this.item,
    this.inverted = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Icon(
        item.icon,
        color: inverted ? Colors.white : EkGidaScreen._softBrown,
        size: size * 0.5,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool dark;

  const _Tag({required this.label, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark
              ? Colors.white.withValues(alpha: 0.86)
              : EkGidaScreen._softBrown,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FoodGuideItem {
  final int month;
  final String title;
  final String foodInfo;

  const _FoodGuideItem({
    required this.month,
    required this.title,
    required this.foodInfo,
  });

  factory _FoodGuideItem.fromMap(Map<String, dynamic> data) {
    return _FoodGuideItem(
      month: (data['month'] as num?)?.toInt() ?? 0,
      title: (data['title'] ?? '').toString(),
      foodInfo: (data['foodInfo'] ?? '').toString(),
    );
  }

  String get displayTitle {
    if (month == -2) {
      return 'Bebek Beslenmesi ve Anne Sütü';
    }
    if (month == -1) {
      return 'Genel Beslenme Önerileri';
    }
    if (month == 13) {
      return 'Okul Öncesi Sağlıklı Beslenme';
    }
    return title.isEmpty ? '$month. Ay Önerileri' : title;
  }

  String get summary {
    final clean = foodInfo
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('•', '')
        .trim();
    if (clean.isEmpty) {
      return defaultSummary;
    }
    return clean.length > 150 ? '${clean.substring(0, 150)}...' : clean;
  }

  String get defaultSummary {
    if (month == -2) {
      return 'Anne sütü, bebeğin büyüme ve bağışıklık desteği için temel beslenme kaynağıdır.';
    }
    if (month == -1) {
      return 'Besin çeşitliliği, hijyen ve bebeğin hazır oluş sinyalleri birlikte değerlendirilir.';
    }
    if (month == 13) {
      return 'Okul öncesi dönemde dengeli tabak ve düzenli öğün alışkanlığı desteklenir.';
    }
    if (month <= 6) {
      return 'Ek gıdaya geçişte küçük miktarlar, tek tek denemeler ve sakin öğün rutini önemlidir.';
    }
    if (month <= 8) {
      return 'Meyve, sebze ve yoğurt gibi yeni tatlar uygun kıvamlarla denenebilir.';
    }
    return 'Aile sofrasına geçişte çeşitlilik, uygun porsiyon ve güvenli kıvamlar öne çıkar.';
  }

  String get category {
    if (month == -2) {
      return 'Anne sütü';
    }
    if (month == -1) {
      return 'Genel öneriler';
    }
    if (month == 13 || month >= 36) {
      return 'Okul öncesi';
    }
    if (month == 7) {
      return 'Meyve/sebze';
    }
    if (month == 8) {
      return 'Yeni tatlar';
    }
    return 'Ek gıda';
  }

  String get ageLabel {
    if (month == -2) {
      return '0-6 Ay';
    }
    if (month == -1) {
      return 'Tüm dönemler';
    }
    if (month == 13) {
      return 'Okul öncesi dönem';
    }
    return '$month. Ay';
  }

  IconData get icon {
    if (month == -2) {
      return Icons.favorite_border_rounded;
    }
    if (month == -1) {
      return Icons.auto_awesome_rounded;
    }
    if (month == 13 || month >= 36) {
      return Icons.school_outlined;
    }
    if (category == 'Meyve/sebze') {
      return Icons.eco_outlined;
    }
    if (category == 'Yeni tatlar') {
      return Icons.local_cafe_outlined;
    }
    return Icons.restaurant_menu_rounded;
  }

  Color get color {
    if (month == -2) {
      return const Color(0xFFF4DDE0);
    }
    if (month == -1) {
      return const Color(0xFFF5E8C8);
    }
    if (month == 13 || month >= 36) {
      return const Color(0xFFDDE8F0);
    }
    if (category == 'Meyve/sebze') {
      return const Color(0xFFE4EFD8);
    }
    if (category == 'Yeni tatlar') {
      return const Color(0xFFF0DED1);
    }
    return const Color(0xFFF4E7D8);
  }
}

class _FoodAdvice {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _FoodAdvice({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });
}

const _adviceCards = [
  _FoodAdvice(
    icon: Icons.child_care_rounded,
    title: 'Bebeğin ritmini izle',
    text:
        'Yeni bir besini denerken acele etmeden, küçük porsiyonlarla ilerlemek daha konforlu olur.',
    color: Color(0xFFE9E1F1),
  ),
  _FoodAdvice(
    icon: Icons.clean_hands_outlined,
    title: 'Hijyen ve güvenli kıvam',
    text:
        'Besinleri iyi yıkamak, uygun pişirmek ve boğulma riskini azaltan kıvamlar tercih etmek önemlidir.',
    color: Color(0xFFDCECE6),
  ),
];

const _fallbackItems = [
  _FoodGuideItem(
    month: -2,
    title: 'Bebek Beslenmesi ve Anne Sütü',
    foodInfo:
        'İlk aylarda anne sütü bebeğin temel beslenme kaynağıdır. Emzirme düzeni, bebeğin açlık ve tokluk sinyalleri izlenerek desteklenebilir.',
  ),
  _FoodGuideItem(
    month: -1,
    title: 'Genel Beslenme Önerileri',
    foodInfo:
        'Ek gıdaya geçişte bebeğin hazır oluşu, uygun kıvam, hijyen ve besinlerin tek tek denenmesi önemlidir. Şüpheli durumlarda çocuk sağlığı uzmanına danışılmalıdır.',
  ),
  _FoodGuideItem(
    month: 6,
    title: '6. Ay - Ek Gıdaya Geçiş',
    foodInfo:
        '6. ay civarında ek gıda küçük miktarlarla başlanabilir. Sebze püreleri, yoğurt ve uygun tahıllar bebeğin toleransına göre denenebilir.',
  ),
  _FoodGuideItem(
    month: 7,
    title: '7. Ay - Meyve ve Sebzeler',
    foodInfo:
        'Meyve ve sebzeler yumuşak kıvamda, tek tek denenerek verilebilir. Her yeni besinde bebeğin tepkileri gözlenmelidir.',
  ),
  _FoodGuideItem(
    month: 8,
    title: '8. Ay - Yeni Tatlar',
    foodInfo:
        'Bu dönemde kıvam yavaşça artırılabilir. Çorba, yoğurt, sebze ve uygun protein kaynakları küçük porsiyonlarla çeşitlendirilebilir.',
  ),
  _FoodGuideItem(
    month: 9,
    title: '9. Ay - Parmak Besinler',
    foodInfo:
        'Bebeğin güvenli şekilde tutabileceği yumuşak parmak besinler desteklenebilir. Sert, yuvarlak ve boğulma riski taşıyan besinlerden kaçınılmalıdır.',
  ),
  _FoodGuideItem(
    month: 12,
    title: '12. Ay - Aile Sofrasına Geçiş',
    foodInfo:
        '1 yaş civarında aile sofrasına geçiş desteklenebilir. Öğün düzeni, çeşitlilik ve ilave tuz/şekerden kaçınma önemini korur.',
  ),
  _FoodGuideItem(
    month: 13,
    title: 'Okul Öncesi Sağlıklı Beslenme',
    foodInfo:
        'Okul öncesi dönemde düzenli öğünler, yeterli su tüketimi, meyve-sebze çeşitliliği ve dengeli tabak alışkanlığı desteklenmelidir.',
  ),
];

class WebDataService {
  final List<String> _urls = [
    'https://hsgm.saglik.gov.tr/tr/beslenme/bebek-beslenmesi.html',
    'https://hsgm.saglik.gov.tr/tr/beslenme/okul-oncesi-beslenme.html',
  ];

  Future<void> syncMinistryData() async {
    try {
      final existingDocs = await FirebaseFirestore.instance
          .collection('foods')
          .get();
      for (final doc in existingDocs.docs) {
        await doc.reference.delete();
      }

      final blackList = [
        'Ana Sayfa',
        'Başkanlığımız',
        'Daire Başkanı',
        'Görev Tanımı',
        'Dokümanlar',
        'Afişler',
        'Broşürler',
        'İngilizce Yayınlar',
        'Kitaplar',
        'Rehberler',
        'Programlar',
        'Sunumlar',
        'Videolar',
        'Haberler',
        'İletişim',
        'Yazdır',
        'Yeterli ve Dengeli Beslenme',
        'Temel Besin Grupları',
        'Yaş Dönemlerinde Beslenme',
        'Gebelik Döneminde Beslenme',
        'Emziklilik Döneminde Beslenme',
        'Bebek Beslenmesi',
        'Okul Öncesinde Sağlıklı Beslenme',
        'Okul Çağı Çocuklarında Beslenme',
        'Ergenlik Döneminde Beslenme',
        'Yaşlılıkta Beslenme',
        'Menopoz Döneminde Beslenme',
        'Özel Durumlarda Beslenme',
        'Hastalıklarda Beslenme',
        'Besin Güvenliği ve Hijyen',
        'Aylara Göre Verilmesi Önerilen Tamamlayıcı Besinler',
      ];

      for (final url in _urls) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) continue;

        final document = parser.parse(response.body);
        final contentArea =
            document.querySelector('.content-area') ?? document.body;
        if (contentArea == null) continue;

        if (url.contains('okul-oncesi')) {
          await _syncPreschoolNutrition(contentArea, blackList);
        } else {
          await _syncBabyNutrition(contentArea, blackList);
        }
      }
      debugPrint('Beslenme verileri senkronize edildi.');
    } catch (e) {
      debugPrint('Beslenme veri senkronizasyon hatası: $e');
    }
  }

  Future<void> _syncPreschoolNutrition(
    dynamic contentArea,
    List<String> blackList,
  ) async {
    var fullContent = '';
    var startCollecting = false;

    for (final element in contentArea.querySelectorAll('*')) {
      final text = element.text.trim();
      final tag = (element.localName ?? '').toLowerCase();

      if (text.toLowerCase().contains('öneriler aşağıda sıralanmıştır')) {
        startCollecting = true;
        continue;
      }

      if (!startCollecting) continue;
      if (text.contains('Son Güncelleme')) break;

      final isBadData = blackList.any((badWord) => text.contains(badWord));
      final isJoinedMenu = text.length > 20 && !text.contains(' ');
      if (isBadData || isJoinedMenu || text.isEmpty) continue;

      if (tag == 'li' && text.length > 25) {
        fullContent += '• $text\n\n';
      } else if (tag == 'p' &&
          (text.length > 40 || text.contains('el yıkama'))) {
        fullContent += '$text\n\n';
      }
    }

    if (fullContent.isNotEmpty) {
      await _saveToFirebase(
        13,
        'Okul Öncesi Sağlıklı Beslenme',
        fullContent.trim(),
      );
    }
  }

  Future<void> _syncBabyNutrition(
    dynamic contentArea,
    List<String> blackList,
  ) async {
    var introContent = '';
    final allElements = contentArea.querySelectorAll('p, ul, strong');

    for (final element in allElements) {
      final text = element.text.trim();
      if (text.contains('. ay')) break;

      final isMenuText = blackList.any((badWord) => text == badWord);
      final isLongJoinedText = text.length > 30 && !text.contains(' ');
      if (isMenuText || isLongJoinedText || text.isEmpty) continue;

      if (element.localName == 'p' && text.length > 25) {
        introContent += '$text\n\n';
      } else if (element.localName == 'ul') {
        final items = element
            .querySelectorAll('li')
            .map((e) => e.text.trim())
            .where((t) => t.length > 5 && !blackList.contains(t));
        if (items.isNotEmpty) introContent += '• ${items.join('\n• ')}\n\n';
      }
    }

    if (introContent.isNotEmpty) {
      await _saveToFirebase(
        -2,
        'Bebek Beslenmesi ve Anne Sütü',
        introContent.trim(),
      );
    }

    final headers = contentArea.querySelectorAll('strong, h3, h4');
    for (final header in headers) {
      final title = header.text.trim();
      final isMonth = title.contains('. ay');
      final isGeneral =
          title.toLowerCase().contains('öneri') ||
          title.toLowerCase().contains('ilke') ||
          title.toLowerCase().contains('emzirme');

      if (!isMonth && !isGeneral) continue;

      var details = '';
      var next = header.parent?.localName == 'p'
          ? header.parent?.nextElementSibling
          : header.nextElementSibling;
      var limit = 0;

      while (next != null && limit < 20) {
        final nextTag = (next.localName ?? '').toLowerCase();
        final nextText = next.text.trim();

        if (nextText.contains('. ay') &&
            (nextTag.startsWith('h') ||
                next.querySelectorAll('strong').isNotEmpty)) {
          break;
        }

        final isRepeatInfo =
            nextText.contains('şeker ve şeker eklenmiş') ||
            nextText.contains('6-12 aylık dönemde') ||
            nextText.contains('Tuz: Tuz bebeği susatır') ||
            nextText.contains('Tamamlayıcı besinler bebek açken') ||
            nextText.contains('Genel Öneriler');

        if (isMonth && isRepeatInfo) {
          next = next.nextElementSibling;
          continue;
        }

        if (nextTag == 'ul') {
          details +=
              '${next.querySelectorAll('li').map((e) => '• ${e.text.trim()}').join('\n')}\n';
        } else if (nextTag == 'p' && nextText.length > 5) {
          details += '$nextText\n\n';
        }

        next = next.nextElementSibling;
        limit++;
      }

      if (details.isNotEmpty) {
        final monthOrder = isMonth ? _calculateOrder(title) : -1;
        await _saveToFirebase(monthOrder, title, details.trim());
      }
    }
  }

  Future<void> _saveToFirebase(int month, String title, String info) async {
    await FirebaseFirestore.instance.collection('foods').add({
      'month': month,
      'title': title,
      'foodInfo': info,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  int _calculateOrder(String text) {
    final regExp = RegExp(r'(\d+)');
    final match = regExp.firstMatch(text);
    if (match != null) {
      final val = int.parse(match.group(0)!);
      return text.contains('yaş') ? val * 12 : val;
    }
    return 0;
  }
}
