import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/security/device_key_store.dart';
import '../../../core/security/device_security_config.dart';
import '../../../core/security/device_security_service.dart';
import '../../../core/security/request_canonicalizer.dart';
import '../../../dependency_injection/injection_container.dart';

/// Internal tool (debug builds or DEVICE_SECURITY_DIAGNOSTIC=true) to check on
/// a real phone that key generation, attestation and signing work, and to
/// export a report + test vector for the backend.
///
/// It uses its own key alias, so it never touches the real device enrollment.
class DeviceSecurityDiagnosticScreen extends StatefulWidget {
  const DeviceSecurityDiagnosticScreen({super.key});

  @override
  State<DeviceSecurityDiagnosticScreen> createState() => _DeviceSecurityDiagnosticScreenState();
}

class _DeviceSecurityDiagnosticScreenState extends State<DeviceSecurityDiagnosticScreen> {
  static const _alias = 'smartpos_diagnostic_key';
  static const _benchmarkRuns = 20;

  final DeviceKeyStore _keyStore = serviceLocator<DeviceKeyStore>();
  final DeviceSecurityService _security = serviceLocator<DeviceSecurityService>();

  Map<String, dynamic>? _report;
  String? _error;
  bool _running = false;

  Future<void> _runDiagnostic() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final report = <String, dynamic>{'device': await _keyStore.deviceInfo()};

      // 1. Key generation with a random challenge, as the backend would send.
      final random = Random.secure();
      final challenge = Uint8List.fromList(List<int>.generate(32, (_) => random.nextInt(256)));
      final stopwatch = Stopwatch()..start();
      final key = await _keyStore.generateKey(challenge, alias: _alias);
      final generationMs = stopwatch.elapsedMilliseconds;

      final attestation = await _keyStore.describeAttestation(alias: _alias);
      final installedDigests = List<String>.from(report['device']['signingCertSha256'] as List);
      final attestedDigests = List<String>.from(attestation['attestedSigningCertSha256'] as List? ?? []);

      // 2. Sign / verify locally with the public key.
      const message = 'HELLO';
      final signature = await _keyStore.sign(message, alias: _alias);
      final verified = await _keyStore.verify(message, signature, alias: _alias);
      final tamperedRejected = !await _keyStore.verify('HELL0', signature, alias: _alias);

      // 3. Signing speed (one signature per API request).
      stopwatch.reset();
      for (var i = 0; i < _benchmarkRuns; i++) {
        await _keyStore.sign('benchmark-$i', alias: _alias);
      }
      final signAverageMs = stopwatch.elapsedMilliseconds / _benchmarkRuns;

      report.addAll({
        'checks': {
          'attestationProvided': key.attested,
          'hardwareBacked': key.securityLevel == 'TEE' || key.securityLevel == 'STRONGBOX',
          'challengeMatches': attestation['attestationChallengeBase64'] == base64Encode(challenge),
          'attestationSecurityLevel': attestation['attestationSecurityLevel'],
          'packageMatches':
              (attestation['attestedPackages'] as List?)?.contains(report['device']['packageName']) ?? false,
          'signingCertMatchesInstalledApk': attestedDigests.any(installedDigests.contains),
          'verifiedBootState': attestation['verifiedBootState'],
          'deviceLocked': attestation['deviceLocked'],
          'localSignatureVerified': verified,
          'tamperedMessageRejected': tamperedRejected,
        },
        'timings': {'keyGenerationMs': generationMs, 'signAverageMs': signAverageMs},
        'key': {
          'securityLevel': key.securityLevel,
          'attestationError': key.attestationError,
          'publicKey': await _keyStore.publicKey(alias: _alias),
        },
        'attestation': attestation,
        'certChain': key.certChain,
        'testVector': await _testVector(),
        'enrollment': {
          'enabled': DeviceSecurityConfig.enabled,
          'mockBackend': DeviceSecurityConfig.useMockBackend,
          'deviceId': _security.deviceId,
          'status': _security.status,
          'attested': _security.attested,
        },
      });
      setState(() => _report = report);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _running = false);
    }
  }

  /// A fully signed example request the backend can use to test its verifier.
  Future<Map<String, dynamic>> _testVector() async {
    const deviceId = 'diagnostic-device';
    final body = jsonEncode({'phone': '0661234567', 'otp': '482913'});
    final uri = Uri.parse('https://example.invalid/api/login/verify-otp?lang=fr');
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = RequestCanonicalizer.generateNonce();
    final bodyHash = RequestCanonicalizer.bodySha256(body);
    final canonical = RequestCanonicalizer.canonicalRequest(
      method: 'POST',
      uri: uri,
      timestamp: timestamp,
      nonce: nonce,
      bodySha256: bodyHash,
      deviceId: deviceId,
    );
    return {
      'publicKey': await _keyStore.publicKey(alias: _alias),
      'method': 'POST',
      'pathAndQuery': RequestCanonicalizer.pathAndQuery(uri),
      'body': body,
      'headers': {
        SignedRequestHeaders.deviceId: deviceId,
        SignedRequestHeaders.timestamp: timestamp,
        SignedRequestHeaders.nonce: nonce,
        SignedRequestHeaders.bodySha256: bodyHash,
        SignedRequestHeaders.signature: await _keyStore.sign(canonical, alias: _alias),
      },
      'canonical': canonical,
    };
  }

  Future<void> _copyReport() async {
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(_report)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport copié')));
    }
  }

  Future<void> _resetEnrollment() async {
    await _security.reset();
    if (DeviceSecurityConfig.enabled) await _security.ensureEnrolled();
    setState(() {});
  }

  /// Sends a signed request to /security/test (once the backend exposes it).
  Future<void> _callTestEndpoint() async {
    String result;
    try {
      final response = await serviceLocator<Dio>().get('/security/test');
      result = '${response.statusCode} ${response.data}';
    } on DioException catch (e) {
      result = '${e.response?.statusCode ?? e.type} ${e.response?.data ?? e.message}';
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  void dispose() {
    _keyStore.deleteKey(alias: _alias);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checks = _report?['checks'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic sécurité appareil'),
        actions: [
          if (_report != null)
            IconButton(icon: const Icon(Icons.copy), tooltip: 'Copier le rapport', onPressed: _copyReport),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _running ? null : _runDiagnostic,
            icon: _running
                ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow),
            label: const Text('Lancer le diagnostic'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _running ? null : _resetEnrollment,
                  child: const Text("Réinitialiser l'enrôlement"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _running ? null : _callTestEndpoint,
                  child: const Text('Appeler /security/test'),
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (checks != null) ...[
            _section('Vérifications', checks),
            _section('Temps', _report!['timings']),
            _section('Appareil', _report!['device']),
            _section('Attestation', _report!['attestation']),
            _section('Enrôlement', _report!['enrollment']),
            _section('Clé', _report!['key']),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, Object? values) {
    final entries = (values as Map<String, dynamic>).entries;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.value is bool)
                    Icon(
                      entry.value as bool ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: entry.value as bool ? Colors.green : Colors.red,
                    ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      '${entry.key}: ${entry.value is bool ? '' : entry.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
