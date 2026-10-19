import 'package:animated_flip_counter/animated_flip_counter.dart';
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
import 'package:plusprayer/widgets/names/name_prayed_status.dart';
import 'package:plusprayer/widgets/names/name_prayed_status_v2.dart';

class HomeCommunity2 extends HookWidget {
  final double bottomPadding;
  final bool filterUnprayed;

  const HomeCommunity2({super.key, this.bottomPadding = 0, this.filterUnprayed = false});

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
              SliverAppBar(
                expandedHeight: 70.0,
                collapsedHeight: kToolbarHeight,
                stretch: true,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: [
                    StretchMode.zoomBackground,
                    // StretchMode.blurBackground,
                  ],
                  // background: Stack(fit: StackFit.expand, children: [
                  //   Image(
                  //     image: dynamicAppImgProvider('community_prayer_list_images/231.png'),
                  //     fit: BoxFit.cover,
                  //   ),
                  //   // const SerratedEdge(),
                  //   const SerratedEdge(isBottom: true),
                  // ]),
                ),
              ),
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
                    // const SizedBox(height: 16),/
                    // Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    //   Padding(
                    //       padding: EdgeInsetsGeometry.only(bottom: 8),
                    //       child: Icon(PlusPrayer.plus_dots,
                    //           size: 16, color: Theme.of(context).colorScheme.onSurface)),
                    FancyText(
                      'Prayer List #${currentMetrics.currentRollId}',
                      style:
                          TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.onSurface),
                      textAlign: TextAlign.center,
                      // color: Colors.amber.shade100,
                    ),
                    // ]),
                    SizedBox(height: 6),
                    NameScreenPrayedStatus2(prayerCount: 1),
                    // Divider(indent: 50, endIndent: 50, radius: BorderRadius.circular(10), color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .1), height: 30,),
                    // SizedBox(height: 20),
                    TempDivider(),
                    Text('32,646 people and causes\nbeing prayed for today',
                        style: TextStyle(fontSize: 15), textAlign: TextAlign.center),
                    // SizedBox(height: 20),
                    TempDivider(),

                    Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 8, children: [
                      AnimatedFlipCounter(
                        thousandSeparator: ',',
                        textStyle: TextStyle(
                          /*fontFamily: 'Roca',*/
                          // color: Colors.amber.shade100,
                            letterSpacing: 0,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        duration: 200.ms,
                        value: 1359,
                        suffix: ' prayers offered',
                      ),
                      // Text('prayers offered',
                      //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      //     textAlign: TextAlign.center),
                    ]),

                    Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 8, children: [
                      AnimatedFlipCounter(
                        thousandSeparator: ',',
                        textStyle: TextStyle(
                          /*fontFamily: 'Roca',*/
                          // color: Colors.amber.shade100,
                            letterSpacing: 0,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        duration: 200.ms,
                        value: 1359,
                        suffix: ' people in prayer now',
                      ),
                      // Text('prayers offered',
                      //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      //     textAlign: TextAlign.center),
                    ]),

                    // TempDivider(),
                    // SizedBox(height: 60),
                    Divider(
                      indent: 8,
                      endIndent: 8,
                      radius: BorderRadius.circular(10),
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .15),
                      height: 100,
                    ),

                    // SurfaceCard(
                    //     outlined: true,
                    //     // elevated: true,
                    //     filled: true,
                    //     child: Padding(
                    //       padding: EdgeInsets.all(16),
                    //       child: Text('Some text'),
                    //     )),
                    // Padding(
                    //     padding: EdgeInsetsGeometry.symmetric(horizontal: 20),
                    //     child: Container(
                    //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    //       decoration: BoxDecoration(
                    //         color: Theme.of(context).colorScheme.surfaceTint,
                    //         borderRadius: BorderRadius.only(
                    //             bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                    //       ),
                    //       child: Text('Some text'),
                    //     ))
                    SurfaceCard.tinted(
                        // outlined: true,
                        //   elevated: true,
                        child: Row(children: [
                      Text('You have 3 intentions on this list'),
                      Expanded(child: SizedBox.shrink()),
                      Icon(Icons.chevron_right_rounded),
                    ]))

                    // Row(
                    //     mainAxisAlignment: MainAxisAlignment.start,
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text('#', style: TextStyle(fontSize: 34)),
                    //       Text('${currentMetrics.currentRollId}', style: TextStyle(fontSize: 48)),
                    //       Text('#', style: TextStyle(fontSize: 34, color: Colors.transparent)),
                    //     ]),
                    // const SizedBox(height: 16),
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

class TempDividerItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(PlusPrayer.plus_dots,
        size: 6, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .25));
  }
}

class TempDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 2, children: [
        TempDividerItem(),
        TempDividerItem(),
        TempDividerItem(),
        // TempDividerItem(),
      ])),
    );
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
      decoration: BoxDecoration(
          gradient: LinearGradient(
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
