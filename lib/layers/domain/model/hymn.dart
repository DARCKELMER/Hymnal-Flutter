import 'package:equatable/equatable.dart';
import 'package:azlistview/azlistview.dart';
import 'package:hymnal_app/core/utils/string_utils.dart';

// ignore: must_be_immutable
class Hymn extends Equatable implements ISuspensionBean {
  final int number;
  final String title;
  final String content;
  final String normalizedTitle;
  final String normalizedContent;

  /// Autores (una línea "Letra: …" y otra "Música: …"), si los trae el
  /// himnario.
  final String? author;
  bool _isShowSuspension = false;

  Hymn({
    required this.number,
    required this.title,
    required this.content,
    required this.normalizedTitle,
    required this.normalizedContent,
    this.author,
  });

  @override
  String getSuspensionTag() {
    final norm = normalizedTitle.trim();
    if (norm.isEmpty) return '#';
    for (int i = 0; i < norm.length; i++) {
      final char = norm[i].toUpperCase();
      // Match any Unicode letter
      if (RegExp(r'\p{L}', unicode: true).hasMatch(char)) {
        return char;
      }
    }
    return '#';
  }

  String get tag => getSuspensionTag();

  @override
  bool get isShowSuspension => _isShowSuspension;

  @override
  set isShowSuspension(bool value) {
    _isShowSuspension = value;
  }

  factory Hymn.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String;
    final content = json['content'] as String;
    return Hymn(
      number: json['number'] as int,
      title: title,
      content: content,
      normalizedTitle: StringUtils.normalize(title),
      normalizedContent: StringUtils.normalize(content),
      author: (json['author'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'title': title,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [
        number,
        title,
        content,
        normalizedTitle,
        normalizedContent,
      ];
}
