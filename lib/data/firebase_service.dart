import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/mensaje.dart';


class FirebaseService{
  //Instancia al firebase
  final DatabaseReference _ref=
  //Ruta a la base de datos
    FirebaseDatabase.instance.ref('chat/general');

  //Metodo para enviar mensaje
  Future<void> enviarMensaje (Mensaje mensaje) async{
    await _ref.push().set(mensaje.toJson());
  }
  //Leer mensajes poder acceder a la referencia desde app
 // DatabaseReference get mensajesRef => _ref;

  //Recibir memsaje
  Stream<List<Mensaje>> recibirMensajes() {
    return _ref.onValue.map((event) {
      //obtener datos
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      //validacion evitar errores cuando la lista esta vacia
      if (data == null) return [];
        //convertir json a objeto
      final mensajes =  data.values
          .map((e) => Mensaje.fromJson(e))
          .toList();
      //Ordenar por fecha
        mensajes.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return  mensajes;
    });
  }
}