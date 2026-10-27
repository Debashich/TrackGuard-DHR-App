enum HazardType {
  slip,
  rockfall,
  blockedDrain,
  damagedWall,
  trackDefect,
  vegetation,
  other;

  static HazardType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'slip':
      case 'landslip':
      case 'mudslide':
        return HazardType.slip;
      case 'rockfall':
      case 'rock_fall':
      case 'falling_rock':
        return HazardType.rockfall;
      case 'blockeddrain':
      case 'blocked_drain':
      case 'drain_blocked':
      case 'drain':
        return HazardType.blockedDrain;
      case 'damagedwall':
      case 'damaged_wall':
      case 'retaining_wall':
      case 'wall_damage':
        return HazardType.damagedWall;
      case 'trackdefect':
      case 'track_defect':
      case 'defect':
      case 'gauge_spread':
        return HazardType.trackDefect;
      case 'vegetation':
      case 'overgrowth':
        return HazardType.vegetation;
      default:
        return HazardType.other;
    }
  }

  String toJson() => name;
}
