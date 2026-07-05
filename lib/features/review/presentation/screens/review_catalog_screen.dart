import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:travel_advisor_mobile/core/di/injection_container.dart';
import 'package:travel_advisor_mobile/core/theme/app_colors.dart';
import 'package:travel_advisor_mobile/core/widgets/net_image.dart';
import 'package:travel_advisor_mobile/features/review/domain/entities/review_types.dart';
import 'package:travel_advisor_mobile/features/review/domain/repositories/review_repository.dart';
import 'package:travel_advisor_mobile/features/review/presentation/constants/review_tags.dart'
    show getTagsForCategory;
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_cubit.dart';
import 'package:travel_advisor_mobile/features/review/presentation/cubit/review_state.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/place_review_screen.dart';
import 'package:travel_advisor_mobile/features/review/presentation/screens/rate_itinerary_screen.dart';

bool _isVideoUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.m4v') ||
      path.endsWith('.webm');
}

Future<void> openReviewItem(
  BuildContext context,
  ReviewCatalogItem item,
) async {
  if (item.isReviewed) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewReadOnlyScreen(item: item)),
    );
    return;
  }
  if (item.isItinerary) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RateItineraryScreen(
          itineraryId: item.itineraryId,
          popExtraOnSubmit: false,
        ),
      ),
    );
    return;
  }
  // Pending place: mở PlaceReviewScreen trực tiếp, không qua RateItineraryScreen
  await openPendingPlaceReview(context, item);
}

/// Mở PlaceReviewScreen cho một địa điểm đang chờ đánh giá (pending place).
///
/// Load detail itinerary theo yêu cầu (chỉ khi user tap), tìm đúng location
/// để lấy categoryId cho tag, rồi push PlaceReviewScreen với submitOnSave: true
/// để submit DB ngay khi user bấm Gửi đánh giá.
///
/// Cubit được tạo cục bộ và đóng sau khi route pop — không chia sẻ với route khác.
Future<void> openPendingPlaceReview(
  BuildContext context,
  ReviewCatalogItem item,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final itineraryId = item.itineraryId;
  final detailId = item.itineraryDetailId;

  if (itineraryId.isEmpty || detailId == null || detailId.isEmpty) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Không tìm thấy thông tin địa điểm cần đánh giá'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final cubit = sl<ReviewCubit>();
  try {
    await cubit.loadReviewData(itineraryId);
    if (!context.mounted) return;

    final state = cubit.state;
    if (state is! ReviewLoaded) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Không thể tải dữ liệu đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final location = state.itinerary.locations
        .where((l) => l.id == detailId)
        .firstOrNull;

    if (location == null) {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy địa điểm trong lịch trình'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Địa điểm đã review → chỉ xem read-only, không dùng cubit nữa
    if (location.hasReview) {
      await openReviewedPlaceReview(
        context,
        itineraryId: itineraryId,
        itineraryDetailId: detailId,
      );
      return;
    }

    // Chưa review → mở PlaceReviewScreen với cubit này, submit DB ngay khi Gửi
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceReviewScreen(
          locationId: detailId,
          reviewCubit: cubit,
          submitOnSave: true,
          itineraryId: itineraryId,
          reviewTags: getTagsForCategory(location.categoryId),
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Không thể mở đánh giá: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } finally {
    // Đóng cubit sau khi route pop (hoặc khi có lỗi), tránh rò rỉ state
    cubit.close();
  }
}

Future<void> openReviewedItineraryReview(
  BuildContext context,
  String itineraryId, {
  SubmittedReviewData? cachedData,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final data =
        cachedData ??
        await sl<ReviewRepository>().getSubmittedReview(itineraryId);
    if (!context.mounted) return;
    await openReviewItem(context, reviewCatalogItemFromSubmittedReview(data));
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text('Khong the tai danh gia: $e')),
    );
  }
}

Future<void> openReviewedPlaceReview(
  BuildContext context, {
  required String itineraryId,
  required String itineraryDetailId,
  SubmittedReviewData? cachedData,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    // Dùng cache nếu có, tránh gọi API thêm lần nữa
    final data =
        cachedData ??
        await sl<ReviewRepository>().getSubmittedReview(itineraryId);
    SubmittedPlaceReview? place;
    for (final item in data.places) {
      if (item.itineraryDetailId == itineraryDetailId) {
        place = item;
        break;
      }
    }

    if (place == null) {
      throw StateError('Khong tim thay danh gia dia diem da gui.');
    }
    if (!context.mounted) return;
    await openReviewItem(
      context,
      reviewCatalogItemFromSubmittedPlace(data, place),
    );
  } catch (e) {
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(content: Text('Khong the tai danh gia: $e')),
    );
  }
}

