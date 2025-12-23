import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/models.dart';
import '../core/network/api_client.dart';

// Tracks list provider
final tracksProvider = FutureProvider<List<Track>>((ref) async {
  final response = await ApiClient().getTracks();
  final List<dynamic> data = response.data;
  return data.map((json) => Track.fromJson(json)).toList();
});

// Single track provider
final trackProvider = FutureProvider.family<Track, String>((ref, slug) async {
  final response = await ApiClient().getTrack(slug);
  return Track.fromJson(response.data);
});

// Courses for track provider
final coursesProvider = FutureProvider.family<List<Course>, String?>((ref, trackId) async {
  final response = await ApiClient().getCourses(trackId: trackId);
  final List<dynamic> data = response.data;
  return data.map((json) => Course.fromJson(json)).toList();
});

// Single course provider
final courseProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, slug) async {
  final response = await ApiClient().getCourse(slug);
  return response.data as Map<String, dynamic>;
});
