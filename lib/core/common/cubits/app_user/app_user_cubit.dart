import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:vandacoo/core/common/entities/user_entity.dart';
import 'package:vandacoo/core/common/models/user_model.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  static const String _userKey = 'cached_user';
  final SharedPreferences _prefs;

  AppUserCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(AppUserInitial()) {
    _loadUserFromPrefs();
  }

  void _loadUserFromPrefs() {
    final userJson = _prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);
        emit(AppUserLoggedIn(user));
      } catch (e) {
        _prefs.remove(_userKey);
        emit(AppUserInitial());
      }
    } else {
      emit(AppUserInitial());
    }
  }

  void updateUser(UserEntity? user) {
    if (user == null) {
      _prefs.remove(_userKey);
      emit(AppUserInitial());
    } else {
      // Convert UserEntity to UserModel for JSON serialization
      final userModel = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        bio: user.bio,
        propic: user.propic,
        hasSeenIntroVideo: user.hasSeenIntroVideo,
        accountType: user.accountType,
        gender: user.gender,
        age: user.age,
      );
      final userJson = json.encode(userModel.toJson());
      _prefs.setString(_userKey, userJson);
      emit(AppUserLoggedIn(user));
    }
  }
}
