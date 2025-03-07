// import 'dart:convert';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/fitness/v1.dart';
// import 'package:googleapis_auth/googleapis_auth.dart' as auth;

// class GoogleFitService {
//   static const List<String> fitnessScopes = [
//     FitnessApi.fitnessActivityReadScope,
//     FitnessApi.fitnessSleepReadScope,
//     FitnessApi.fitnessHeartRateReadScope,
//   ];

//   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: fitnessScopes);
//   late FitnessApi _fitnessApi;

//   Future<void> init() async {
//     final account = await _googleSignIn.signIn();
//     if (account == null) {
//       throw Exception('User cancelled Google login');
//     }

//     final authHeaders = await account.authHeaders;
//     final client = auth.AuthClient(authHeaders);

//     _fitnessApi = FitnessApi(client);
//   }

//   Future<String?> fetchStepsData() async {
//     final response = await _fetchAggregateData('com.google.step_count.delta');
//     if (response == null || (response.bucket?.isEmpty ?? true)) {
//       return null;
//     }

//     return _parseSteps(response);
//   }

//   Future<String?> fetchHeartRateData() async {
//     final response = await _fetchAggregateData('com.google.heart_rate.bpm');
//     if (response == null || response.bucket?.isEmpty ?? true) {
//       return null; // No data
//     }
//     return _parseHeartRate(response);
//   }

//   Future<String?> fetchSleepData() async {
//     final response = await _fetchAggregateData('com.google.sleep.segment');
//     if (response == null || response.bucket?.isEmpty ?? true) {
//       return null; // No data
//     }
//     return _parseSleep(response);
//   }

//   Future<AggregateResponse?> _fetchAggregateData(String dataType) async {
//     try {
//       final response = await _fitnessApi.users.dataset.aggregate(
//         'me',
//         AggregateRequest(
//           aggregateBy: [AggregateBy(dataTypeName: dataType)],
//           bucketByTime: BucketByTime(durationMillis: 86400000),
//           startTimeMillis: DateTime.now()
//               .subtract(Duration(days: 7))
//               .toUtc()
//               .millisecondsSinceEpoch,
//           endTimeMillis: DateTime.now().toUtc().millisecondsSinceEpoch,
//         ),
//       );
//       return response;
//     } catch (e) {
//       print('Failed to fetch $dataType: $e');
//       return null;
//     }
//   }

//   String _parseSteps(AggregateResponse response) {
//     int totalSteps = 0;

//     for (var bucket in response.bucket ?? []) {
//       for (var dataset in bucket.dataset ?? []) {
//         for (var point in dataset.point ?? []) {
//           for (var value in point.value ?? []) {
//             totalSteps += value.intVal ?? 0;
//           }
//         }
//       }
//     }

//     return "$totalSteps Steps in last 7 days";
//   }

//   String _parseHeartRate(AggregateResponse response) {
//     List<double> heartRates = [];

//     for (var bucket in response.bucket ?? []) {
//       for (var dataset in bucket.dataset ?? []) {
//         for (var point in dataset.point ?? []) {
//           for (var value in point.value ?? []) {
//             if (value.fpVal != null) {
//               heartRates.add(value.fpVal!);
//             }
//           }
//         }
//       }
//     }

//     if (heartRates.isEmpty) {
//       return "No Heart Rate Data";
//     }

//     double avgHeartRate =
//         heartRates.reduce((a, b) => a + b) / heartRates.length;
//     return "Average Heart Rate: ${avgHeartRate.toStringAsFixed(1)} bpm";
//   }

//   String _parseSleep(AggregateResponse response) {
//     int totalSleepMinutes = 0;

//     for (var bucket in response.bucket ?? []) {
//       for (var dataset in bucket.dataset ?? []) {
//         for (var point in dataset.point ?? []) {
//           final startTime = DateTime.fromMillisecondsSinceEpoch(
//               point.startTimeNanos! ~/ 1000000);
//           final endTime = DateTime.fromMillisecondsSinceEpoch(
//               point.endTimeNanos! ~/ 1000000);
//           totalSleepMinutes += endTime.difference(startTime).inMinutes;
//         }
//       }
//     }

//     if (totalSleepMinutes == 0) {
//       return "No Sleep Data";
//     }

//     int hours = totalSleepMinutes ~/ 60;
//     int minutes = totalSleepMinutes % 60;
//     return "Total Sleep: ${hours}h ${minutes}m (last 7 days)";
//   }
// }

// class GoogleHttpClient extends auth.BaseClient {
//   final Map<String, String> _headers;
//   final auth.Client _inner = auth.Client();

//   GoogleHttpClient(this._headers);

//   @override
//   Future<auth.StreamedResponse> send(auth.BaseRequest request) {
//     request.headers.addAll(_headers);
//     return _inner.send(request);
//   }
// }
