import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/fan_level.dart';
import '../domain/profile.dart';

const _cacheKey = 'drama_profile';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile> fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    final profile = Profile.fromJson(data);
    await _writeCache(profile);
    return profile;
  }

  Future<Profile?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheProfile(Profile profile) => _writeCache(profile);

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }

  Future<List<FanLevelThreshold>> fetchFanLevelThresholds() async {
    final rows = await _client
        .from('fan_level_thresholds')
        .select()
        .order('level');
    return rows.map<FanLevelThreshold>(FanLevelThreshold.fromJson).toList();
  }

  Future<void> updateProfile({
    required String userId,
    required String username,
    String? avatarUrl,
  }) async {
    await _client.from('profiles').update({
      'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    }).eq('id', userId);
  }

  Future<void> _writeCache(Profile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(profile.toJson()));
  }
}
