class Mensaje{

  final String texto;
  final String autor;
  final int timestamp;

  Mensaje({
    required this.texto,
    required this.autor,
    required this.timestamp});

  factory Mensaje.fromJson(Map<dynamic, dynamic> json) {
    return Mensaje(
      texto: json['texto'] ?? '',
      autor: json['autor'] ?? '',
      timestamp: json['timestamp'] ??0,
    );
  }
  Map<String, dynamic> toJson(){
    return {
      'texto': texto,
      'autor': autor,
      'timestamp': timestamp,
    };
  }

}