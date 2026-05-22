class Note {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final String uploaderId;
  final String uploaderName;
  final DateTime createdAt;
  final int downloadCount;
  final bool isPdf;
  final double rating;
  final int reviewCount;
  final String? previewUrl;
  final String? previewText;
  final String? authorAvatarUrl; // Joined from profiles table
  final bool isPremium;
  final int creditsCost;
  bool isBookmarked;


  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    required this.uploaderId,
    required this.uploaderName,
    required this.createdAt,
    this.downloadCount = 0,
    this.isPdf = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.previewUrl,
    this.previewText,
    this.authorAvatarUrl,
    this.isPremium = false,
    this.creditsCost = 0,
    this.isBookmarked = false,
  });


  bool get isFree => price <= 0;

  factory Note.fromMap(Map<String, dynamic> data) {
    // Helper to safely parse doubles
    double toDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    // Helper to safely parse ints
    int toInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return Note(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: toDouble(data['price']),
      category: data['category'] ?? '',
      fileUrl: data['file_url'] ?? data['fileUrl'] ?? '',
      fileName: data['file_name'] ?? data['fileName'],
      fileType: data['file_type'] ?? data['fileType'],
      uploaderId: data['uploader_id'] ?? data['uploaderId'] ?? '',
      uploaderName: data['uploader_name'] ?? data['uploaderName'] ?? '',
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : (data['createdAt'] is DateTime ? data['createdAt'] : DateTime.now()),
      downloadCount: toInt(data['download_count'] ?? data['downloadCount'] ?? data['downloads']),
      isPdf: data['is_pdf'] ?? data['isPdf'] ?? (data['file_name']?.endsWith('.pdf') ?? false),
      rating: toDouble(data['rating']),
      reviewCount: toInt(data['review_count'] ?? data['reviewCount']),
      previewUrl: data['preview_url'] ?? data['previewUrl'],
      previewText: data['preview_text'] ?? data['previewText'],
      authorAvatarUrl: data['profiles']?['avatar_url'] ?? data['authorAvatarUrl'],
      isPremium: data['is_premium'] ?? false,
      creditsCost: toInt(data['credits_cost']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_type': fileType,
      'uploader_id': uploaderId,
      'uploader_name': uploaderName,
      'created_at': createdAt.toIso8601String(),
      'download_count': downloadCount,
      'is_pdf': isPdf,
      'rating': rating,
      'review_count': reviewCount,
      'preview_url': previewUrl,
      'preview_text': previewText,
      'authorAvatarUrl': authorAvatarUrl,
      'is_premium': isPremium,
      'credits_cost': creditsCost,
    };
  }

  Note copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String? uploaderId,
    String? uploaderName,
    DateTime? createdAt,
    int? downloadCount,
    bool? isPdf,
    double? rating,
    int? reviewCount,
    String? previewUrl,
    String? previewText,
    String? authorAvatarUrl,
    bool? isPremium,
    int? creditsCost,
    bool? isBookmarked,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      createdAt: createdAt ?? this.createdAt,
      downloadCount: downloadCount ?? this.downloadCount,
      isPdf: isPdf ?? this.isPdf,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      previewUrl: previewUrl ?? this.previewUrl,
      previewText: previewText ?? this.previewText,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      isPremium: isPremium ?? this.isPremium,
      creditsCost: creditsCost ?? this.creditsCost,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

}

class Review {
  final String id;
  final String noteId;
  final String userId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;
  final String? avatarUrl; // Joined from profiles table using user_id

  Review({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
    this.avatarUrl,
  });

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: data['id']?.toString() ?? '',
      noteId: data['note_id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name'] ?? 'Anonymous',
      comment: data['review_text'] ?? data['comment'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: data['created_at'] != null 
          ? DateTime.parse(data['created_at']) 
          : DateTime.now(),
      avatarUrl: data['profiles']?['avatar_url'] ?? data['avatarUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'note_id': noteId,
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }
}


