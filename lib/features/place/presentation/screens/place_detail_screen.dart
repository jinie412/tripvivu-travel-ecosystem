import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_cubit.dart';
import 'package:travel_advisor_mobile/features/place/presentation/cubit/place_detail_state.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_contact_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_description_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_gallery_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_header.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_info_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/place_review_section.dart';
import 'package:travel_advisor_mobile/features/place/presentation/widgets/related_places_section.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  final bool showRelatedPlaces;

  const PlaceDetailScreen({
    super.key, 
    required this.placeId,
    this.showRelatedPlaces = true,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaceDetailCubit>().loadPlaceDetail(widget.placeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<PlaceDetailCubit, PlaceDetailState>(
        builder: (context, state) {
          if (state is PlaceDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is PlaceDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<PlaceDetailCubit>().loadPlaceDetail(widget.placeId),
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }
          
          if (state is PlaceDetailLoaded) {
            final place = state.placeDetail;
            return SingleChildScrollView(
              child: Column(
                children: [
                  // 1. Hero Image & Buttons
                  PlaceHeader(
                    imageUrl: place.images.isNotEmpty ? place.images[0] : 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800&q=80',
                    isFavorite: place.isFavorite,
                    onBack: () => Navigator.pop(context),
                    onFavorite: () {
                      context.read<PlaceDetailCubit>().toggleFavorite();
                      if (!place.isFavorite) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã lưu vào danh mục yêu thích'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  
                  // 2. Title, Rating, Location, Tags
                  PlaceInfoSection(
                    name: place.name,
                    rating: place.rating,
                    location: '${place.district}, ${place.city}',
                    tags: place.tags,
                  ),
                  
                  // 3. Image Gallery
                  PlaceGallerySection(images: place.images),
                  
                  // 4. Description
                  PlaceDescriptionSection(description: place.description),
                  
                  // 5. Contact Info (Hours, Phone, Address)
                  PlaceContactSection(
                    openingTime: place.openingHours,
                    closingTime: place.closingHours,
                    phone: place.phone,
                    address: place.address,
                  ),
                  
                  // 6. Reviews Section
                  PlaceReviewSection(
                    rating: place.rating,
                    totalReviews: place.totalReviews,
                    reviews: place.reviews,
                  ),
                  
                  // 7. Related Places - ONLY SHOW if showRelatedPlaces is true
                  if (widget.showRelatedPlaces)
                    RelatedPlacesSection(relatedPlaces: place.relatedPlaces),
                  
                  const SizedBox(height: 60),
                ],
              ),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}