import 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'dart:io';



class CustomAppStore extends UpgraderStore {
  final String appStoreId;
  final String countryCode;

  CustomAppStore({required this.appStoreId, this.countryCode = 'IN'});

  @override
  Future<UpgraderVersionInfo> getVersionInfo({
    required UpgraderState state,
    required Version installedVersion,
    required String? country,
    required String? language,
  }) async {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = state.debugLogging;
    iTunes.client = state.client;
    iTunes.clientHeaders = state.clientHeaders;

    final response = await iTunes.lookupById(appStoreId, country: country ?? countryCode);
    if (response == null) {
      return UpgraderVersionInfo(installedVersion: installedVersion);
    }

    final version = iTunes.version(response);
    Version? appStoreVersion;
    if (version != null) {
      try {
        appStoreVersion = Version.parse(version);
      } catch (_) {}
    }

    return UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreVersion: appStoreVersion,
      appStoreListingURL: iTunes.trackViewUrl(response),
      releaseNotes: iTunes.releaseNotes(response),
      minAppVersion: iTunes.minAppVersion(response),
    );
  }
}

class AppUpdateService {
  /// Returns a configured [Upgrader] instance supporting smart update policies with explicit iOS App Store ID & country lookup
  static Upgrader getUpgrader() {
    return Upgrader(
      debugLogging: true, // Enable debug logging to inspect lookup responses in console
      storeController: UpgraderStoreController(
        oniOS: () => CustomAppStore(appStoreId: '6770619179', countryCode: 'IN'),
      ),
      durationUntilAlertAgain: const Duration(hours: 24),
      messages: UpgraderMessages(code: 'en'),
    );
  }

  /// Manually open store for updates
  static Future<void> openStore() async {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/in/app/payfx-global/id6770619179'
        : 'https://play.google.com/store/apps/details?id=com.payfx.payfxglobalapp';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
