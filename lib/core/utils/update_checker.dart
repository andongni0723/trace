import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'useful_extension.dart';
import 'utils_function.dart';

typedef GithubReleaseAsset = ({
  String name,
  int sizeBytes,
  String? downloadUrl,
});
typedef GithubReleaseInfo = ({
  String tag,
  String notes,
  GithubReleaseAsset? asset,
});

class GitHubUpdateChecker {
  GitHubUpdateChecker({required this.owner, required this.repo, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  static const String _apiBaseUrl = 'https://api.github.com';

  final String owner;
  final String repo;
  final Dio _dio;

  String get _latestReleasePath => '/repos/$owner/$repo/releases/latest';

  bool isUpdateAvailable({
    required String currentVersion,
    required String latestVersion,
  }) {
    final normalizedCurrent = currentVersion.trim().removePrefix('v');
    final normalizedLatest = latestVersion.trim().removePrefix('v');
    final result = compareVersion(normalizedCurrent, normalizedLatest) < 0;

    debugPrint(
      '[UpdateCheck] current=$normalizedCurrent latest=$normalizedLatest',
    );
    debugPrint('[UpdateCheck] available=$result');

    return result;
  }

  Future<GithubReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_latestReleasePath);

      if (response.statusCode != 200) {
        throw HttpException(
          'Get latest release failed with status ${response.statusCode}.',
        );
      }

      final data = response.data;
      if (data == null) {
        throw const FormatException('GitHub release response is empty.');
      }

      final tag = data['tag_name'] as String?;
      final notes = (data['body'] as String?) ?? '';
      final assets = (data['assets'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final primaryAsset = assets.isEmpty
          ? null
          : (
              name: (assets.first['name'] as String?) ?? 'unknown',
              sizeBytes: (assets.first['size'] as num?)?.toInt() ?? 0,
              downloadUrl: assets.first['browser_download_url'] as String?,
            );

      if (tag == null || tag.isEmpty) {
        throw const FormatException('Missing tag_name in GitHub response.');
      }

      debugPrint('[UpdateCheck] tag=$tag asset=${primaryAsset?.name}');

      return (tag: tag, notes: notes, asset: primaryAsset);
    } on DioException catch (error) {
      debugPrint('[UpdateCheck] dio error: ${error.message}');
      return null;
    } on SocketException {
      debugPrint('[UpdateCheck] no internet connection.');
      return null;
    } on TimeoutException {
      debugPrint('[UpdateCheck] request timeout.');
      return null;
    } on Exception catch (error) {
      debugPrint('[UpdateCheck] unexpected error: $error');
      return null;
    }
  }

  Future<bool> hasNewerRelease({String? currentVersion}) async {
    final resolvedCurrentVersion = currentVersion ?? await getAppVersion();
    final latestRelease = await fetchLatestRelease();
    if (latestRelease == null) return false;

    return isUpdateAvailable(
      currentVersion: resolvedCurrentVersion,
      latestVersion: latestRelease.tag,
    );
  }
}
