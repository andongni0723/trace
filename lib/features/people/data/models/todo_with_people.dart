import '../../../../core/database/database.dart';

class TodoWithPeople {
  const TodoWithPeople({required this.todo, required this.relatedPeople});

  final Todo todo;
  final List<PeopleData> relatedPeople;
}
