import 'package:flutter/material.dart';
import '../../create_issue_screen.dart';

class CreateIssueFAB extends StatelessWidget {
  const CreateIssueFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToCreateIssue(context),
      child: const Icon(Icons.add),
    );
  }

  void _navigateToCreateIssue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateIssueScreen(),
      ),
    );
  }
}