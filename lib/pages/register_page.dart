import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/vehiculo_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y estado
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _empresaController = TextEditingController();

  String _tipoSeleccionado = 'Carro'; // Por defecto

  DateTime? _fechaMatricula;
  DateTime? _venceRTM;
  DateTime? _venceSOAT;
  DateTime? _venceBotiquin;
  DateTime? _venceExtintor;

  // Archivos de imagen (XFile soporta web y móvil)
  XFile? _fotoFrente;
  XFile? _fotoTrasera;
  XFile? _fotoLateral;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(String section) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (section == 'frente') _fotoFrente = image;
        if (section == 'trasera') _fotoTrasera = image;
        if (section == 'lateral') _fotoLateral = image;
      });
    }
  }

  Future<DateTime?> _selectDate(
    BuildContext context,
    DateTime? initialDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    return picked;
  }

  Future<String?> _uploadImage(XFile? file) async {
    if (file == null) return null;

    try {
      // Usar bytes para compatibilidad Web/Móvil
      Uint8List fileBytes = await file.readAsBytes();
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      Reference ref = FirebaseStorage.instance.ref().child(
        'vehiculos/$fileName',
      );

      // Metadata para el tipo de contenido (opcional pero recomendado)
      SettableMetadata metadata = SettableMetadata(contentType: file.mimeType);

      UploadTask task = ref.putData(fileBytes, metadata);

      TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error subiendo imagen: $e')));
      return null;
    }
  }

  Future<void> _guardarVehiculo() async {
    if (_formKey.currentState!.validate()) {
      // Validaciones adicionales de fechas requeridas
      if (_fechaMatricula == null || _venceRTM == null || _venceSOAT == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor completa las fechas obligatorias (Matrícula, RTM, SOAT).',
            ),
          ),
        );
        return;
      }

      if (_tipoSeleccionado == 'Carro') {
        if (_venceBotiquin == null || _venceExtintor == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Para Carros, Botiquín y Extintor son obligatorios.',
              ),
            ),
          );
          return;
        }
      }

      setState(() => _isUploading = true);

      try {
        // Subir fotos
        String? frenteUrl = await _uploadImage(_fotoFrente);
        String? traseraUrl = await _uploadImage(_fotoTrasera);
        String? lateralUrl = await _uploadImage(_fotoLateral);

        final nuevoVehiculo = Vehiculo(
          id: '', // Firestore generará el ID
          placa: _placaController.text.toUpperCase(),
          empresa: _empresaController.text,
          tipo: _tipoSeleccionado,
          fechaMatricula: _fechaMatricula!,
          venceRTM: _venceRTM!,
          venceSOAT: _venceSOAT!,
          venceBotiquin: _venceBotiquin,
          venceExtintor: _venceExtintor,
          fotoFrenteUrl: frenteUrl,
          fotoTraseraUrl: traseraUrl,
          fotoLateralUrl: lateralUrl,
        );

        await FirebaseFirestore.instance
            .collection('vehiculos')
            .add(nuevoVehiculo.toMap());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehículo registrado con éxito')),
          );
          Navigator.pop(context); // Volver al Dashboard
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  // Widget auxiliar para selección de fecha
  Widget _buildDateField(
    String label,
    DateTime? selectedDate,
    Function(DateTime) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final date = await _selectDate(context, selectedDate);
          if (date != null) {
            onSelected(date);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            selectedDate == null
                ? 'Seleccionar fecha'
                : DateFormat('yyyy-MM-dd').format(selectedDate),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para selección de imagen
  Widget _buildImagePicker(String label, XFile? file, Function() onTap) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: file == null
                ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                : kIsWeb
                ? Image.network(
                    file.path,
                    fit: BoxFit.cover,
                  ) // Previsualización Web simple
                : Image.file(File(file.path), fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Vehículo')),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tipo de Vehículo
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Carro'),
                            value: 'Carro',
                            groupValue: _tipoSeleccionado,
                            onChanged: (v) =>
                                setState(() => _tipoSeleccionado = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Moto'),
                            value: 'Moto',
                            groupValue: _tipoSeleccionado,
                            onChanged: (v) =>
                                setState(() => _tipoSeleccionado = v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _placaController,
                      decoration: const InputDecoration(
                        labelText: 'Placa',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _empresaController,
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Campo requerido' : null,
                    ),

                    const SizedBox(height: 16),
                    _buildDateField(
                      'Fecha Matrícula',
                      _fechaMatricula,
                      (d) => setState(() => _fechaMatricula = d),
                    ),
                    _buildDateField(
                      'Vence RTM',
                      _venceRTM,
                      (d) => setState(() => _venceRTM = d),
                    ),
                    _buildDateField(
                      'Vence SOAT',
                      _venceSOAT,
                      (d) => setState(() => _venceSOAT = d),
                    ),

                    if (_tipoSeleccionado == 'Carro') ...[
                      _buildDateField(
                        'Vence Botiquín',
                        _venceBotiquin,
                        (d) => setState(() => _venceBotiquin = d),
                      ),
                      _buildDateField(
                        'Vence Extintor',
                        _venceExtintor,
                        (d) => setState(() => _venceExtintor = d),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Text(
                      'Fotos del Vehículo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImagePicker(
                          'Frente',
                          _fotoFrente,
                          () => _pickImage('frente'),
                        ),
                        _buildImagePicker(
                          'Trasera',
                          _fotoTrasera,
                          () => _pickImage('trasera'),
                        ),
                        _buildImagePicker(
                          'Lateral',
                          _fotoLateral,
                          () => _pickImage('lateral'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _guardarVehiculo,
                      child: const Text(
                        'GUARDAR VEHÍCULO',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
