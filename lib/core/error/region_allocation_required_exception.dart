/// One geographic region detected by the planner's macro-clustering step.
class RegionInfo {
  final String regionName;
  final List<String> placeIds;
  final List<String> placeNames;
  final int maxDays;
  // Backend's ready-to-submit default: central region first (up to its own
  // maxDays), then any leftover trip days borrowed from the nearest
  // remaining regions in order — the wizard prefills steppers with this so
  // the user can just tap "Tạo lịch trình" without manually distributing days.
  final int suggestedDays;
  final int totalVisitMinutes;
  final int travelMinutesFromCentral;
  final bool isRemote;

  RegionInfo({
    required this.regionName,
    required this.placeIds,
    required this.placeNames,
    required this.maxDays,
    required this.suggestedDays,
    required this.totalVisitMinutes,
    required this.travelMinutesFromCentral,
    required this.isRemote,
  });

  factory RegionInfo.fromJson(Map<String, dynamic> json) {
    return RegionInfo(
      regionName: (json['regionName'] ?? '').toString(),
      placeIds:
          (json['placeIds'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      placeNames:
          (json['placeNames'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      maxDays: (json['maxDays'] as num?)?.toInt() ?? 1,
      suggestedDays: (json['suggestedDays'] as num?)?.toInt() ?? 0,
      totalVisitMinutes: (json['totalVisitMinutes'] as num?)?.toInt() ?? 0,
      travelMinutesFromCentral:
          (json['travelMinutesFromCentral'] as num?)?.toInt() ?? 0,
      isRemote: json['isRemote'] == true,
    );
  }
}

/// Thrown when POST /itinerary/plan returns 422 REGION_ALLOCATION_REQUIRED —
/// always returned on the first attempt (before `regionAllocations` is
/// submitted): the planner ran macro-clustering and wants the traveller to
/// decide how many days to spend in each detected region before it commits
/// to a schedule.
class RegionAllocationRequiredException implements Exception {
  final String message;
  final List<RegionInfo> regions;
  final int numDays;
  final int estimatedTotalDays;
  // > 0 when even every detected region's maxDays combined can't cover
  // numDays — show ONE consolidated notice instead of per-region warnings.
  final int shortfallDays;

  RegionAllocationRequiredException({
    required this.message,
    required this.regions,
    required this.numDays,
    required this.estimatedTotalDays,
    required this.shortfallDays,
  });

  factory RegionAllocationRequiredException.fromJson(
    Map<String, dynamic> json,
  ) {
    final regions =
        (json['regions'] as List?)
            ?.map((e) => RegionInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <RegionInfo>[];
    return RegionAllocationRequiredException(
      message:
          json['message']?.toString() ??
          'Hệ thống đã nhận diện được các vùng địa lý trong lịch trình của bạn.',
      regions: regions,
      numDays: (json['numDays'] as num?)?.toInt() ?? 0,
      estimatedTotalDays: (json['estimatedTotalDays'] as num?)?.toInt() ?? 0,
      shortfallDays: (json['shortfallDays'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => message;
}
