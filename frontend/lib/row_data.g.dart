// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'row_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RowData _$RowDataFromJson(Map<String, dynamic> json) => RowData(
      name: json['name'] as String,
      titles: (json['titles'] as List<dynamic>)
          .map((e) => Title.fromJson(e as Map<String, dynamic>))
          .toList(),
      index: json['index'] as int? ?? 0,
    );

Map<String, dynamic> _$RowDataToJson(RowData instance) => <String, dynamic>{
      'name': instance.name,
      'titles': instance.titles,
      'index': instance.index,
    };