ReviewCatalogItem reviewCatalogItemFromSubmittedReview(
  SubmittedReviewData data,
) {
  return ReviewCatalogItem(
    kind: 'itinerary',
    status: 'reviewed',
    reviewId: null,
    itineraryId: data.itineraryId,
    itineraryDetailId: null,
    placeId: null,
    title: data.itineraryTitle,
    imageUrl: data.coverImage,
    rating: data.overallRating,
    content: data.overallContent,
    reviewedAt: data.overallReviewedAt,
    itineraryTitle: data.itineraryTitle,
    destination: data.destination,
    startDate: _parseDate(data.startDate),
    endDate: _parseDate(data.endDate),
    visitDate: null,
    tags: data.overallTags,
    mediaUrls: data.overallMediaUrls,
    reviewStatus: null,
    itineraryStatus: data.itineraryStatus,
    placeReviews: data.places
        .where((place) => place.rating != null)
        .map(
          (place) => reviewedPlaceItemFromSubmittedPlace(
            place,
            startDate: data.startDate,
          ),
        )
        .toList(),
  );
}

ReviewCatalogItem reviewCatalogItemFromSubmittedPlace(
  SubmittedReviewData data,
  SubmittedPlaceReview place,
) {
  return ReviewCatalogItem(
    kind: 'place',
    status: 'reviewed',
    reviewId: null,
    itineraryId: data.itineraryId,
    itineraryDetailId: place.itineraryDetailId,
    placeId: null,
    title: place.placeName,
    imageUrl: place.placeImageUrl,
    rating: place.rating,
    content: place.content,
    reviewedAt: place.reviewedAt,
    itineraryTitle: data.itineraryTitle,
    destination: data.destination,
    startDate: _parseDate(data.startDate),
    endDate: _parseDate(data.endDate),
    visitDate: _computeVisitDate(data.startDate, place.dayLabel),
    tags: place.tags,
    mediaUrls: place.mediaUrls,
    reviewStatus: null,
    itineraryStatus: data.itineraryStatus,
    placeReviews: const [],
  );
}

ReviewedPlaceItem reviewedPlaceItemFromSubmittedPlace(
  SubmittedPlaceReview place, {
  String startDate = '',
}) {
  return ReviewedPlaceItem(
    title: place.placeName,
    imageUrl: place.placeImageUrl,
    rating: place.rating ?? 0,
    content: place.content,
    visitDate: _computeVisitDate(startDate, place.dayLabel),
    tags: place.tags,
    mediaUrls: place.mediaUrls,
    reviewedAt: place.reviewedAt,
  );
}

DateTime? _parseDate(String value) => DateTime.tryParse(value);

DateTime? _computeVisitDate(String startDate, String dayLabel) {
  final start = DateTime.tryParse(startDate);
  if (start == null) return null;
  final match = RegExp(r'(\d+)').firstMatch(dayLabel.toUpperCase());
  final day = int.tryParse(match?.group(1) ?? '') ?? 1;
  return start.add(Duration(days: day - 1));
}

class ReviewCatalogScreen extends StatefulWidget {
  final int initialTab;
  const ReviewCatalogScreen({super.key, this.initialTab = 0});

  @override
  State<ReviewCatalogScreen> createState() => _ReviewCatalogScreenState();
}

