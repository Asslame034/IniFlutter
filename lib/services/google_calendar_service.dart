import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class GoogleCalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  Future<void> syncTaskToCalendar(Task task) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Gagal login ke Google Calendar');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception('Tidak dapat memperoleh akses token');
      }

      final client = GoogleAuthClient(accessToken);
      final calendarApi = calendar.CalendarApi(client);

      // Buat event di Google Calendar
      final event = calendar.Event()
        ..summary = task.title
        ..description = task.description;

      // Set start time
      final startTime = calendar.EventDateTime()
        ..dateTime = task.dueDate
        ..timeZone = 'Asia/Jakarta';
      event.start = startTime;

      // Set end time
      final endTime = calendar.EventDateTime()
        ..dateTime = task.dueDate?.add(const Duration(hours: 1))
        ..timeZone = 'Asia/Jakarta';
      event.end = endTime;

      await calendarApi.events.insert(event, 'primary');
    } catch (e) {
      print('Error syncing to Google Calendar: $e');
      rethrow;
    }
  }

  Future<void> deleteTaskFromCalendar(String eventId) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Gagal login ke Google Calendar');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception('Tidak dapat memperoleh akses token');
      }

      final client = GoogleAuthClient(accessToken);
      final calendarApi = calendar.CalendarApi(client);

      await calendarApi.events.delete('primary', eventId);
    } catch (e) {
      print('Error deleting from Google Calendar: $e');
      rethrow;
    }
  }
}

class GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
} 