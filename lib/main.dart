import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

final log = Logger('main');

String envReq(String key) {
  final v = Platform.environment[key];
  if (v == null || v.isEmpty) {
    throw StateError('Missing env: $key');
  }
  return v;
}

String envOr(String key, String def) => Platform.environment[key] ?? def;

bool envIsLive() {
  final env = envOr('ARTIST_TALLY_ENV', 'development');
  final qs = envOr('Http_Query', '');
  return env == 'production' || qs.contains('env=production');
}

DateTime midnightLocal() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

Uri buildApiUrl(DateTime startDate, DateTime endDate) {
  final apiDomain = envReq('ARTIST_TALLY_API_DOMAIN');
  final protocol = apiDomain.contains('localhost') ? 'http' : 'https';
  return Uri.parse(
    '$protocol://$apiDomain/api/v1/orders/portraits/artist-tally'
    '?since=${startDate.millisecondsSinceEpoch}'
    '&until=${endDate.millisecondsSinceEpoch}',
  );
}

Future<http.Response> _req(
  Uri url,
  String method, {
  String? body,
  Map<String, String>? customHeaders,
}) async {
  final headers = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'artist_tally_tool/2 (com.nozzlegear.artist_tally_tool)',
    ...?customHeaders,
  };

  switch (method.toUpperCase()) {
    case 'POST':
      return http.post(url, body: body, headers: headers).timeout(const Duration(seconds: 25));
    case 'GET':
      return http.get(url, headers: headers).timeout(const Duration(seconds: 25));
    default:
      throw UnimplementedError('Unsupported method $method');
  }
}

void _ensureSuccess(http.Response resp) {
  if (resp.statusCode < 200 || resp.statusCode >= 300) {
    final message =
        'Request to ${resp.request?.url} failed with ${resp.statusCode} ${resp.reasonPhrase}.';
    log.severe('$message Response body: ${resp.body}');
    throw StateError(message);
  }
}

Future<String> getBody(String url, [Map<String, String>? headers]) async {
  final r = await _req(Uri.parse(url), 'GET', customHeaders: headers);
  _ensureSuccess(r);
  return r.body;
}

Future<String> postBody(String url, String body,
    [Map<String, String>? headers]) async {
  final r =
      await _req(Uri.parse(url), 'POST', body: body, customHeaders: headers);
  _ensureSuccess(r);
  return r.body;
}

Future<void> main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    // Match old format closely
    stdout.writeln('[${rec.level.name}] ${rec.time}: ${rec.message}');
  });

  log.info('Artist Tally Tool starting up.');

  final endDate = midnightLocal();
  final startDate = DateTime(endDate.year, endDate.month, endDate.day - 1);
  final apiUrl = buildApiUrl(startDate, endDate);

  final swuKey = envReq('ARTIST_TALLY_SWU_KEY');
  final auth = base64Encode(utf8.encode('$swuKey:'));
  final swuHeaders = {
    'Authorization': 'Basic $auth',
  };

  log.info('Getting tally from $apiUrl.');

  final body = await getBody(apiUrl.toString());
  final tallyResponse = TallyResponse.fromJson(jsonDecode(body));

  final tally = [
    for (final e in tallyResponse.summary.entries)
      TallyTemplate(artist: e.key, count: e.value)
  ];

  final message = buildEmailData(startDate, tally);

  log.info('Sending to: ${message.recipient.address}');
  for (final cc in message.cc) {
    log.info('CCed to: ${cc.address}');
  }

  final result = await postBody(
    'https://api.sendwithus.com/api/v1/send',
    jsonEncode(message),
    swuHeaders,
  );

  log.info('Send result: $result');
}

SwuMessage buildEmailData(DateTime startDate, List<TallyTemplate> tally) {
  final isLive = envIsLive();
  final swuTemplateId = envReq('ARTIST_TALLY_SWU_TEMPLATE_ID');
  final emailRecipient =
      SwuRecipient.fromJson(jsonDecode(envReq('ARTIST_TALLY_PRIMARY_RECIPIENT')));
  final ccs = isLive
      ? (jsonDecode(envReq('ARTIST_TALLY_CC_LIST')) as List)
          .map((e) => SwuRecipient.fromJson(e as Map<String, dynamic>))
          .toList()
      : <SwuRecipient>[];
  final sender =
      SwuSender.fromJson(jsonDecode(envReq('ARTIST_TALLY_SENDER')));

  return SwuMessage(
    template: swuTemplateId,
    recipient: emailRecipient,
    cc: ccs,
    sender: sender,
    templateData: SwuTallyTemplateData(
      date: DateFormat('MMM dd, yyyy').format(startDate),
      tally: tally,
    ),
  );
}

class TallyResponse {
  final num since;
  final Map<String, int> summary;

  TallyResponse({required this.since, required this.summary});

  factory TallyResponse.fromJson(Map<String, dynamic> j) => TallyResponse(
        since: j['since'] as num,
        summary: (j['summary'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}

class TallyTemplate {
  final String artist;
  final int count;

  TallyTemplate({required this.artist, required this.count});

  Map<String, dynamic> toJson() => {
        'artist': artist,
        'count': count,
      };
}

class SwuRecipient {
  final String name;
  final String address;

  SwuRecipient({required this.name, required this.address});

  factory SwuRecipient.fromJson(Map<String, dynamic> j) => SwuRecipient(
        name: j['name'] as String,
        address: j['address'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
      };
}

class SwuSender {
  final String name;
  final String address;
  final String replyTo;

  SwuSender({required this.name, required this.address, required this.replyTo});

  factory SwuSender.fromJson(Map<String, dynamic> j) => SwuSender(
        name: j['name'] as String,
        address: j['address'] as String,
        replyTo: j['replyTo'] as String,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'replyTo': replyTo,
      };
}

class SwuTallyTemplateData {
  final String date;
  final List<TallyTemplate> tally;

  SwuTallyTemplateData({required this.date, required this.tally});

  Map<String, dynamic> toJson() => {
        'date': date,
        'tally': tally.map((t) => t.toJson()).toList(),
      };
}

class SwuMessage {
  final String template;
  final SwuRecipient recipient;
  final List<SwuRecipient> cc;
  final SwuSender sender;
  final SwuTallyTemplateData templateData;

  SwuMessage({
    required this.template,
    required this.recipient,
    required this.cc,
    required this.sender,
    required this.templateData,
  });

  Map<String, dynamic> toJson() => {
    'template': template,
    'recipient': recipient.toJson(),
    'cc': cc.map((r) => r.toJson()).toList(),
    'sender': sender.toJson(),
    'template_data': templateData.toJson(),
  };
}
