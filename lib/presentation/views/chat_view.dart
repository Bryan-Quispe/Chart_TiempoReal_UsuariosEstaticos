import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../../domain/models/mensaje.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  // Usuario actual (por defecto Doris)
  String _usuarioActual = "Usuario Doris";

  // Lista de usuarios disponibles
  final List<String> _usuariosDisponibles = [
    "Usuario Doris",
    "Usuario Bryan",
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _enviarMensaje() {
    if (_controller.text.trim().isEmpty) return;

    final service = ref.read(firebaseServiceProvider);
    service.enviarMensaje(
      Mensaje(
        texto: _controller.text.trim(),
        autor: _usuarioActual,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    _controller.clear();

    // Scroll al final después de enviar
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final mensajesAsync = ref.watch(mensajeProvider);

    // Auto-scroll cuando lleguen nuevos mensajes
    ref.listen(mensajeProvider, (previous, next) {
      if (next is AsyncData) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat en Tiempo Real'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Selector de usuario en el AppBar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: _usuarioActual,
                  dropdownColor: Colors.blue[700],
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _usuariosDisponibles.map((String usuario) {
                    return DropdownMenuItem<String>(
                      value: usuario,
                      child: Text(usuario),
                    );
                  }).toList(),
                  onChanged: (String? nuevoUsuario) {
                    if (nuevoUsuario != null) {
                      setState(() {
                        _usuarioActual = nuevoUsuario;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicador de usuario actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Text(
              'Chateando como: $_usuarioActual',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: mensajesAsync.when(
              data: (mensajes) {
                if (mensajes.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay mensajes aún.\n¡Envía el primero!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: mensajes.length,
                  itemBuilder: (context, i) {
                    final m = mensajes[i];
                    // El mensaje es mío si el autor coincide con mi usuario actual
                    final esMio = m.autor == _usuarioActual;

                    return _MessageBubble(
                      mensaje: m,
                      esMio: esMio,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $e'),
                  ],
                ),
              ),
            ),
          ),

          // Barra de entrada de mensaje
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviarMensaje(),
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      onPressed: _enviarMensaje,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Mensaje mensaje;
  final bool esMio;

  const _MessageBubble({
    required this.mensaje,
    required this.esMio,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: esMio ? Colors.blue[600] : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: esMio ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: esMio ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mostrar nombre del autor solo si no es mío
            if (!esMio)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  mensaje.autor,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),

            // Texto del mensaje
            Text(
              mensaje.texto,
              style: TextStyle(
                color: esMio ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 4),

            // Hora del mensaje
            Text(
              _formatTimestamp(mensaje.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: esMio ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    // Si es hoy, solo mostrar hora
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }

    // Si es otro día, mostrar fecha y hora
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}