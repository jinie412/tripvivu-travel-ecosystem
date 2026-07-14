import 'package:travel_advisor_mobile/features/itinerary/domain/entities/incurred_cost_entity.dart';

class IncurredCostModel {
  final String id;
  final CostType type;
  final String? placeId;
  final String? placeName;
  final String note;
  final double amount;
  final List<String> chargedTo;
  final String createdBy;
  final DateTime createdAt;
  final String? updatedBy;

  const IncurredCostModel({
    required this.id,
    this.type = CostType.other,
    this.placeId,
    this.placeName,
    required this.note,
    required this.amount,
    this.chargedTo = const [],
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
  });

  factory IncurredCostModel.fromJson(Map<String, dynamic> json) {
    return IncurredCostModel(
      id: (json['id'] ?? '').toString(),
      type: CostType.fromApi((json['type'] ?? json['costType'])?.toString()),
      placeId: json['place_id']?.toString() ?? json['placeId']?.toString(),
      placeName: json['place_name']?.toString() ?? json['placeName']?.toString(),
      note: (json['note'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      chargedTo:
          ((json['charged_to'] ?? json['chargedTo']) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdBy:
          (json['created_by'] ?? json['createdBy'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(
            (json['created_at'] ?? json['createdAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      updatedBy: json['updated_by']?.toString() ?? json['updatedBy']?.toString(),
    );
  }

  IncurredCostEntity toEntity() => IncurredCostEntity(
    id: id,
    type: type,
    placeId: placeId,
    placeName: placeName,
    note: note,
    amount: amount,
    chargedTo: chargedTo,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedBy: updatedBy,
  );
}

class EligiblePlaceModel {
  final String id;
  final String name;
  final String address;
  final double currentEffectivePrice;

  const EligiblePlaceModel({
    required this.id,
    required this.name,
    this.address = '',
    this.currentEffectivePrice = 0,
  });

  factory EligiblePlaceModel.fromJson(Map<String, dynamic> json) {
    return EligiblePlaceModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      currentEffectivePrice:
          (json['currentEffectivePrice'] ??
                  json['current_effective_price'] ??
                  0)
              .toDouble(),
    );
  }

  EligiblePlaceEntity toEntity() => EligiblePlaceEntity(
    id: id,
    name: name,
    address: address,
    currentEffectivePrice: currentEffectivePrice,
  );
}

class MemberCostTotalModel {
  final String userId;
  final String fullName;
  final bool isOwner;
  final double total;
  final double childrenShare;

  const MemberCostTotalModel({
    required this.userId,
    required this.fullName,
    required this.isOwner,
    required this.total,
    this.childrenShare = 0,
  });

  factory MemberCostTotalModel.fromJson(Map<String, dynamic> json) {
    return MemberCostTotalModel(
      userId: (json['userId'] ?? json['user_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['full_name'] ?? '').toString(),
      isOwner: json['isOwner'] == true || json['is_owner'] == true,
      total: (json['total'] ?? 0).toDouble(),
      childrenShare:
          (json['childrenShare'] ?? json['children_share'] ?? 0).toDouble(),
    );
  }

  MemberCostTotalEntity toEntity() => MemberCostTotalEntity(
    userId: userId,
    fullName: fullName,
    isOwner: isOwner,
    total: total,
    childrenShare: childrenShare,
  );
}

class CostBreakdownModel {
  final List<MemberCostTotalModel> memberTotals;
  final double totalCost;
  final double basePlanCost;
  final double incurredTotal;
  final double childrenShare;
  final double spentSoFar;
  final double estimatedCostForGroup;
  final double estimatedCostPerAdult;
  final double estimatedCostPerChild;
  final double payableLimitForGroup;
  final double payableLimitPerAdult;
  final double payableLimitPerChild;
  final double reserveCost;
  final double roundedGroupTotal;
  final double contingencyCost;
  final double roundedCostPerAdult;
  final double roundedCostPerChild;
  final double placeCostPerAdult;
  final double placeCostPerChild;
  final double hotelCostPerAdult;
  final double hotelCostPerChild;
  final double transportPerAdult;
  final double childPriceRatio;
  final double transportRatePerKmMotorbike;
  final double transportRatePerKmCar;
  final int adultCount;
  final int childCount;

  const CostBreakdownModel({
    this.memberTotals = const [],
    this.totalCost = 0,
    this.basePlanCost = 0,
    this.incurredTotal = 0,
    this.childrenShare = 0,
    this.spentSoFar = 0,
    this.estimatedCostForGroup = 0,
    this.estimatedCostPerAdult = 0,
    this.estimatedCostPerChild = 0,
    this.payableLimitForGroup = 0,
    this.payableLimitPerAdult = 0,
    this.payableLimitPerChild = 0,
    this.reserveCost = 0,
    this.roundedGroupTotal = 0,
    this.contingencyCost = 0,
    this.roundedCostPerAdult = 0,
    this.roundedCostPerChild = 0,
    this.placeCostPerAdult = 0,
    this.placeCostPerChild = 0,
    this.hotelCostPerAdult = 0,
    this.hotelCostPerChild = 0,
    this.transportPerAdult = 0,
    this.childPriceRatio = 0.7,
    this.transportRatePerKmMotorbike = 0,
    this.transportRatePerKmCar = 0,
    this.adultCount = 1,
    this.childCount = 0,
  });

  factory CostBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CostBreakdownModel(
      memberTotals:
          ((json['memberTotals'] ?? json['member_totals']) as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MemberCostTotalModel.fromJson)
              .toList() ??
          const [],
      totalCost: (json['totalCost'] ?? json['total_cost'] ?? 0).toDouble(),
      basePlanCost:
          (json['basePlanCost'] ?? json['base_plan_cost'] ?? 0).toDouble(),
      incurredTotal:
          (json['incurredTotal'] ?? json['incurred_total'] ?? 0).toDouble(),
      childrenShare:
          (json['childrenShare'] ?? json['children_share'] ?? 0).toDouble(),
      spentSoFar:
          (json['spentSoFar'] ?? json['spent_so_far'] ?? 0).toDouble(),
      estimatedCostForGroup:
          (json['estimatedCostForGroup'] ??
                  json['estimated_cost_for_group'] ??
                  0)
              .toDouble(),
      estimatedCostPerAdult:
          (json['estimatedCostPerAdult'] ??
                  json['estimated_cost_per_adult'] ??
                  0)
              .toDouble(),
      estimatedCostPerChild:
          (json['estimatedCostPerChild'] ??
                  json['estimated_cost_per_child'] ??
                  0)
              .toDouble(),
      payableLimitForGroup:
          (json['payableLimitForGroup'] ??
                  json['payable_limit_for_group'] ??
                  0)
              .toDouble(),
      payableLimitPerAdult:
          (json['payableLimitPerAdult'] ??
                  json['payable_limit_per_adult'] ??
                  0)
              .toDouble(),
      payableLimitPerChild:
          (json['payableLimitPerChild'] ??
                  json['payable_limit_per_child'] ??
                  0)
              .toDouble(),
      reserveCost: (json['reserveCost'] ?? json['reserve_cost'] ?? 0)
          .toDouble(),
      roundedGroupTotal:
          (json['roundedGroupTotal'] ?? json['rounded_group_total'] ?? 0)
              .toDouble(),
      contingencyCost:
          (json['contingencyCost'] ?? json['contingency_cost'] ?? 0)
              .toDouble(),
      roundedCostPerAdult:
          (json['roundedCostPerAdult'] ?? json['rounded_cost_per_adult'] ?? 0)
              .toDouble(),
      roundedCostPerChild:
          (json['roundedCostPerChild'] ?? json['rounded_cost_per_child'] ?? 0)
              .toDouble(),
      placeCostPerAdult:
          (json['placeCostPerAdult'] ?? json['place_cost_per_adult'] ?? 0)
              .toDouble(),
      placeCostPerChild:
          (json['placeCostPerChild'] ?? json['place_cost_per_child'] ?? 0)
              .toDouble(),
      hotelCostPerAdult:
          (json['hotelCostPerAdult'] ?? json['hotel_cost_per_adult'] ?? 0)
              .toDouble(),
      hotelCostPerChild:
          (json['hotelCostPerChild'] ?? json['hotel_cost_per_child'] ?? 0)
              .toDouble(),
      transportPerAdult:
          (json['transportPerAdult'] ?? json['transport_per_adult'] ?? 0)
              .toDouble(),
      childPriceRatio:
          (json['childPriceRatio'] ?? json['child_price_ratio'] ?? 0.7)
              .toDouble(),
      transportRatePerKmMotorbike:
          (((json['transportRatePerKm'] ?? json['transport_rate_per_km'])
                      as Map<String, dynamic>?)?['motorbike'] ??
                  0)
              .toDouble(),
      transportRatePerKmCar:
          (((json['transportRatePerKm'] ?? json['transport_rate_per_km'])
                      as Map<String, dynamic>?)?['car'] ??
                  0)
              .toDouble(),
      adultCount:
          (json['adultCount'] ?? json['adult_count'] as num?)?.toInt() ?? 1,
      childCount:
          (json['childCount'] ?? json['child_count'] as num?)?.toInt() ?? 0,
    );
  }

  CostBreakdownEntity toEntity() => CostBreakdownEntity(
    memberTotals: memberTotals.map((e) => e.toEntity()).toList(),
    totalCost: totalCost,
    basePlanCost: basePlanCost,
    incurredTotal: incurredTotal,
    childrenShare: childrenShare,
    spentSoFar: spentSoFar,
    estimatedCostForGroup: estimatedCostForGroup,
    estimatedCostPerAdult: estimatedCostPerAdult,
    estimatedCostPerChild: estimatedCostPerChild,
    payableLimitForGroup: payableLimitForGroup,
    payableLimitPerAdult: payableLimitPerAdult,
    payableLimitPerChild: payableLimitPerChild,
    reserveCost: reserveCost,
    roundedGroupTotal: roundedGroupTotal,
    contingencyCost: contingencyCost,
    roundedCostPerAdult: roundedCostPerAdult,
    roundedCostPerChild: roundedCostPerChild,
    placeCostPerAdult: placeCostPerAdult,
    placeCostPerChild: placeCostPerChild,
    hotelCostPerAdult: hotelCostPerAdult,
    hotelCostPerChild: hotelCostPerChild,
    transportPerAdult: transportPerAdult,
    childPriceRatio: childPriceRatio,
    transportRatePerKmMotorbike: transportRatePerKmMotorbike,
    transportRatePerKmCar: transportRatePerKmCar,
    adultCount: adultCount,
    childCount: childCount,
  );
}
