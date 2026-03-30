import 'package:flutter/material.dart';

import '../widgets/database_summary_view.dart';

class DatabasePage extends StatelessWidget {
  const DatabasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: const DatabaseSummaryView());
  }
}
