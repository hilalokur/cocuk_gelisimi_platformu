import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChildProvider extends ChangeNotifier {
  String? _selectedChildId;
  List<DocumentSnapshot> _children = [];
  bool _isLoading = true;

  String? get selectedChildId => _selectedChildId;
  List<DocumentSnapshot> get children => _children;
  bool get isLoading => _isLoading;

  ChildProvider() {
    _init();
  }

  void _init() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((userDoc) {
            if (userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>;
              final role = data['role'] ?? 'parent';
              final parentId = role == 'bakici' ? data['parentId'] : user.uid;

              if (parentId != null) {
                FirebaseFirestore.instance
                    .collection('children')
                    .where('parentId', isEqualTo: parentId)
                    .snapshots()
                    .listen((snapshot) {
                      _children = snapshot.docs;
                      if (_selectedChildId == null && _children.isNotEmpty) {
                        _selectedChildId = _children.first.id;
                      } else if (_selectedChildId != null &&
                          _children.isNotEmpty) {
                        bool exists = _children.any(
                          (doc) => doc.id == _selectedChildId,
                        );
                        if (!exists) _selectedChildId = _children.first.id;
                      }
                      _isLoading = false;
                      notifyListeners();
                    });
              }
            }
          });
    }
  }

  void setSelectedChild(String childId) {
    _selectedChildId = childId;
    notifyListeners();
  }
}
