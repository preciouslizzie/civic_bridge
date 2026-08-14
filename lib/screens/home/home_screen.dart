import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/issues_provider.dart';
import '../../utils/constants.dart';
import 'widgets/issue_list.dart';
import 'widgets/create_issue_fab.dart';
import 'widgets/filter_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load issues when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssuesProvider>().loadIssues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicVoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: _showProfile,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildFeedTab(),
          _buildMyIssuesTab(),
          _buildNotificationsTab(),
        ],
      ),
      floatingActionButton: const CreateIssueFAB(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Issues',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Updates',
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return Consumer<IssuesProvider>(
      builder: (context, issuesProvider, child) {
        if (issuesProvider.isLoading && issuesProvider.issues.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (issuesProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppConstants.errorColor),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Failed to load issues',
                  style: AppConstants.headline2,
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Text(
                  issuesProvider.error!,
                  style: AppConstants.bodyText2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                ElevatedButton(
                  onPressed: issuesProvider.loadIssues,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return IssueList(
          issues: issuesProvider.issues,
          isLoading: issuesProvider.isLoading,
          onRefresh: issuesProvider.loadIssues,
        );
      },
    );
  }

  Widget _buildMyIssuesTab() {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.firebaseUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text('Please log in to view your issues'),
      );
    }

    return Consumer<IssuesProvider>(
      builder: (context, issuesProvider, child) {
        final myIssues = issuesProvider.issues
            .where((issue) => issue.userId == userId)
            .toList();

        if (issuesProvider.isLoading && myIssues.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return IssueList(
          issues: myIssues,
          isLoading: issuesProvider.isLoading,
          onRefresh: issuesProvider.loadIssues,
          emptyMessage: 'You haven\'t reported any issues yet',
        );
      },
    );
  }

  Widget _buildNotificationsTab() {
    return const Center(
      child: Text('Notifications coming soon'),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _showProfile() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userProfile;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user != null) ...[
              Text('Name: ${user.name}'),
              Text('Phone: ${user.phoneNumber}'),
              Text('Location: ${user.lga}, ${user.state}'),
              Text('Anonymous: ${user.anonymousPosting ? 'Yes' : 'No'}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}