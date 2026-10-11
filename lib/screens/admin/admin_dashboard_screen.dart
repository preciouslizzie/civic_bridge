import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildNavItem(0, Icons.dashboard, 'Dashboard'),
                _buildNavItem(1, Icons.report_problem, 'Issues'),
                _buildNavItem(2, Icons.people, 'Users'),
                _buildNavItem(3, Icons.flag, 'Reports'),
                _buildNavItem(4, Icons.analytics, 'Analytics'),
                _buildNavItem(5, Icons.settings, 'Settings'),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? AppConstants.primaryColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: _selectedIndex == index ? AppConstants.primaryColor : Colors.black,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const AdminOverviewTab();
      case 1:
        return const AdminIssuesTab();
      case 2:
        return const AdminUsersTab();
      case 3:
        return const AdminReportsTab();
      case 4:
        return const AdminAnalyticsTab();
      case 5:
        return const AdminSettingsTab();
      default:
        return const AdminOverviewTab();
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/auth');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Overview Tab
class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatCard('Total Issues', '1,234', Icons.report_problem, Colors.blue),
              const SizedBox(width: 20),
              _buildStatCard('Active Users', '5,678', Icons.people, Colors.green),
              const SizedBox(width: 20),
              _buildStatCard('Flagged Content', '23', Icons.flag, Colors.orange),
              const SizedBox(width: 20),
              _buildStatCard('Resolved Issues', '890', Icons.check_circle, Colors.purple),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Card(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.report_problem, color: Colors.orange),
                    title: Text('New issue reported in Lagos'),
                    subtitle: Text('2 minutes ago'),
                  ),
                  ListTile(
                    leading: Icon(Icons.flag, color: Colors.red),
                    title: Text('Comment flagged for review'),
                    subtitle: Text('5 minutes ago'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Issue resolved in Abuja'),
                    subtitle: Text('10 minutes ago'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(title, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// Issues Tab
class AdminIssuesTab extends StatelessWidget {
  const AdminIssuesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Issue Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: 10),
                  FilterChip(
                    label: const Text('Flagged'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: 10),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: 10, // Replace with actual data
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.report_problem),
                    title: Text('Issue ${index + 1}'),
                    subtitle: const Text('Reported 2 hours ago'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: const Text('Pending'),
                          backgroundColor: Colors.orange.shade100,
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showIssueDetails(context, index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIssueDetails(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Issue ${index + 1} Details'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: Pending'),
            Text('Category: Infrastructure'),
            Text('Location: Lagos, Nigeria'),
            Text('Description: Pothole on main road causing accidents...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Update Status'),
          ),
        ],
      ),
    );
  }
}

// Users Tab
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: 20, // Replace with actual data
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text('User ${index + 1}'),
                    subtitle: Text('user${index + 1}@example.com'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: const Text('Active'),
                          backgroundColor: Colors.green.shade100,
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showUserActions(context, index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserActions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit User'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Suspend User'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Make Moderator'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// Reports Tab
class AdminReportsTab extends StatelessWidget {
  const AdminReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Reports',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: 5, // Replace with actual data
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.flag, color: Colors.red),
                    title: Text('Report ${index + 1}'),
                    subtitle: const Text('Inappropriate content - Spam'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Chip(
                          label: const Text('Pending'),
                          backgroundColor: Colors.orange.shade100,
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Review'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Analytics Tab
class AdminAnalyticsTab extends StatelessWidget {
  const AdminAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics & Insights',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Issues by Category'),
                        const SizedBox(height: 10),
                        // Placeholder for chart
                        Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(child: Text('Chart Placeholder')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('Issues by State'),
                        const SizedBox(height: 10),
                        // Placeholder for chart
                        Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(child: Text('Map Placeholder')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Settings Tab
class AdminSettingsTab extends StatelessWidget {
  const AdminSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moderation Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Auto-moderate content'),
                    subtitle: const Text('Automatically flag inappropriate content'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Require approval for new users'),
                    subtitle: const Text('New users need admin approval to post'),
                    value: false,
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Notification Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Email notifications'),
                    subtitle: const Text('Send email alerts for important events'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Push notifications'),
                    subtitle: const Text('Send push notifications to moderators'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}