import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:plusprayer/hooks/use_currentMetrics.dart';
import 'package:plusprayer/hooks/use_in_prayer.dart';
import 'package:plusprayer/presentation/logo.dart';
import 'package:plusprayer/presentation/plus_prayer_icons.dart';
import 'package:plusprayer/presentation/text.dart';
import 'package:plusprayer/presentation/themes.dart';
import 'package:plusprayer/widgets/framework/app_img.dart';
import 'package:plusprayer/widgets/framework/surface_card.dart';

class HomeCommunity extends HookWidget {
  final double bottomPadding;
  final bool filterUnprayed;

  const HomeCommunity({super.key, this.bottomPadding = 0, this.filterUnprayed = false});

  @override
  Widget build(BuildContext context) {
    final currentMetrics = useCurrentMetrics();

    // return Container(
    //   padding: EdgeInsets.only(bottom: bottomPadding),
    //   child: Center(child: Text('community')),
    // ).animate().fadeIn();

    // print(MediaQuery.of(context).padding.top);

    return Padding(
        padding: EdgeInsets.only(bottom: 0),
        child: Stack(children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // SliverAppBar(
              //   expandedHeight: 160.0,
              //   collapsedHeight: kToolbarHeight,
              //   stretch: true,
              //   floating: false,
              //   pinned: true,
              //   backgroundColor: Colors.transparent,
              //   elevation: 0,
              //   flexibleSpace: FlexibleSpaceBar(
              //     stretchModes: [
              //       StretchMode.zoomBackground,
              //       // StretchMode.blurBackground,
              //     ],
              //     background: Stack(fit: StackFit.expand, children: [
              //       Image(
              //         image: dynamicAppImgProvider('community_prayer_list_images/231.png'),
              //         fit: BoxFit.cover,
              //       ),
              //       // const SerratedEdge(),
              //       const SerratedEdge(isBottom: true),
              //     ]),
              //   ),
              // ),
              // SliverPersistentHeader(
              //   pinned: true,
              //   delegate: _MyHeaderDelegate(),
              // ),
              SliverPadding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // SurfaceCard.tinted(
                    //     child: Column(
                    //   crossAxisAlignment: CrossAxisAlignment.start,
                    //   children: [
                    //     Text(
                    //       'COMMUNITY PRAYER LIST',
                    //       style: TextStyle(
                    //           fontSize: 12,
                    //           fontWeight: FontWeight.w900,
                    //           color: Theme.of(context).colorScheme.onSurface),
                    //     ),
                    //     const SizedBox(height: 8),
                    //     Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    //       PPPPIcon.outlined(
                    //         size: 44,
                    //         iconColor: Theme.of(context).extension<PPCustomTheme>()!.prayerListColor,
                    //         iconScale: .85,
                    //         color: Theme.of(context).scaffoldBackgroundColor,
                    //         outlineColor: Theme.of(context)
                    //             .extension<PPCustomTheme>()!
                    //             .prayerListColor
                    //             .withValues(alpha:.3),
                    //         outlineScale: .02,
                    //       ),
                    //       const SizedBox(width: 8),
                    //       Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    //         const SizedBox(height: 4),
                    //         FancyText('#${currentMetrics.currentRollId}', style: TextStyle(fontSize: 30))
                    //       ])
                    //     ]),
                    //   ],
                    // )),
                    // const SizedBox(height: 16),
                    // PPPPIcon.outlined(
                    //   size: 112,
                    //   iconColor: Theme.of(context).extension<PPCustomTheme>()!.prayerListColor,
                    //   iconScale: .8,
                    //   color: Theme.of(context).colorScheme.surfaceTint,
                    //   outlineColor: Theme.of(context)
                    //       .extension<PPCustomTheme>()!
                    //       .prayerListColor
                    //       .withValues(alpha: .3),
                    //   outlineScale: .02,
                    // ),
                    // const SizedBox(height: 16),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('#', style: TextStyle(fontSize: 34)),
                          Text('${currentMetrics.currentRollId}', style: TextStyle(fontSize: 48)),
                          Text('#', style: TextStyle(fontSize: 34, color: Colors.transparent)),
                        ]),
                    const SizedBox(height: 16),
                    // SurfaceCard.tinted(
                    //     padding: EdgeInsets.zero,
                    //     child: Container(
                    //         height: 120,
                    //         child: Stack(children: [
                    //           Positioned(
                    //               left: -20,
                    //               top: -5,
                    //               bottom: 0,
                    //               child: Row(children: [
                    //                 Icon(PlusPrayer.plus_dots_list,
                    //                     size: 130,
                    //                     color: Theme.of(context)
                    //                         .extension<PPCustomTheme>()!
                    //                         .prayerListColor
                    //                         .withValues(alpha: 1)),
                    //               ])),
                    //           Center(
                    //               child: Container(
                    //                   padding: EdgeInsets.all(16),
                    //                   child: Column(
                    //                     crossAxisAlignment: CrossAxisAlignment.center,
                    //                     children: [
                    //                       Text('COMMUNITY PRAYER LIST',
                    //                           style: TextStyle(
                    //                               fontSize: 12,
                    //                               fontWeight: FontWeight.w900,
                    //                               color: Theme.of(context).colorScheme.onSurface)),
                    //                       const SizedBox(height: 8),
                    //                       FancyText('#${currentMetrics.currentRollId}',
                    //                           style: TextStyle(fontSize: 30))
                    //                     ],
                    //                   )))
                    //         ]))),
                    // SizedBox(height: 16),
                    // Container(
                    //     clipBehavior: Clip.hardEdge,
                    //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
                    //     child: Image(
                    //         image: dynamicAppImgProvider(
                    //             'community_prayer_list_images/231.png'))),
                  ]),
                ),
              ),
            ],
          ),
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   height: 8,
          //   child: CustomPaint(
          //     painter: SerratedEdgePainter(
          //       color: Theme.of(context).scaffoldBackgroundColor,
          //       triangleHeight: 8.0,
          //       triangleWidth: 12.0,
          //     ),
          //     size: Size.infinite,
          //   ),
          // ),
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   height: 8,
          //   child: CustomPaint(
          //     painter: SerratedEdgePainter(
          //       color: Theme.of(context).scaffoldBackgroundColor,
          //       triangleHeight: 8.0,
          //       triangleWidth: 12.0,
          //     ),
          //     size: Size.infinite,
          //   ),
          // ),
        ])).animate().fadeIn(duration: 100.ms);
  }
}

