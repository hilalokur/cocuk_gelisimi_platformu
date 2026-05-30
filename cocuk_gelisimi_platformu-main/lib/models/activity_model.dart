class ActivityModel {
  final String title;
  final String description;
  final String ageGroup;

  ActivityModel({
    required this.title,
    required this.description,
    required this.ageGroup,
  });

  // Veriyi Firebase'e göndermek için Map formatına çevirir
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ageGroup': ageGroup, // Artık tırnaksız ve temiz gidecek!
    };
  }
}