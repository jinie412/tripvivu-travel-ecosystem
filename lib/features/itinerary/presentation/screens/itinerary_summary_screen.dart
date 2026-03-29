import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/itinerary_cubit.dart';
import '../cubit/itinerary_state.dart';
import '../widgets/itinerary_stat_card.dart';
import '../widgets/short_itinerary_item.dart';
import '../../domain/entities/itinerary_detail_entity.dart';
import '../../../../core/widgets/section_header.dart';
import 'itinerary_detail_screen.dart';

class ItinerarySummaryScreen extends StatelessWidget {
  final String itineraryId;

  const ItinerarySummaryScreen({super.key, required this.itineraryId});

  @override
  Widget build(BuildContext context) {
    return const _ItinerarySummaryView();
  }
}

class _ItinerarySummaryView extends StatelessWidget {
  const _ItinerarySummaryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tóm tắt lịch trình',
          style: TextStyle(
            color: Color(0xFF1C1C1E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: BlocBuilder<ItineraryCubit, ItineraryState>(
        builder: (context, state) {
          if (state is ItineraryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ItineraryError) {
            return Center(child: Text(state.message));
          }
          if (state is ItineraryLoaded && state.selectedItinerary != null) {
            final itin = state.selectedItinerary!;
            final dateFormatter = DateFormat('dd ThMM');
            final dateRange = '${dateFormatter.format(itin.startDate)} - ${dateFormatter.format(itin.endDate)}, ${itin.startDate.year}';

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        // Destination Card
                        _buildDestinationCard(itin.destination, dateRange),
                        
                        const SizedBox(height: 32),
                        Text(
                          'Tổng quan chuyến đi',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatsGrid(itin),
                        
                        if (itin.visitedRestaurants.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const SectionHeader(title: 'Trải nghiệm ẩm thực'),
                          const SizedBox(height: 8),
                          _buildCulinarySection(itin),
                        ],
                        
                        const SizedBox(height: 32),
                        const SectionHeader(
                          title: 'Lịch trình rút gọn',
                        ),
                        const SizedBox(height: 8),
                        ...itin.days.take(3).map((day) => ShortItineraryItem(
                          dayNumber: day.dayNumber,
                          date: DateFormat('dd ThMM').format(day.date),
                          title: day.activities.isNotEmpty ? day.activities.first.title : 'Đang lên kế hoạch',
                          icon: _getIconForDay(day.dayNumber),
                          onTap: () => _navigateToDetail(context, itin),
                        )),
                        
                        const SizedBox(height: 32),
                        _buildBudgetSection(itin),
                        
                        const SizedBox(height: 32),
                        _buildNotesSection(itin.notes),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // Sticky Action Button at the bottom
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _navigateToDetail(context, itin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Xem chi tiết lịch trình',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, dynamic itin) {
    final cubit = context.read<ItineraryCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ItineraryDetailScreen(
            itineraryId: itin.id,
            initialDetail: itin,
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationCard(String destination, String dateRange) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'ĐIỂM ĐẾN',
                          style: TextStyle(
                            fontSize: 10, 
                            color: Colors.white.withValues(alpha: 0.7), 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: 13, 
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.airplanemode_active, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ColorFilter.mode(Colors.white.withValues(alpha: 0.2), BlendMode.overlay),
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.map_outlined, size: 18),
                        label: Text('Xem bản đồ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1E3A8A),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic itin) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        ItineraryStatCard(
          label: 'Thời gian',
          value: '${itin.durationDays} Ngày',
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF3B82F6),
        ),
        ItineraryStatCard(
          label: 'Hoạt động',
          value: '${itin.activitiesCount} điểm',
          icon: Icons.explore_outlined,
          iconColor: const Color(0xFFF59E0B),
        ),
        ItineraryStatCard(
          label: 'Chỗ ở',
          value: '${itin.hotelsCount} khách sạn',
          icon: Icons.hotel_outlined,
          iconColor: const Color(0xFFEC4899),
        ),
        ItineraryStatCard(
          label: 'Di chuyển',
          value: '${itin.transportTurns} lượt',
          icon: Icons.directions_bus_outlined,
          iconColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildBudgetSection(dynamic itin) {
    final progress = itin.spentBudget / itin.estimatedBudget;
    final formatter = NumberFormat('#,###', 'vi_VN');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ngân sách',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Bình ổn',
                  style: TextStyle(fontSize: 10, color: Color(0xFF166534), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đã chi', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text('${formatter.format(itin.spentBudget)} đ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Dự kiến', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Text('${formatter.format(itin.estimatedBudget)} đ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(List<dynamic> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.notes, size: 20, color: Color(0xFF4B5563)),
            SizedBox(width: 8),
            Text(
              'Ghi chú quan trọng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...notes.map((note) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.circle, size: 6, color: Color(0xFF3B82F6)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(note.toString(), style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCulinarySection(ItineraryDetailEntity itin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: itin.visitedRestaurants.map((food) {
          return _CulinaryExpandableItem(food: food);
        }).toList(),
      ),
    );
  }

  IconData _getIconForDay(int day) {
    switch (day) {
      case 1: return Icons.flight_land_outlined;
      case 2: return Icons.camera_alt_outlined;
      case 3: return Icons.restaurant_outlined;
      case 4: return Icons.shopping_bag_outlined;
      default: return Icons.explore_outlined;
    }
  }
}

class _CulinaryExpandableItem extends StatefulWidget {
  final VisitedRestaurant food;
  const _CulinaryExpandableItem({required this.food});

  @override
  State<_CulinaryExpandableItem> createState() => _CulinaryExpandableItemState();
}

class _CulinaryExpandableItemState extends State<_CulinaryExpandableItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.restaurant_menu_outlined, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUÁN ĐÃ GHÉ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.food.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
                  color: const Color(0xFFCBD5E1),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(76, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...widget.food.dishes.map((dish) {
                  final formatter = NumberFormat('#,###', 'vi_VN');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Image.network(
                              widget.food.imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.restaurant_outlined,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dish.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${formatter.format(dish.price)} đ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'SL: ${dish.quantity}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        // Separator logic
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ],
    );
  }
}
