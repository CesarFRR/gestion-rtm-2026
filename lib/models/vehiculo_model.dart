import 'package:cloud_firestore/cloud_firestore.dart';

class Vehiculo {
  final String id;
  final String placa;
  final String empresa;
  final String tipo; // 'Carro' o 'Moto'
  final DateTime? fechaMatricula;
  final DateTime? venceRTM;
  final DateTime? venceSOAT;
  final DateTime? venceBotiquin; // Puede ser nulo si es Moto
  final DateTime? venceExtintor; // Puede ser nulo si es Moto
  
  // URLs de fotos
  final String? fotoFrenteUrl;
  final String? fotoTraseraUrl;
  final String? fotoLateralUrl;

  Vehiculo({
    required this.id,
    required this.placa,
    required this.empresa,
    required this.tipo,
    required this.fechaMatricula,
    required this.venceRTM,
    required this.venceSOAT,
    this.venceBotiquin,
    this.venceExtintor,
    this.fotoFrenteUrl,
    this.fotoTraseraUrl,
    this.fotoLateralUrl,
  });

  factory Vehiculo.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    DateTime? toDateNullable(dynamic field) {
      if (field == null) return null;
      if (field is Timestamp) return field.toDate();
      return null;
    }

    return Vehiculo(
      id: doc.id,
      placa: data['placa'] ?? '',
      empresa: data['empresa'] ?? '',
      tipo: data['tipo'] ?? 'Carro',
      fechaMatricula: toDateNullable(data['fechaMatricula']),
      venceRTM: toDateNullable(data['venceRTM']),
      venceSOAT: toDateNullable(data['venceSOAT']),
      venceBotiquin: toDateNullable(data['venceBotiquin']),
      venceExtintor: toDateNullable(data['venceExtintor']),
      fotoFrenteUrl: data['fotoFrenteUrl'],
      fotoTraseraUrl: data['fotoTraseraUrl'],
      fotoLateralUrl: data['fotoLateralUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placa': placa,
      'empresa': empresa,
      'tipo': tipo,
      'fechaMatricula': fechaMatricula != null ? Timestamp.fromDate(fechaMatricula!) : null,
      'venceRTM': venceRTM != null ? Timestamp.fromDate(venceRTM!) : null,
      'venceSOAT': venceSOAT != null ? Timestamp.fromDate(venceSOAT!) : null,
      'venceBotiquin': venceBotiquin != null ? Timestamp.fromDate(venceBotiquin!) : null,
      'venceExtintor': venceExtintor != null ? Timestamp.fromDate(venceExtintor!) : null,
      'fotoFrenteUrl': fotoFrenteUrl,
      'fotoTraseraUrl': fotoTraseraUrl,
      'fotoLateralUrl': fotoLateralUrl,
    };
  }

  // Lógica de Alertas
  bool get tieneAlertaRoja {
    final now = DateTime.now();
    final threshold = 10; // días

    int diasPara(DateTime? fecha) {
         if (fecha == null) return 999; // Si no hay fecha, no hay alerta
         final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
         final hoySinHora = DateTime(now.year, now.month, now.day);
         return fechaSinHora.difference(hoySinHora).inDays;
    }

    // Si fecha es nula, diasPara devuelve 999 (> 10), así que no alerta.
    // Si queremos alertar por falta de fecha, cambiar lógica.
    // Asumiremos que null = no dato = no alerta roja (o cambiar si cliente pide)
    
    if (venceRTM != null && diasPara(venceRTM) < threshold) return true;
    if (venceSOAT != null && diasPara(venceSOAT) < threshold) return true;
    if (tipo == 'Carro' && venceExtintor != null && diasPara(venceExtintor) < threshold) return true;
    
    return false;
  }
}
