import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/issues_provider.dart';
import '../../../models/issue.dart';
import '../../../utils/constants.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedState;
  String? _selectedLga;
  IssueCategory? _selectedCategory;
  IssueStatus? _selectedStatus;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  void initState() {
    super.initState();
    final issuesProvider = context.read<IssuesProvider>();
    _selectedState = issuesProvider.selectedState;
    _selectedLga = issuesProvider.selectedLga;
    _selectedCategory = issuesProvider.selectedCategory;
    _selectedStatus = issuesProvider.selectedStatus;
    _sortBy = issuesProvider.sortBy;
    _sortDescending = issuesProvider.sortDescending;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter Issues',
                style: AppConstants.headline2,
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          _buildStateFilter(),
          const SizedBox(height: AppConstants.paddingMedium),

          _buildCategoryFilter(),
          const SizedBox(height: AppConstants.paddingMedium),

          _buildStatusFilter(),
          const SizedBox(height: AppConstants.paddingMedium),

          _buildSortOptions(),
          const SizedBox(height: AppConstants.paddingLarge),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<String>(
          value: _selectedState,
          decoration: const InputDecoration(
            hintText: 'All states',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All states'),
            ),
            ...AppConstants.nigerianStates.map((state) {
              return DropdownMenuItem(
                value: state,
                child: Text(state),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              if (value != _selectedState) {
                _selectedLga = null; // Reset LGA when state changes
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<IssueCategory>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            hintText: 'All categories',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All categories'),
            ),
            ...IssueCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(_getCategoryDisplayName(category)),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedCategory = value);
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        DropdownButtonFormField<IssueStatus>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            hintText: 'All statuses',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('All statuses'),
            ),
            ...IssueStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(_getStatusDisplayName(status)),
              );
            }),
          ],
          onChanged: (value) {
            setState(() => _selectedStatus = value);
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: AppConstants.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.paddingSmall),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'createdAt',
                    child: Text('Date Created'),
                  ),
                  DropdownMenuItem(
                    value: 'upvotes',
                    child: Text('Most Supported'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                  }
                },
              ),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            IconButton(
              icon: Icon(
                _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
              ),
              onPressed: () {
                setState(() => _sortDescending = !_sortDescending);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedState = null;
      _selectedLga = null;
      _selectedCategory = null;
      _selectedStatus = null;
      _sortBy = 'createdAt';
      _sortDescending = true;
    });
  }

  void _applyFilters() {
    final issuesProvider = context.read<IssuesProvider>();
    issuesProvider.setFilters(
      state: _selectedState,
      lga: _selectedLga,
      category: _selectedCategory,
      status: _selectedStatus,
    );
    issuesProvider.setSorting(_sortBy, _sortDescending);
    Navigator.of(context).pop();
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

  String _getStatusDisplayName(IssueStatus status) {
    switch (status) {
      case IssueStatus.reported:
        return 'Reported';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.resolved:
        return 'Resolved';
      case IssueStatus.archived:
        return 'Archived';
    }
  }
}