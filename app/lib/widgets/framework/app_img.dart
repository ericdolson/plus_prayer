import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

const cloudFrontUrl = 'https://d3g6ilbyi1765n.cloudfront.net/';

enum AppImageType {
  // Prefetch images
  addNameDark(file: 'add_name_dark_v1.png', shouldPrefetch: true, themeMode: ThemeMode.dark),
  addNameLight(file: 'add_name_light_v1.png', shouldPrefetch: true, themeMode: ThemeMode.light),
  hands(file: 'hands_v1.png', shouldPrefetch: true),
  loginBg(file: 'login_bg_v1.png', shouldPrefetch: true),
  unprayedEmptyDark(
      file: 'unprayed_empty_dark_v1.png', shouldPrefetch: true, themeMode: ThemeMode.dark),
  unprayedEmptyLight(
      file: 'unprayed_empty_light_v1.png', shouldPrefetch: true, themeMode: ThemeMode.light);

  // Do not prefetch images

  final String file;
  final bool shouldPrefetch;
  final ThemeMode? themeMode; // null means either dark or light

  String get url => '$cloudFrontUrl$file';

  const AppImageType({
    required this.file,
    this.shouldPrefetch = false,
    this.themeMode,
  });
}

Future<void> loadImportantImages(BuildContext context, ThemeMode themeMode) async {
  final start = DateTime.now();
  Iterable<Future<dynamic>> items = AppImageType.values
      .where((appImageType) =>
          appImageType.shouldPrefetch &&
          (appImageType.themeMode == null || appImageType.themeMode == themeMode))
      .map((appImageType) async {
    await precacheImage(CachedNetworkImageProvider(appImageType.url), context);
  });

  print('waiting to prefetch images');
  await Future.wait(items);

  final end = DateTime.now();
  final duration = end.difference(start);
  print('Prefetching images took: ${duration.inMilliseconds} ms');
}

// Community Prayer List provider
CachedNetworkImageProvider cplImgProvider(int prayerListId) =>
    dynamicAppImgProvider('community_prayer_list_images/$prayerListId.png');

CachedNetworkImageProvider dynamicAppImgProvider(String urlPath) =>
    CachedNetworkImageProvider('$cloudFrontUrl$urlPath');

CachedNetworkImageProvider remoteAppImgProvider(AppImageType appImageType) =>
    CachedNetworkImageProvider(appImageType.url);
