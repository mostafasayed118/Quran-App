/// The pure version-policy model for the Force Update gate.
///
/// Everything here is deterministic and platform-free so it can be unit
/// tested without a device, a database or a network. The policy comes from a
/// remote document (see `docs/release-readiness-audit.md` for the hosting
/// contract); the gate only ever enforces what a *valid* policy says — an
/// unreadable or malformed policy fails open (the app starts normally).
///
/// Version comparison is on (major, minor, patch, build) — never on raw
/// strings, so `1.10.0` correctly sorts above `1.9.0`.
library;

/// A parsed `major.minor.patch(+build)` version, comparable field by field.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch, [this.build = 0]);

  final int major;
  final int minor;
  final int patch;

  /// The build number after `+`; 0 when absent.
  final int build;

  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)(\+(\d+))?$');

  /// Parses [raw]; returns null for anything unrecognized.
  ///
  /// Accepted shape: `major.minor.patch` with an optional `+build`. Leading
  /// whitespace is tolerated; anything else (prerelease tags, missing parts,
  /// non-numeric fields) is rejected — the caller treats null as "no valid
  /// policy", never as a version to enforce against.
  static AppVersion? parse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    final match = _pattern.firstMatch(trimmed);
    if (match == null) return null;
    final major = int.tryParse(match.group(1)!);
    final minor = int.tryParse(match.group(2)!);
    final patch = int.tryParse(match.group(3)!);
    final build = match.group(5) == null ? 0 : int.tryParse(match.group(5)!);
    if (major == null || minor == null || patch == null || build == null) {
      return null;
    }
    return AppVersion(major, minor, patch, build);
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    return build.compareTo(other.build);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      other.major == major &&
      other.minor == minor &&
      other.patch == patch &&
      other.build == build;

  @override
  int get hashCode => Object.hash(major, minor, patch, build);

  @override
  String toString() =>
      build == 0 ? '$major.$minor.$patch' : '$major.$minor.$patch+$build';
}

/// Why the installed build is in the state it is in.
enum VersionVerdict {
  /// At or above the recommended version — nothing to show.
  upToDate,

  /// Supported, but older than the recommended version — optional prompt.
  updateRecommended,

  /// Below the minimum supported version — mandatory update.
  updateRequired,
}

/// A validated update policy. Instances are created only from well-formed
/// input; construction never throws.
class VersionPolicy {
  const VersionPolicy({
    required this.minSupported,
    required this.latest,
    this.expiresAt,
  });

  /// No installation below this is allowed to keep running the app.
  final AppVersion minSupported;

  /// The newest version the publisher advertises; at-or-above means "current".
  final AppVersion latest;

  /// When this policy stops being authoritative, or null for "no expiry".
  ///
  /// The gate never enforces an expired policy: a stale document must not be
  /// able to wall an install after the publisher stopped maintaining it.
  final DateTime? expiresAt;

  /// Whether [now] is past [expiresAt] (false when there is no expiry).
  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !now.isBefore(expiry);
  }

  /// Reads and validates the wire JSON; returns null when unusable.
  ///
  /// Rules:
  /// - `min_supported` and `latest` are required and must parse;
  /// - `latest` must not sit below `min_supported` (a policy whose latest is
  ///   below its own minimum is malformed beyond repair — fail open);
  /// - `expires_at`, if present, must be an ISO-8601 instant; an unreadable
  ///   one is dropped (the policy then has no expiry).
  ///
  /// The document carries only what the gate enforces. The earlier
  /// `message_ar`/`message_en`/`store_url` fields were parsed, bounded and
  /// then never read by anything: the screen renders its ARB copy and the
  /// update button opens the hardcoded Play listing, so removing them removes
  /// dead surface (and a remote-URL field nobody should ever wire up).
  static VersionPolicy? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final minSupported = AppVersion.parse(json['min_supported'] as String?);
    final latest = AppVersion.parse(json['latest'] as String?);
    if (minSupported == null || latest == null) return null;
    if (latest.compareTo(minSupported) < 0) return null;
    return VersionPolicy(
      minSupported: minSupported,
      latest: latest,
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
    );
  }

  /// The verdict for [installed]; never null, never throws.
  VersionVerdict verdictFor(AppVersion installed) {
    if (installed.compareTo(minSupported) < 0) {
      return VersionVerdict.updateRequired;
    }
    if (installed.compareTo(latest) < 0) {
      return VersionVerdict.updateRecommended;
    }
    return VersionVerdict.upToDate;
  }
}
