import 'package:flutter/material.dart';

class MaterialItem {
  final String id;
  final String title;
  final String subject;
  final String type; // 'notes' or 'qp'
  final String semester;
  final String fileUrl;
  final String uploadedBy;
  final String uploaderName;
  final String createdAt;
  final int downloads;

  MaterialItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.semester,
    required this.fileUrl,
    required this.uploadedBy,
    required this.uploaderName,
    required this.createdAt,
    required this.downloads,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subject: json['subject'] ?? '',
      type: json['type'] ?? 'notes',
      semester: json['semester'] ?? 'N/A',
      fileUrl: json['fileUrl'] ?? '',
      uploadedBy: json['uploadedBy'] ?? '',
      uploaderName: json['uploaderName'] ?? 'Unknown',
      createdAt: json['createdAt'] ?? '',
      downloads: json['downloads'] ?? 0,
    );
  }

  bool get isQP => type == 'qp';
  bool get isNotes => type == 'notes';
}

class Announcement {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String department;
  final String createdBy;
  final String createdByName;
  final String createdAt;
  final bool isPinned;

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.department,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.isPinned,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'low',
      department: json['department'] ?? 'ALL',
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Staff',
      createdAt: json['createdAt'] ?? '',
      isPinned: json['isPinned'] ?? false,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case 'high':
        return const Color(0xFFEA4335);
      case 'medium':
        return const Color(0xFFFBBC04);
      default:
        return const Color(0xFF34A853);
    }
  }
}