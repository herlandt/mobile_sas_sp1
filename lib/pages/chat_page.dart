import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../services/api_service.dart'; // Importamos el servicio

class ChatPage extends StatefulWidget {
  final String appointmentId;

  const ChatPage({super.key, required this.appointmentId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  WebSocketChannel? _channel;
  final List<Map<String, String>> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _connectToChat(); // Llamamos a la nueva función
  }

  // --- ESTA ES LA FUNCIÓN QUE FALTABA ---
  Future<void> _connectToChat() async {
    try {
      print("CHAT DEBUG: Paso 1 - Iniciando conexión...");
      final token = await _apiService.getToken();
      print("CHAT DEBUG: Paso 2 - Token obtenido: ${token != null ? 'Sí, existe' : 'No, es nulo'}");

      if (token == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error de autenticación.';
          });
        }
        return;
      }

      final wsUrl = 'ws://10.0.2.2:8000/ws/chat/${widget.appointmentId}/?token=$token';
      print("CHAT DEBUG: Paso 3 - Conectando a la URL: $wsUrl");

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print("CHAT DEBUG: Paso 4 - Conexión WebSocket creada.");

      _channel!.stream.listen(
        (message) {
          print("CHAT DEBUG: Mensaje recibido: $message");
          final decodedMessage = jsonDecode(message);
          if (mounted) {
            setState(() {
              _messages.add({
                "sender": decodedMessage['sender'] ?? 'Desconocido',
                "message": decodedMessage['message'] ?? '',
              });
            });
          }
        },
        onDone: () => print("CHAT DEBUG: Conexión cerrada."),
        onError: (error) => print("CHAT DEBUG: Error en stream: $error"),
      );
      print("CHAT DEBUG: Paso 5 - Escuchando el stream.");

      if (mounted) {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      print("CHAT DEBUG: ERROR CATASTRÓFICO en _connectToChat: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al conectar al chat.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat de la Cita'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
            : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ListTile(
                        title: Text(message['sender']!),
                        subtitle: Text(message['message']!),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(labelText: 'Escribe un mensaje...'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _channel != null) {
      _channel!.sink.add(jsonEncode({'message': _controller.text}));
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
