import "package:json_annotation/json_annotation.dart";
import "title.dart";

part "row_data.g.dart";

@JsonSerializable()
class RowData {
  RowData({required this.name, required this.titles, this.index = 0});

  final String name;
  final List<Title> titles;

  int index;

  factory RowData.fromJson(Map<String, dynamic> json) =>
      _$RowDataFromJson(json);
}
