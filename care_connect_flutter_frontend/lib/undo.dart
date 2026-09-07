import 'package:flutter/foundation.dart';

/// A single reversible state change made somewhere in the app.
class UndoableAction {
  final String id;
  final String description;
  final DateTime timestamp;
  final VoidCallback undo;

  UndoableAction({
    required this.id,
    required this.description,
    required this.undo,
  }) : timestamp = DateTime.now();
}

/// App-wide log of reversible actions, shown by the floating undo button.
class ActionHistory extends ChangeNotifier {
  final List<UndoableAction> _actions = [];

  /// Most recent action first.
  List<UndoableAction> get actions => List.unmodifiable(_actions.reversed);

  void add(UndoableAction action) {
    _actions.add(action);
    notifyListeners();
  }

  void undo(String id) {
    final index = _actions.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final action = _actions.removeAt(index);
    action.undo();
    notifyListeners();
  }

  void clear() {
    _actions.clear();
    notifyListeners();
  }
}
