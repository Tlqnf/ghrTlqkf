import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pedal/services/socket_service.dart';

void main() {
  group('SocketService', () {
    const socketUrl = 'ws://172.30.1.14:8080/ws/record-route';
    late SocketService socketService;

    setUp(() {
      socketService = SocketService(url: socketUrl);
    });

    tearDown(() {
      socketService.disconnect();
    });

    test('should connect, send, and receive a message', () async {
      // 1. Arrange: Set up a completer to wait for the first message
      final completer = Completer<dynamic>();

      // 2. Act: Connect and listen for messages
      socketService.connect();
      socketService.stream.listen((data) {
        if (!completer.isCompleted) {
          completer.complete(data);
        }
      }, onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Give the connection a moment to establish
      await Future.delayed(const Duration(seconds: 1));

      // Send a test message (adjust the message format as needed)
      const testMessage = '{"event": "test", "data": "Hello from Flutter Test"}';
      socketService.sendMessage(testMessage);

      // 3. Assert: Wait for the completer to complete (i.e., a message is received)
      // The test will time out and fail if no message is received.
      final receivedData = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('No message received from server within 5 seconds.'),
      );

      // Optionally, assert the content of the received data
      expect(receivedData, isNotNull);
    });
  });
}
