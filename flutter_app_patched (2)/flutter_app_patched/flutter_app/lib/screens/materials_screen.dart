import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/material_provider.dart';
import '../models/material_model.dart';
import '../widgets/common_widgets.dart';
import 'package:intl/intl.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final types = ['all', 'notes', 'qp'];
        context.read<MaterialProvider>().setType(types[_tabController.index]);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MaterialProvider>().fetchMaterials();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaterialProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.layers_rounded), text: 'All'),
            Tab(icon: Icon(Icons.menu_book_rounded), text: 'Notes'),
            Tab(icon: Icon(Icons.quiz_rounded), text: 'PYQ'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => _showUploadDialog(context),
            tooltip: 'Upload',
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.errorMessage != null)
            ErrorBanner(message: provider.errorMessage!, onDismiss: provider.clearMessages),
          if (provider.successMessage != null)
            SuccessBanner(message: provider.successMessage!, onDismiss: provider.clearMessages),
          if (provider.uploading)
            LinearProgressIndicator(color: cs.primary),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search notes, QP, subjects…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (provider.subjects.length > 1)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: provider.subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final subject = provider.subjects[i];
                        final selected = provider.selectedSubject == subject;
                        return ChoiceChip(
                          label: Text(subject),
                          selected: selected,
                          onSelected: (_) => provider.setSubject(subject),
                          selectedColor: cs.primary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),

                if (provider.semesters.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: provider.semesters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final sem = provider.semesters[i];
                        final selected = provider.selectedSemester == sem;
                        return ChoiceChip(
                          label: Text(sem == 'All' ? '📅 All Sems' : 'Sem $sem'),
                          selected: selected,
                          onSelected: (_) => provider.setSemester(sem),
                          selectedColor: cs.tertiary,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),

          Expanded(
            child: provider.loading
                ? Center(child: CircularProgressIndicator(color: cs.primary))
                : _MaterialList(
                    provider: provider,
                    searchQuery: _searchQuery,
                  ),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MaterialProvider>(),
        child: const _UploadSheet(),
      ),
    );
  }
}

class _MaterialList extends StatelessWidget {
  final MaterialProvider provider;
  final String searchQuery;

  const _MaterialList({required this.provider, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final items = provider.materials.where((m) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return m.title.toLowerCase().contains(q) ||
          m.subject.toLowerCase().contains(q) ||
          m.uploaderName.toLowerCase().contains(q);
    }).toList();

    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No materials found',
        subtitle: 'Try adjusting filters or upload new materials',
      );
    }

    final trending = [...items]
      ..sort((a, b) => b.downloads.compareTo(a.downloads));
    final top3 = trending.take(3).map((m) => m.id).toSet();

    return RefreshIndicator(
      onRefresh: () => context.read<MaterialProvider>().fetchMaterials(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _MaterialCard(
          item: items[i],
          isTrending: top3.contains(items[i].id),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialItem item;
  final bool isTrending;
  const _MaterialCard({required this.item, required this.isTrending});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isQP = item.type == 'qp';

    String formattedDate = '';
    try {
      final dt = DateTime.parse(item.createdAt);
      formattedDate = DateFormat('MMM d, y').format(dt.toLocal());
    } catch (_) {
      formattedDate = item.createdAt;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (item.fileUrl.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening: ${item.title}')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isQP
                      ? const Color(0xFFFEF3C7)
                      : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isQP ? Icons.quiz_rounded : Icons.description_rounded,
                  color: isQP
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF4F46E5),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isTrending)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🔥 Hot',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Tag(
                          label: item.subject,
                          color: cs.primary,
                          bg: cs.primaryContainer,
                        ),
                        _Tag(
                          label: 'Sem ${item.semester}',
                          color: cs.tertiary,
                          bg: cs.tertiaryContainer,
                        ),
                        _Tag(
                          label: isQP ? 'PYQ' : 'Notes',
                          color: isQP
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF4F46E5),
                          bg: isQP
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFEDE9FE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          item.uploaderName,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.download_rounded,
                            size: 12, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${item.downloads}',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Text(
                          formattedDate,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.fileUrl.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.download_rounded, color: cs.primary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Downloading: ${item.title}')),
                    );
                  },
                  tooltip: 'Download',
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Tag({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  String _type = 'notes';
  String _semester = '1';
  Uint8List? _fileBytes;
  String? _fileName;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileBytes = result.files.first.bytes;
        _fileName = result.files.first.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MaterialProvider>();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Upload Material',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface)),
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
                  labelText: 'Title', prefixIcon: Icon(Icons.title_rounded)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject_rounded)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'notes', child: Text('📒 Notes')),
                      DropdownMenuItem(value: 'qp', child: Text('📋 PYQ')),
                      DropdownMenuItem(value: 'lab', child: Text('🧪 Lab')),
                    ],
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: List.generate(
                      8,
                      (i) => DropdownMenuItem(
                          value: '${i + 1}', child: Text('Sem ${i + 1}')),
                    ),
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fileBytes != null
                        ? cs.primary
                        : cs.outline.withOpacity(0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _fileBytes != null
                          ? Icons.check_circle_rounded
                          : Icons.upload_file_rounded,
                      size: 32,
                      color: _fileBytes != null ? cs.primary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fileName ?? 'Tap to pick PDF / Doc / PPT',
                      style: TextStyle(
                        color: _fileBytes != null
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (provider.uploading || _fileBytes == null)
                    ? null
                    : () async {
                        if (_titleCtrl.text.trim().isEmpty ||
                            _subjectCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill all fields')),
                          );
                          return;
                        }
                        final ok = await provider.uploadMaterial(
                          fileBytes: _fileBytes!,
                          fileName: _fileName!,
                          title: _titleCtrl.text.trim(),
                          subject: _subjectCtrl.text.trim(),
                          type: _type,
                          semester: _semester,
                        );
                        if (ok && context.mounted) Navigator.pop(context);
                      },
                icon: provider.uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label:
                    Text(provider.uploading ? 'Uploading…' : 'Upload Material'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}