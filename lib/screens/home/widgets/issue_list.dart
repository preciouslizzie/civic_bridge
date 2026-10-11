import 'package:flutter/material.dart';
import '../../../models/issue.dart';
import '../../../utils/constants.dart';
import '../../../widgets/issue_card.dart';

class IssueList extends StatelessWidget {
  final List<Issue> issues;
  final bool isLoading;
  final VoidCallback onRefresh;
  final String? emptyMessage;

  const IssueList({
    super.key,
    required this.issues,
    required this.isLoading,
    required this.onRefresh,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: issues.isEmpty && !isLoading
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              itemCount: issues.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == issues.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.paddingLarge),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return IssueCard(issue: issues[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            emptyMessage ?? 'No issues found',
            style: AppConstants.headline2.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Be the first to report an issue in your community',
            style: AppConstants.bodyText2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}