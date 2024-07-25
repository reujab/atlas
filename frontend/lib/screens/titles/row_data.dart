import "package:json_annotation/json_annotation.dart";
import "package:frontend/title_data.dart";

part "row_data.g.dart";

@JsonSerializable()
class RowData {
  RowData({required this.name, required this.titles, this.titleIndex = 0});

  final String name;
  final List<TitleData> titles;

  @JsonKey(includeFromJson: false)
  int titleIndex;

  factory RowData.fromJson(Map<String, dynamic> json) =>
      _$RowDataFromJson(json);

  Map<String, dynamic> toJson() => _$RowDataToJson(this);
}
