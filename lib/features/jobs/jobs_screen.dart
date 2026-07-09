import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'applications_controller.dart';
import 'browse_controller.dart';
import 'job_detail_screen.dart';
import 'jobs_state.dart';
import 'matched_controller.dart';
import 'widgets/job_card.dart';

/// Tabs: ranked matches, browse/search, and the candidate's own
/// applications. Each tab owns its own controller/state so switching tabs
/// doesn't re-trigger the others' network calls.
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jobs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Matched to you'),
              Tab(text: 'Browse'),
              Tab(text: 'My applications'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MatchedTab(),
            _BrowseTab(),
            _ApplicationsTab(),
          ],
        ),
      ),
    );
  }
}

void _openJob(BuildContext context, String jobId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobId)),
  );
}

class _MatchedTab extends ConsumerWidget {
  const _MatchedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchedControllerProvider);

    return switch (state) {
      MatchedLoading() => const Center(child: CircularProgressIndicator()),
      MatchedError(:final message) => _ErrorRetry(
          message: message,
          onRetry: () => ref.read(matchedControllerProvider.notifier).load(),
        ),
      // The API returns an empty list specifically when the candidate has
      // no verified skill claim yet (see JobsRepository.matched) — that is
      // not the same as "no jobs exist", so it gets its own explanation
      // rather than rendering a blank list.
      MatchedLoaded(:final jobs) when jobs.isEmpty => const _EmptyState(
          message: 'Job matches are based on your verified skills. '
              'Earn a badge to see roles that match you.',
        ),
      MatchedLoaded(:final jobs) => RefreshIndicator(
          onRefresh: () => ref.read(matchedControllerProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final matchedJob = jobs[index];
              return JobCard(
                job: matchedJob.job,
                onTap: () => _openJob(context, matchedJob.job.id),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${matchedJob.score}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.primary),
                    ),
                    SizedBox(
                      width: 60,
                      child: LinearProgressIndicator(value: matchedJob.score / 100),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    };
  }
}

class _BrowseTab extends ConsumerStatefulWidget {
  const _BrowseTab();

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  final _locationController = TextEditingController();
  bool _remoteOnly = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(browseControllerProvider.notifier).search(
          location: _locationController.text.trim(),
          remote: _remoteOnly ? true : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browseControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g. Bengaluru',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _search(),
              ),
              CheckboxListTile(
                value: _remoteOnly,
                onChanged: (value) => setState(() => _remoteOnly = value ?? false),
                title: const Text('Remote only'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              FilledButton(
                onPressed: state is BrowseLoading ? null : _search,
                child: Text(state is BrowseLoading ? 'Searching…' : 'Search'),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (state) {
            BrowseLoading() => const Center(child: CircularProgressIndicator()),
            BrowseError(:final message) => _ErrorRetry(message: message, onRetry: _search),
            BrowseLoaded(:final jobs) when jobs.isEmpty =>
              const _EmptyState(message: 'No jobs match those filters yet.'),
            BrowseLoaded(:final jobs, :final total) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: jobs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '$total job${total == 1 ? '' : 's'} found',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  final job = jobs[index - 1];
                  return JobCard(job: job, onTap: () => _openJob(context, job.id));
                },
              ),
          },
        ),
      ],
    );
  }
}

class _ApplicationsTab extends ConsumerWidget {
  const _ApplicationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applicationsControllerProvider);

    return switch (state) {
      ApplicationsLoading() => const Center(child: CircularProgressIndicator()),
      ApplicationsError(:final message) => _ErrorRetry(
          message: message,
          onRetry: () => ref.read(applicationsControllerProvider.notifier).load(),
        ),
      ApplicationsLoaded(:final applications) when applications.isEmpty =>
        const _EmptyState(message: "You haven't applied to any jobs yet."),
      ApplicationsLoaded(:final applications) => RefreshIndicator(
          onRefresh: () => ref.read(applicationsControllerProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => _openJob(context, application.jobId),
                  title: Text(application.jobTitle),
                  subtitle: Text(
                    '${application.orgName}\nApplied ${_formatDate(application.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: Chip(label: Text(application.status)),
                ),
              );
            },
          ),
        ),
    };
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