class _ReviewCatalogScreenState extends State<ReviewCatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<ReviewCatalog> _catalog;
  String _kind = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _catalog = sl<ReviewRepository>().getReviewCatalog();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _open(ReviewCatalogItem item) async {
    await openReviewItem(context, item);
    if (mounted) {
      setState(() => _catalog = sl<ReviewRepository>().getReviewCatalog());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Danh sách đánh giá',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Chờ đánh giá'),
            Tab(text: 'Đã đánh giá'),
          ],
        ),
      ),
      body: FutureBuilder<ReviewCatalog>(
        future: _catalog,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Không thể tải đánh giá: ${snapshot.error}'),
            );
          }
          final data = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tất cả')),
                    ButtonSegment(
                      value: 'itinerary',
                      label: Text('Lịch trình'),
                      icon: Icon(Icons.route_outlined),
                    ),
                    ButtonSegment(
                      value: 'place',
                      label: Text('Địa điểm'),
                      icon: Icon(Icons.place_outlined),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (value) =>
                      setState(() => _kind = value.first),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ReviewList(items: data.pending, kind: _kind, onTap: _open),
                    _ReviewList(
                      items: data.reviewed,
                      kind: _kind,
                      onTap: _open,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  final List<ReviewCatalogItem> items;
  final String kind;
  final ValueChanged<ReviewCatalogItem> onTap;
  const _ReviewList({
    required this.items,
    required this.kind,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visible = kind == 'all'
        ? items
        : items.where((e) => e.kind == kind).toList();
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 44,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có đánh giá trong mục này.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: visible.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = visible[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              onTap: () => onTap(item),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEAF3FB),
                child: Icon(
                  item.isItinerary
                      ? Icons.route_outlined
                      : Icons.place_outlined,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: _ReviewItemSubtitle(item: item),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewItemSubtitle extends StatelessWidget {
  final ReviewCatalogItem item;
  const _ReviewItemSubtitle({required this.item});

  String _date(DateTime? value) =>
      value == null ? 'không rõ ngày' : DateFormat('dd/MM/yyyy').format(value);

  @override
  Widget build(BuildContext context) {
    final contextLine = item.isItinerary
        ? 'Lịch trình du lịch ${item.destination ?? 'chưa xác định điểm đến'} từ ngày ${_date(item.startDate)} đến ngày ${_date(item.endDate)}'
        : 'Ghé thăm ngày ${_date(item.visitDate)} • Lịch trình ${item.itineraryTitle ?? 'không xác định'}';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(contextLine, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (item.isReviewed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFA500),
                  size: 17,
                ),
                Text(' ${item.rating?.toStringAsFixed(1) ?? '–'}'),
                if (item.reviewedAt != null)
                  Text('  •  ${_date(item.reviewedAt)}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ReviewReadOnlyScreen extends StatelessWidget {
  final ReviewCatalogItem item;
  const ReviewReadOnlyScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          item.isItinerary ? 'Đánh giá lịch trình' : 'Đánh giá địa điểm',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: item.isItinerary
            ? _ItineraryReviewDetail(item: item)
            : _PlaceReviewDetail(item: item),
      ),
    );
  }
}

class _ItineraryReviewDetail extends StatelessWidget {
  final ReviewCatalogItem item;
  const _ItineraryReviewDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy');
    final range = item.startDate == null || item.endDate == null
        ? 'Không rõ thời gian'
        : '${date.format(item.startDate!)} - ${date.format(item.endDate!)}';
    final status = switch (item.itineraryStatus?.toLowerCase()) {
      'completed' => 'HOÀN THÀNH',
      'ongoing' => 'ĐANG DIỄN RA',
      'upcoming' => 'SẮP DIỄN RA',
      final value when value != null && value.isNotEmpty => value.toUpperCase(),
      _ => 'HOÀN THÀNH',
    };
    final destination = item.destination?.trim();
    final subtitle = destination?.isNotEmpty == true
        ? '$destination • $range'
        : range;
    String? reviewCover;
    for (final url in item.mediaUrls) {
      if (!_isVideoUrl(url)) {
        reviewCover = url;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan về lịch trình',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 160,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (reviewCover != null)
                _CorsFriendlyImage(url: reviewCover)
              else
                NetImage(url: item.imageUrl),
              Container(color: Colors.black.withValues(alpha: 0.42)),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Cảm nhận của bạn',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 10),
        Center(child: _ReadOnlyStars(rating: item.rating ?? 0)),
        _ReviewTags(tags: item.tags),
        const SizedBox(height: 20),
        _ReviewContent(content: item.content),
        _ReviewMedia(mediaUrls: item.mediaUrls),
        if (item.placeReviews.isNotEmpty) ...[
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá địa điểm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${item.placeReviews.length} địa điểm',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...item.placeReviews.map(
            (place) =>
                ReviewedPlaceCard(place: place, itineraryTitle: item.title),
          ),
        ],
        _ReviewTimestamp(reviewedAt: item.reviewedAt),
      ],
    );
  }
}

class ReviewedPlaceCard extends StatelessWidget {
  final ReviewedPlaceItem place;
  final String itineraryTitle;
  const ReviewedPlaceCard({
    super.key,
    required this.place,
    required this.itineraryTitle,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReviewedPlaceScreen(place: place, itineraryTitle: itineraryTitle),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: NetImage(url: place.imageUrl, borderRadius: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: Color(0xFFFFA500),
                    ),
                    Text(' ${place.rating.toStringAsFixed(1)}'),
                    if (place.visitDate != null)
                      Text(
                        '  •  ${DateFormat('dd/MM/yyyy').format(place.visitDate!)}',
                      ),
                  ],
                ),
                if (place.content?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    place.content!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (place.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    place.tags.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PlaceReviewDetail extends StatelessWidget {
  final ReviewCatalogItem item;
  const _PlaceReviewDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final visit = item.visitDate == null
        ? 'Không rõ ngày ghé thăm'
        : 'Ghé thăm ${DateFormat('dd/MM/yyyy').format(item.visitDate!)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: NetImage(url: item.imageUrl, borderRadius: 12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$visit • ${item.itineraryTitle ?? 'Không rõ lịch trình'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Cảm nhận của bạn về địa điểm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),
        Center(child: _ReadOnlyStars(rating: item.rating ?? 0)),
        _ReviewTags(tags: item.tags),
        const SizedBox(height: 24),
        _ReviewContent(content: item.content),
        _ReviewMedia(mediaUrls: item.mediaUrls),
        _ReviewTimestamp(reviewedAt: item.reviewedAt),
      ],
    );
  }
}

class _ReadOnlyStars extends StatelessWidget {
  final double rating;
  const _ReadOnlyStars({required this.rating});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      5,
      (index) => Icon(
        index < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
        color: const Color(0xFFFFA500),
        size: 32,
      ),
    ),
  );
}

