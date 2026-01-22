import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/firebase_service.dart';
import '../../domain/models/mensaje.dart';

//una instacia a FirebaseService
final firebaseServiceProvider = Provider<FirebaseService>((ref) =>FirebaseService());
//clase StringProvider

final mensajeProvider = StreamProvider<List<Mensaje>>((ref){

  final service = ref.read(firebaseServiceProvider);
  return service.recibirMensajes();

});