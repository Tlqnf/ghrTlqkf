import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  final String url;
  WebSocketChannel? _channel;
  final StreamController<dynamic> _streamController = StreamController<dynamic>.broadcast();
  bool _isConnected = false;

  SocketService({required this.url});

  Stream<dynamic> get stream => _streamController.stream;

  void connect() {
    if (_isConnected) {
      debugPrint("Socket is already connected.");
      return;
    }
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      debugPrint("Socket connected to $url");

      _channel!.stream.listen(
        (data) {
          _streamController.add(data);
        },
        onDone: () {
          _isConnected = false;
          debugPrint("Socket disconnected.");
        },
        onError: (error) {
          _isConnected = false;
          debugPrint("Socket error: $error");
          _streamController.addError(error);
        },
      );
    } catch (e) {
      debugPrint("Error connecting to socket: $e");
      _isConnected = false;
    }
  }

  void sendMessage(String message) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(message);
      debugPrint("Sent message: $message");
    } else {
      debugPrint("Cannot send message. Socket is not connected.");
    }
  }

  void disconnect() {
    if (_channel != null && _isConnected) {
      _channel!.sink.close();
      _isConnected = false;
      debugPrint("Socket disconnected.");
    }
  }
}