class _ReviewContent extends StatelessWidget {
  final String? content;
  const _ReviewContent({required this.content});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Nội dung đánh giá',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        ),
        child: Text(
          content?.trim().isNotEmpty == true
              ? content!
              : 'Đánh giá không có nội dung.',
          style: const TextStyle(height: 1.5, color: Color(0xFF4B5563)),
        ),
      ),
    ],
  );
}

class _ReviewTags extends StatelessWidget {
  final List<String> tags;
  const _ReviewTags({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blobLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CorsFriendlyImage extends StatelessWidget {
  final String url;
  final double borderRadius;
  final BoxFit fit;

  const _CorsFriendlyImage({
    required this.url,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      cacheWidth: 1080, // không giải mã full-res — tiết kiệm RAM
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: Color(0xFFE5E7EB),
              child: Center(child: CircularProgressIndicator()),
            ),
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE5E7EB),
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        ),
      ),
    ),
  );
}

class _ReviewMedia extends StatelessWidget {
  final List<String> mediaUrls;
  const _ReviewMedia({required this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    if (mediaUrls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình ảnh & video',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mediaUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => GestureDetector(
                onTap: () async {
                  final selectedUrl = mediaUrls[index];
                  if (_isVideoUrl(selectedUrl)) {
                    await launchUrl(
                      Uri.parse(selectedUrl),
                      mode: LaunchMode.externalApplication,
                      webOnlyWindowName: '_blank',
                    );
                    return;
                  }
                  final images = mediaUrls
                      .where((url) => !_isVideoUrl(url))
                      .toList();
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (_) => _ReviewGalleryDialog(
                      images: images,
                      initialIndex: images.indexOf(selectedUrl),
                    ),
                  );
                },
                child: SizedBox(
                  width: 110,
                  child: _isVideoUrl(mediaUrls[index])
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.play_circle_fill_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Video',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _CorsFriendlyImage(
                          url: mediaUrls[index],
                          borderRadius: 14,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTimestamp extends StatelessWidget {
  final DateTime? reviewedAt;
  const _ReviewTimestamp({required this.reviewedAt});

  @override
  Widget build(BuildContext context) {
    if (reviewedAt == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        'Đã đánh giá lúc ${DateFormat('HH:mm, dd/MM/yyyy').format(reviewedAt!.toLocal())}',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    );
  }
}

class _ReviewGalleryDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _ReviewGalleryDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_ReviewGalleryDialog> createState() => _ReviewGalleryDialogState();
}

class _ReviewGalleryDialogState extends State<_ReviewGalleryDialog> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: Colors.black,
    child: SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, index) => InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: _CorsFriendlyImage(
                  url: widget.images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
          Positioned(
            top: 16,
            right: 20,
            child: Text(
              '${_index + 1}/${widget.images.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class ReviewedPlaceScreen extends StatelessWidget {
  final ReviewedPlaceItem place;
  final String itineraryTitle;
  const ReviewedPlaceScreen({
    super.key,
    required this.place,
    required this.itineraryTitle,
  });

  @override
  Widget build(BuildContext context) {
    final visit = place.visitDate == null
        ? 'Không rõ ngày ghé thăm'
        : 'Ghé thăm ${DateFormat('dd/MM/yyyy').format(place.visitDate!)}';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Đánh giá địa điểm',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: NetImage(url: place.imageUrl, borderRadius: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$visit • $itineraryTitle',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Cảm nhận của bạn về địa điểm',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            Center(child: _ReadOnlyStars(rating: place.rating)),
            _ReviewTags(tags: place.tags),
            const SizedBox(height: 24),
            _ReviewContent(content: place.content),
            _ReviewMedia(mediaUrls: place.mediaUrls),
            _ReviewTimestamp(reviewedAt: place.reviewedAt),
          ],
        ),
      ),
    );
  }
}
