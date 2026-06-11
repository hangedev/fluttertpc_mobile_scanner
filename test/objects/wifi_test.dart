import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/enums/encryption_type.dart';
import 'package:mobile_scanner/src/objects/wifi.dart';

void main() {
  group('WiFi', () {
    test('constructor creates with default values', () {
      const wifi = WiFi();
      expect(wifi.encryptionType, EncryptionType.unknown);
      expect(wifi.ssid, isNull);
      expect(wifi.password, isNull);
    });

    test('constructor creates with custom values', () {
      const wifi = WiFi(
        encryptionType: EncryptionType.wpa,
        ssid: 'HomeNetwork',
        password: 'secure123',
      );
      expect(wifi.encryptionType, EncryptionType.wpa);
      expect(wifi.ssid, 'HomeNetwork');
      expect(wifi.password, 'secure123');
    });

    test('fromNative parses data correctly', () {
      final data = <Object?, Object?>{
        'encryptionType': 2, // wpa
        'ssid': 'GuestWiFi',
        'password': 'guestpass',
      };

      final wifi = WiFi.fromNative(data);
      expect(wifi.encryptionType, EncryptionType.wpa);
      expect(wifi.ssid, 'GuestWiFi');
      expect(wifi.password, 'guestpass');
    });

    test('fromNative handles WEP encryption', () {
      final data = <Object?, Object?>{
        'encryptionType': 3, // wep
        'ssid': 'OldNetwork',
      };

      final wifi = WiFi.fromNative(data);
      expect(wifi.encryptionType, EncryptionType.wep);
      expect(wifi.ssid, 'OldNetwork');
    });

    test('fromNative handles no encryption', () {
      final data = <Object?, Object?>{
        'encryptionType': 1, // open
        'ssid': 'OpenNetwork',
      };

      final wifi = WiFi.fromNative(data);
      expect(wifi.encryptionType, EncryptionType.open);
      expect(wifi.ssid, 'OpenNetwork');
    });

    test('fromNative handles missing ssid', () {
      final data = <Object?, Object?>{
        'encryptionType': 2,
        'password': 'secret',
      };

      final wifi = WiFi.fromNative(data);
      expect(wifi.encryptionType, EncryptionType.wpa);
      expect(wifi.ssid, isNull);
      expect(wifi.password, 'secret');
    });

    test('fromNative handles missing fields', () {
      final data = <Object?, Object?>{};

      final wifi = WiFi.fromNative(data);
      expect(wifi.encryptionType, EncryptionType.unknown);
      expect(wifi.ssid, isNull);
      expect(wifi.password, isNull);
    });

    test('fromNative handles null encryption type', () {
      final data = <Object?, Object?>{
        'encryptionType': null,
        'ssid': 'TestNet',
      };

      final wifi = WiFi.fromNative(data);
      expect(wifi.encryptionType, EncryptionType.unknown);
      expect(wifi.ssid, 'TestNet');
    });
  });
}