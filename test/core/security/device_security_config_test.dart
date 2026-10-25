import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobilis_smart_pos/src/core/security/device_security_config.dart';

void main() {
  // Whichever variable EndPoints.baseUrl reads, it points to the same API here
  setUpAll(() => dotenv.testLoad(fileInput: '''
BASE_URL=https://ms-pos.mobilis.dz/api1/app
BASE_URL_PRE_PROD=https://ms-pos.mobilis.dz/api1/app
BASE_URL_DEV=https://ms-pos.mobilis.dz/api1/app
'''));

  test('only requests to our API are considered API requests', () {
    expect(DeviceSecurityConfig.isApiRequest(Uri.parse('https://ms-pos.mobilis.dz/api1/app/login')), isTrue);
    expect(DeviceSecurityConfig.isApiRequest(Uri.parse('https://ocr.example.dz/process_id')), isFalse);
    expect(DeviceSecurityConfig.isApiRequest(Uri.parse('https://ms-pos.mobilis.dz/api2/admin/x')), isFalse);
  });

  test('signing is off unless DEVICE_SECURITY_ENABLED is set at build time', () {
    expect(DeviceSecurityConfig.shouldSign(Uri.parse('https://ms-pos.mobilis.dz/api1/app/login')),
        DeviceSecurityConfig.enabled);
  });
}