class SerratedEdgePainter extends CustomPainter {
  final Color color;
  final double triangleHeight;
  final double triangleWidth;

  SerratedEdgePainter({
    required this.color,
    required this.triangleHeight,
    required this.triangleWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start at the top-left corner
    path.moveTo(0, 0);

    // Draw the serrated edge with triangles pointing down (mirrored)
    double x = 0;
    while (x < size.width) {
      // Move to the bottom point of the triangle (pointing down)
      path.lineTo(x + triangleWidth / 2, triangleHeight);
      // Move to the top of the next triangle
      path.lineTo(x + triangleWidth, 0);
      x += triangleWidth;
    }

    // Complete the rectangle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SerratedEdgePainter oldDelegate) {
    return color != oldDelegate.color ||
        triangleHeight != oldDelegate.triangleHeight ||
        triangleWidth != oldDelegate.triangleWidth;
  }
}

class SerratedEdge extends StatelessWidget {
  final bool isBottom;

  const SerratedEdge({super.key, this.isBottom = false});

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: isBottom ? 0 : null,
        top: isBottom ? null : 0,
        left: 0,
        right: 0,
        height: 5,
        child: Transform.flip(
          flipY: !isBottom,
          child: Stack(children: [
            Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: .2), Colors.transparent]))),
            CustomPaint(
              painter: SerratedEdgePainter(
                color: Theme.of(context).scaffoldBackgroundColor,
                triangleHeight: 5.0,
                triangleWidth: 22.0,
              ),
              size: Size.infinite,
            )
          ]),
        ));
  }
}

class _MyHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 10;
  @override
  double get maxExtent => 10;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).scaffoldBackgroundColor,
          Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0),
        ],
      )),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
