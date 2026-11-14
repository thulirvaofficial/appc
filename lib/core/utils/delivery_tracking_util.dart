import 'dart:math' as math;

/// Centralized Delivery Tracking & Telemetry Utility
/// Single source of truth for distance and ETA calculations across all customer screens
class DeliveryTrackingUtil {
  /// Calculate Haversine distance in kilometers between two GPS coordinates
  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // math.pi / 180
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  /// Calculate ETA in minutes based on distance (average urban delivery pace ~4.5 min/km)
  static int calculateEtaMinutes(double distanceKm) {
    if (distanceKm <= 0) return 3;
    return (distanceKm * 4.5).clamp(3.0, 45.0).round();
  }

  /// Formats ETA and distance string consistently (e.g. "ETA: 12 min (2.8 km)" or "Calculating ETA")
  static String formatEta(double? partnerLat, double? partnerLng, double? destLat, double? destLng) {
    if (partnerLat == null || partnerLng == null || destLat == null || destLng == null) {
      return 'Calculating ETA';
    }
    final dist = calculateDistanceKm(partnerLat, partnerLng, destLat, destLng);
    final eta = calculateEtaMinutes(dist);
    return 'ETA: $eta min (${dist.toStringAsFixed(1)} km)';
  }

  /// Formats concise ETA string for banners (e.g. "ETA: 12 min")
  static String formatEtaShort(double? partnerLat, double? partnerLng, double? destLat, double? destLng) {
    if (partnerLat == null || partnerLng == null || destLat == null || destLng == null) {
      return 'Calculating ETA';
    }
    final dist = calculateDistanceKm(partnerLat, partnerLng, destLat, destLng);
    final eta = calculateEtaMinutes(dist);
    return 'ETA: $eta min (${dist.toStringAsFixed(1)} km)';
  }
}
