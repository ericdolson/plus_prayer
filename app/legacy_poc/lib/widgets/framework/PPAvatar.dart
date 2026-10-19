import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:plusprayer/models/name.dart';

final random = Random();
const double defaultRadius = 24;

class PPAvatar extends StatelessWidget {
  final String? _character;
  final Color? _color;
  final String? _imageUrl;
  final double _radius;

  const PPAvatar(
      {super.key, String? character, Color? color, double radius = defaultRadius, String? imageUrl})
      : _character = character,
        _color = color,
        _radius = radius,
        _imageUrl = imageUrl;

  PPAvatar.fromName({super.key, double radius = defaultRadius, required Name name})
      : _character = name.avatarLetter,
        _color = name.color,
        _radius = radius,
        _imageUrl = name.imageUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: _radius,
      backgroundColor: _color ?? Colors.primaries[(_character?.hashCode ?? 7) % Colors.primaries.length], //Theme.of(context).colorScheme.onSurface.withValues(alpha:.2),
      backgroundImage: _imageUrl == null ? null : CachedNetworkImageProvider(_imageUrl!),
      child: _imageUrl == null && _character != null
          ? Text(_character, style: TextStyle(fontSize: _radius, fontWeight: FontWeight.w500))
          : null,
    );
  }
}
