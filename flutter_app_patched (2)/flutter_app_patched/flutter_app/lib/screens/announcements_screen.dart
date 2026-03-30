import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../models/material_model.dart';
import '../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().fetchAnnouncements();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final user = context.read<AuthProvider>().user;
    final canPost = user?.canPostAnnouncement ?? false;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '🔴 Urgent'),
            Tab(text: '⭐ Important'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<AnnouncementProvider>().fetchAnnouncements(),
          ),
        ],
      ),
      floatingActionButton: canPost
          ? FloatingActionButton.extended(
              onPressed: () => _showAnnouncementDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Post'),
            )
          : null,
      body: Column(
        children: [
          if (provider.errorMessage != null)
            ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearMessages),
          if (provider.successMessage != null)
            SuccessBanner(message: provider.successMessage!, onDismiss: provider.clearMessages),
          Expanded(
            child: provider.loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _AnnouncementList(
                        announcements: provider.announcements,
                        canEdit: canPost,
                        currentUserId: user?.uid ?? '',
                        onEdit: (a) => _showAnnouncementDialog(context, existing: a),
                        onDelete: (id) => _confirmDelete(context, id),
                        emptyMessage: 'No announcements yet',
                      ),
                      _AnnouncementList(
                        announcements: provider.announcements
                            .where((a) => a.priority == 'high')
                            .toList(),
                        canEdit: canPost,
                        currentUserId: user?.uid ?? '',
                        onEdit: (a) => _showAnnouncementDialog(context, existing: a),
                        onDelete: (id) => _confirmDelete(context, id),
                        emptyMessage: 'No urgent announcements',
                      ),
                      _AnnouncementList(
                        announcements: provider.announcements
                            .where((a) => a.isPinned)
                            .toList(),
                        canEdit: canPost,
                        currentUserId: user?.uid ?? '',
                        onEdit: (a) => _showAnnouncementDialog(context, existing: a),
                        onDelete: (id) => _confirmDelete(context, id),
                        emptyMessage: 'No pinned announcements',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context, {Announcement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AnnouncementProvider>(),
        child: _AnnouncementForm(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(context);
              context.read<AnnouncementProvider>().deleteAnnouncement(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  final List<Announcement> announcements;
  final bool canEdit;
  final String currentUserId;
  final void Function(Announcement) onEdit;
  final void Function(String) onDelete;
  final String emptyMessage;

  const _AnnouncementList({
    required this.announcements,
    required this.canEdit,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (announcements.isEmpty) {
      return EmptyState(
        icon: Icons.campaign_outlined,
        title: emptyMessage,
        subtitle: canEdit ? 'Tap + to post an announcement' : null,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<AnnouncementProvider>().fetchAnnouncements(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _AnnouncementCard(
          announcement: announcements[i],
          canEdit: canEdit,
          currentUserId: currentUserId,
          onEdit: () => onEdit(announcements[i]),
          onDelete: () => onDelete(announcements[i].id),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool canEdit;
  final String currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.canEdit,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = announcement.priorityColor;
    final isUrgent = announcement.priority == 'high';
    final isMedium = announcement.priority == 'medium';

    String formattedDate = '';
    try {
      final dt = DateTime.parse(announcement.createdAt);
      formattedDate = DateFormat('MMM d, y • h:mm a').format(dt.toLocal());
    } catch (_) {
      formattedDate = announcement.createdAt;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? priorityColor.withOpacity(0.4)
              : cs.outline.withOpacity(0.4),
          width: isUrgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: priorityColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUrgent) ...[
                        const Text('🚨', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        isUrgent ? 'URGENT' : isMedium ? 'IMPORTANT' : 'INFO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: priorityColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (announcement.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📌', style: TextStyle(fontSize: 10)),
                        const SizedBox(width: 3),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (canEdit)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        size: 18, color: cs.onSurfaceVariant),
                    onSelected: (v) {
                      if (v == 'edit') onEdit();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  announcement.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      announcement.createdByName,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (announcement.department != 'ALL')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          announcement.department,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementForm extends StatefulWidget {
  final Announcement? existing;
  const _AnnouncementForm({this.existing});

  @override
  State<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<_AnnouncementForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'low';
  String _department = 'ALL';

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _descCtrl.text = widget.existing!.description;
      _priority = widget.existing!.priority;
      _department = widget.existing!.department;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isEdit ? 'Edit Announcement' : 'New Announcement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                    DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                    DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _department,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All')),
                    DropdownMenuItem(value: 'CS', child: Text('CS')),
                    DropdownMenuItem(value: 'IT', child: Text('IT')),
                    DropdownMenuItem(value: 'ECE', child: Text('ECE')),
                    DropdownMenuItem(value: 'MECH', child: Text('MECH')),
                    DropdownMenuItem(value: 'CIVIL', child: Text('CIVIL')),
                  ],
                  onChanged: (v) => setState(() => _department = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: provider.posting
                  ? null
                  : () async {
                      if (_titleCtrl.text.trim().isEmpty) return;
                      bool ok;
                      if (isEdit) {
                        ok = await provider.updateAnnouncement(
                          widget.existing!.id,
                          title: _titleCtrl.text.trim(),
                          description: _descCtrl.text.trim(),
                          priority: _priority,
                          department: _department,
                        );
                      } else {
                        ok = await provider.createAnnouncement(
                          title: _titleCtrl.text.trim(),
                          description: _descCtrl.text.trim(),
                          priority: _priority,
                          department: _department,
                        );
                      }
                      if (ok && context.mounted) Navigator.pop(context);
                    },
              child: provider.posting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Update' : 'Post Announcement'),
            ),
          ),
        ],
      ),
    );
  }
}