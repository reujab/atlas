// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'title.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Title _$TitleFromJson(Map<String, dynamic> json) => Title(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      genres:
          (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
      overview: json['overview'] as String,
      released: json['released'] == null
          ? null
          : DateTime.parse(json['released'] as String),
      trailer: json['trailer'] as String?,
      rating: json['rating'] as String?,
      poster: json['poster'] as String,
    );

Map<String, dynamic> _$TitleToJson(Title instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'genres': instance.genres,
      'overview': instance.overview,
      'released': instance.released?.toIso8601String(),
      'trailer': instance.trailer,
      'rating': instance.rating,
      'poster': instance.poster,
    };
