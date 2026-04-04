import 'package:flutter_riverpod/flutter_riverpod.dart';

final messagesHomeSelectionModeProvider =
    NotifierProvider<MessagesHomeSelectionModeNotifier, bool>(
      MessagesHomeSelectionModeNotifier.new,
    );

class MessagesHomeSelectionModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSelectionMode(bool value) {
    state = value;
  }
}
