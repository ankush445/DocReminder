enum DocumentStatus {
  valid,
  expiringSoon,
  expired;

  String get label {
    switch (this) {
      case DocumentStatus.valid:
        return 'Valid';
      case DocumentStatus.expiringSoon:
        return 'Expiring Soon';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }
}
