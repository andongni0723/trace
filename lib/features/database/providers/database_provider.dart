import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database.dart';
import '../../people/providers/people_database_providers.dart';

final allTodosProvider = StreamProvider<List<Todo>>((ref) {
  return ref.watch(todosDaoProvider).watchAllTodos();
});
