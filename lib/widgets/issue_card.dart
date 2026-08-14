import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/issue.dart';
import '../../providers/issues_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../screens/issue_details_screen.dart';

class IssueCard extends StatelessWidget {
  final Issue issue;

  const IssueCard({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: InkWell(
        onTap: () => _navigateToDetails(context),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                issue.title,
                style: AppConstants.bodyText1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                issue.description,
                style: AppConstants.bodyText2,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (issue.imageUrls.isNotEmpty) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                _buildImageGallery(),
              ],
              const SizedBox(height: AppConstants.paddingMedium),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildStatusChip(),
        const Spacer(),
        Text(
          _formatTimeAgo(issue.createdAt),
          style: AppConstants.bodyText2.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    Color color;
    switch (issue.status) {
      case IssueStatus.reported:
        color = AppConstants.warningColor;
        break;
      case IssueStatus.inProgress:
        color = AppConstants.primaryColor;
        break;
      case IssueStatus.resolved:
        color = AppConstants.successColor;
        break;
      case IssueStatus.archived:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        issue.status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: issue.imageUrls.length,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: AppConstants.paddingSmall),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              child: CachedNetworkImage(
                imageUrl: issue.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${issue.lga}, ${issue.state}',
            style: AppConstants.bodyText2.copyWith(
              color: Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        _buildVoteButton(context),
        const SizedBox(width: AppConstants.paddingSmall),
        Text(
          '${issue.upvotes}',
          style: AppConstants.bodyText2,
        ),
        const SizedBox(width: AppConstants.paddingMedium),
        Icon(
          Icons.comment,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '${issue.commentCount}',
          style: AppConstants.bodyText2,
        ),
      ],
    );
  }

  Widget _buildVoteButton(BuildContext context) {
    return Consumer2<AuthProvider, IssuesProvider>(
      builder: (context, authProvider, issuesProvider, child) {
        final userId = authProvider.firebaseUser?.uid;
        if (userId == null) return const SizedBox.shrink();

        return FutureBuilder<bool>(
          future: issuesProvider.hasUserVoted(issue.id, userId),
          builder: (context, snapshot) {
            final hasVoted = snapshot.data ?? false;

            return IconButton(
              icon: Icon(
                hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 20,
                color: hasVoted ? AppConstants.primaryColor : Colors.grey.shade600,
              ),
              onPressed: () => issuesProvider.voteOnIssue(issue.id, userId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            );
          },
        );
      },
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IssueDetailsScreen(issue: issue),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}