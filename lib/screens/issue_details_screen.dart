import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/issue.dart';
import '../../models/comment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issues_provider.dart';
import '../../utils/constants.dart';

class IssueDetailsScreen extends StatefulWidget {
  final Issue issue;

  const IssueDetailsScreen({super.key, required this.issue});

  @override
  State<IssueDetailsScreen> createState() => _IssueDetailsScreenState();
}

class _IssueDetailsScreenState extends State<IssueDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isAnonymous = false;

  @override
  void initState() {
    super.initState();
    // Load issue details and comments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssuesProvider>().selectIssue(widget.issue.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareIssue,
          ),
          IconButton(
            icon: const Icon(Icons.report),
            onPressed: _reportIssue,
          ),
        ],
      ),
      body: Consumer<IssuesProvider>(
        builder: (context, issuesProvider, child) {
          final issue = issuesProvider.selectedIssue ?? widget.issue;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIssueHeader(issue),
                      const SizedBox(height: AppConstants.paddingMedium),
                      _buildIssueContent(issue),
                      if (issue.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: AppConstants.paddingMedium),
                        _buildImageGallery(issue),
                      ],
                      const SizedBox(height: AppConstants.paddingMedium),
                      _buildStatusHistory(issue),
                      const SizedBox(height: AppConstants.paddingLarge),
                      _buildCommentsSection(issuesProvider),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIssueHeader(Issue issue) {
    return Row(
      children: [
        _buildStatusChip(issue.status),
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

  Widget _buildStatusChip(IssueStatus status) {
    Color color;
    switch (status) {
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
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIssueContent(Issue issue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          issue.title,
          style: AppConstants.headline2,
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              '${issue.lga}, ${issue.state}',
              style: AppConstants.bodyText2.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Icon(
              Icons.category,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              _getCategoryDisplayName(issue.category),
              style: AppConstants.bodyText2.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Text(
          issue.description,
          style: AppConstants.bodyText1,
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        Row(
          children: [
            _buildVoteButton(issue),
            const SizedBox(width: AppConstants.paddingMedium),
            Text(
              '${issue.upvotes} upvotes',
              style: AppConstants.bodyText2,
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Text(
              '${issue.commentCount} comments',
              style: AppConstants.bodyText2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageGallery(Issue issue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: issue.imageUrls.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: AppConstants.paddingSmall),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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
        ),
      ],
    );
  }

  Widget _buildStatusHistory(Issue issue) {
    if (issue.statusHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status History',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        ...issue.statusHistory.map((update) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
              child: Row(
                children: [
                  _buildStatusChip(update.status),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      'Updated by ${update.updatedBy}',
                      style: AppConstants.bodyText2,
                    ),
                  ),
                  Text(
                    _formatTimeAgo(update.timestamp),
                    style: AppConstants.bodyText2.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCommentsSection(IssuesProvider issuesProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingMedium),
        if (issuesProvider.comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Text(
                'No comments yet. Be the first to comment!',
                style: AppConstants.bodyText2,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...issuesProvider.comments.map((comment) => _buildComment(comment)),
      ],
    );
  }

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              (comment.userName ?? 'U')[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.isAnonymous ? 'Anonymous' : (comment.userName ?? 'User'),
                      style: AppConstants.bodyText2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      _formatTimeAgo(comment.createdAt),
                      style: AppConstants.bodyText2.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: AppConstants.bodyText2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userProfile;

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        color: Colors.grey.shade100,
        child: const Text('Please complete your profile to comment'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() => _isAnonymous = value ?? false);
            },
          ),
          const Text('Anonymous'),
          const SizedBox(width: AppConstants.paddingSmall),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton(Issue issue) {
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
                color: hasVoted ? AppConstants.primaryColor : null,
              ),
              onPressed: () => issuesProvider.voteOnIssue(issue.id, userId),
            );
          },
        );
      },
    );
  }

  void _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final issuesProvider = context.read<IssuesProvider>();
    final user = authProvider.userProfile;
    final userId = authProvider.firebaseUser?.uid;

    if (user == null || userId == null) return;

    final success = await issuesProvider.addComment(
      issueId: widget.issue.id,
      userId: userId,
      userName: _isAnonymous ? null : user.name,
      isAnonymous: _isAnonymous,
      content: content,
    );

    if (success) {
      _commentController.clear();
      setState(() => _isAnonymous = false);
    }
  }

  void _shareIssue() {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _reportIssue() {
    // Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report functionality coming soon')),
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

  String _getCategoryDisplayName(IssueCategory category) {
    switch (category) {
      case IssueCategory.roads:
        return 'Roads';
      case IssueCategory.electricity:
        return 'Electricity';
      case IssueCategory.water:
        return 'Water';
      case IssueCategory.security:
        return 'Security';
      case IssueCategory.health:
        return 'Health';
      case IssueCategory.education:
        return 'Education';
      case IssueCategory.environment:
        return 'Environment';
      case IssueCategory.transportation:
        return 'Transportation';
      case IssueCategory.sanitation:
        return 'Sanitation';
      case IssueCategory.other:
        return 'Other';
    }
  }
}