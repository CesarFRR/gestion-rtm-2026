import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // REMOVED
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/vehiculo_model.dart';
import '../services/cloudinary_service.dart';

class EditVehiculoPage extends StatefulWidget {
  final Vehiculo vehiculo;
  const EditVehiculoPage({super.key, required this.vehiculo});

  @override
  State<EditVehiculoPage> createState() => _EditVehiculoPageState();
}

class _EditVehiculoPageState extends State<EditVehiculoPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  late TextEditingController _placaController;

  // Dropdown empresas
  final List<String> _empresas = [
    'Molinos Morichal',
    'Distriofertas',
    'La Buena Arepa',
  ];
  String? _empresaSeleccionada;

  late String _tipoSeleccionado;

  DateTime? _fechaMatricula;
  DateTime? _venceRTM;
  DateTime? _venceSOAT;
  DateTime? _venceBotiquin;
  DateTime? _venceExtintor;
  DateTime? _venceTodoRiesgo;

  // Archivos de imagen NUEVOS
  XFile? _fotoFrente;
  XFile? _fotoTrasera;
  XFile? _fotoLateralDerecho;
  XFile? _fotoLateralIzquierdo;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Inicializar con los datos del vehículo
    _placaController = TextEditingController(text: widget.vehiculo.placa);
    _empresaSeleccionada = widget.vehiculo.empresa;
    _tipoSeleccionado = widget.vehiculo.tipo;
    _fechaMatricula = widget.vehiculo.fechaMatricula;
    _venceRTM = widget.vehiculo.venceRTM;
    _venceSOAT = widget.vehiculo.venceSOAT;
    _venceBotiquin = widget.vehiculo.venceBotiquin;
    _venceExtintor = widget.vehiculo.venceExtintor;
    _venceTodoRiesgo = widget.vehiculo.venceTodoRiesgo;
  }

  @override
  void dispose() {
    _placaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String section) async {
    // Mostrar selector de fuente (Cámara o Galería)
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galería'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Cámara'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Optimización opcional
      );
      if (image != null) {
        setState(() {
          if (section == 'frente') _fotoFrente = image;
          if (section == 'trasera') _fotoTrasera = image;
          if (section == 'lateral_derecho') _fotoLateralDerecho = image;
          if (section == 'lateral_izquierdo') _fotoLateralIzquierdo = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al acceder a la cámara/galería: $e')),
        );
      }
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
      final url = await CloudinaryService.uploadImage(
        file,
        _placaController.text.toUpperCase(),
        file == _fotoFrente
            ? 'frente'
            : file == _fotoTrasera
            ? 'trasera'
            : file == _fotoLateralDerecho
            ? 'lateral_derecho'
            : 'lateral_izquierdo',
      );

      // Si CloudinaryService retorna null (fallo controlado), lanzamos excepci?n
      // para que _guardarVehiculo detenga el proceso.
      if (url == null) {
        throw Exception('Error al subir imagen a Cloudinary (URL vac?a)');
      }
      return url;
    } catch (e) {
      // Si ocurre cualquier error (excepci?n o error controlado arriba),
      // lo relanzamos (rethrow) para que el try-catch de _guardarVehiculo
      // capture el fallo y NO guarde nada en Firestore.
      debugPrint('Fallo cr?tico en subida de imagen: $e');
      rethrow;
    }
  }

  Future<void> _guardarVehiculo() async {
    if (_formKey.currentState!.validate()) {
      // Validaciones adicionales
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

      setState(() => _isUploading = true);

      try {
        // 1. Guardar referencia a las URLs antiguas antes de reemplazarlas
        final String? oldFrente = widget.vehiculo.fotoFrenteUrl;
        final String? oldTrasera = widget.vehiculo.fotoTraseraUrl;
        final String? oldLatDer = widget.vehiculo.fotoLateralDerechoUrl;
        final String? oldLatIzq = widget.vehiculo.fotoLateralIzquierdoUrl;

        // 2. Subir fotos nuevas (si existen)
        String? frenteUrl = _fotoFrente != null
            ? await _uploadImage(_fotoFrente)
            : oldFrente;

        String? traseraUrl = _fotoTrasera != null
            ? await _uploadImage(_fotoTrasera)
            : oldTrasera;

        String? lateralDerUrl = _fotoLateralDerecho != null
            ? await _uploadImage(_fotoLateralDerecho)
            : oldLatDer;

        String? lateralIzqUrl = _fotoLateralIzquierdo != null
            ? await _uploadImage(_fotoLateralIzquierdo)
            : oldLatIzq;

        final vehiculoEditado = Vehiculo(
          id: widget.vehiculo.id,
          placa: _placaController.text.toUpperCase(),
          empresa: _empresaSeleccionada!,
          tipo: _tipoSeleccionado,
          fechaMatricula: _fechaMatricula!,
          venceRTM: _venceRTM!,
          venceSOAT: _venceSOAT!,
          venceBotiquin: _venceBotiquin,
          venceExtintor: _venceExtintor,
          venceTodoRiesgo: _venceTodoRiesgo,
          fotoFrenteUrl: frenteUrl,
          fotoTraseraUrl: traseraUrl,
          fotoLateralDerechoUrl: lateralDerUrl,
          fotoLateralIzquierdoUrl: lateralIzqUrl,
        );

        // 3. Actualizar Firestore
        // Si la placa cambió, borramos el documento viejo
        if (_placaController.text.toUpperCase() != widget.vehiculo.placa) {
          await FirebaseFirestore.instance
              .collection('vehiculos')
              .doc(widget.vehiculo.placa)
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('vehiculos')
            .doc(vehiculoEditado.placa)
            .set(vehiculoEditado.toMap());

        // 4. SOLO SI FIRESTORE TUVO ÉXITO: Intentar borrar las imágenes viejas de Cloudinary
        // Solo si fueron reemplazadas por algo nuevo
        if (_fotoFrente != null && oldFrente != null) {
          CloudinaryService.deleteImage(oldFrente);
        }
        if (_fotoTrasera != null && oldTrasera != null) {
          CloudinaryService.deleteImage(oldTrasera);
        }
        if (_fotoLateralDerecho != null && oldLatDer != null) {
          CloudinaryService.deleteImage(oldLatDer);
        }
        if (_fotoLateralIzquierdo != null && oldLatIzq != null) {
          CloudinaryService.deleteImage(oldLatIzq);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehículo actualizado con éxito')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

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
            filled: true,
            fillColor: Colors.grey[50],
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

  Widget _buildImagePicker(
    String label,
    XFile? file,
    String? networkUrl,
    Function() onTap,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: file != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(file.path, fit: BoxFit.cover)
                        : Image.file(File(file.path), fit: BoxFit.cover),
                  )
                : networkUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(networkUrl, fit: BoxFit.cover),
                  )
                : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Manejo manual para suavidad extrema
      appBar: AppBar(title: const Text('Editar Vehículo'), centerTitle: true),
      body: SafeArea(
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      // Padding fijo generoso abajo para permitir scroll manual sobre el teclado
                      // sin causar rebuilds ni animaciones de redimensionamiento (Jank-Free)
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 300),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // --- Sección 1: Información Básica ---
                            const Text(
                              'Información General',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(child: _buildRadioTile('Carro')),
                                Expanded(child: _buildRadioTile('Moto')),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Fila: Placa y Empresa
                            if (MediaQuery.sizeOf(context).width < 800)
                              Column(
                                children: [
                                  TextFormField(
                                    controller: _placaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Placa',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                    ),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requerido' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  DropdownButtonFormField<String>(
                                    value: _empresaSeleccionada,
                                    isExpanded:
                                        true, // Importante para evitar overflow en dropdown
                                    items: _empresas.map((e) {
                                      return DropdownMenuItem(
                                        value: e,
                                        child: Text(
                                          e,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setState(
                                      () => _empresaSeleccionada = val,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Empresa',
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      isDense: true,
                                    ),
                                    validator: (v) => v == null
                                        ? 'Selecciona una empresa'
                                        : null,
                                  ),
                                ],
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _placaController,
                                      decoration: const InputDecoration(
                                        labelText: 'Placa',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                      ),
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      validator: (v) =>
                                          v!.isEmpty ? 'Requerido' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _empresaSeleccionada,
                                      isExpanded: true,
                                      items: _empresas.map((e) {
                                        return DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(
                                        () => _empresaSeleccionada = val,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Empresa',
                                        border: OutlineInputBorder(),
                                        filled: true,
                                      ),
                                      validator: (v) => v == null
                                          ? 'Selecciona una empresa'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 32),

                            // --- Sección 2: Fechas y Vencimientos ---
                            const Text(
                              'Vencimientos',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),

                            _buildDateField(
                              'Fecha de Matrícula',
                              _fechaMatricula,
                              (d) => setState(() => _fechaMatricula = d),
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    'Vence RTM',
                                    _venceRTM,
                                    (d) => setState(() => _venceRTM = d),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    'Vence SOAT',
                                    _venceSOAT,
                                    (d) => setState(() => _venceSOAT = d),
                                  ),
                                ),
                              ],
                            ),

                            if (_tipoSeleccionado == 'Carro') ...[
                              if (MediaQuery.sizeOf(context).width < 800)
                                Column(
                                  children: [
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
                                    _buildDateField(
                                      'Vence Todo Riesgo',
                                      _venceTodoRiesgo,
                                      (d) =>
                                          setState(() => _venceTodoRiesgo = d),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildDateField(
                                        'Vence Botiquín',
                                        _venceBotiquin,
                                        (d) =>
                                            setState(() => _venceBotiquin = d),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDateField(
                                        'Vence Extintor',
                                        _venceExtintor,
                                        (d) =>
                                            setState(() => _venceExtintor = d),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildDateField(
                                        'Vence Todo Riesgo',
                                        _venceTodoRiesgo,
                                        (d) => setState(
                                          () => _venceTodoRiesgo = d,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],

                            const SizedBox(height: 32),

                            // --- Sección 3: Evidencia Fotográfica ---
                            const Text(
                              'Evidencia Fotográfica',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            const SizedBox(height: 16),

                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildImagePicker(
                                  'Frente',
                                  _fotoFrente,
                                  widget.vehiculo.fotoFrenteUrl,
                                  () => _pickImage('frente'),
                                ),
                                _buildImagePicker(
                                  'Trasera',
                                  _fotoTrasera,
                                  widget.vehiculo.fotoTraseraUrl,
                                  () => _pickImage('trasera'),
                                ),
                                _buildImagePicker(
                                  'Lat. Derecho',
                                  _fotoLateralDerecho,
                                  widget.vehiculo.fotoLateralDerechoUrl,
                                  () => _pickImage('lateral_derecho'),
                                ),
                                _buildImagePicker(
                                  'Lat. Izquierdo',
                                  _fotoLateralIzquierdo,
                                  widget.vehiculo.fotoLateralIzquierdoUrl,
                                  () => _pickImage('lateral_izquierdo'),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),
                            Center(
                              child: SizedBox(
                                width: 250,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _guardarVehiculo,
                                  child: const Text(
                                    'ACTUALIZAR VEHÍCULO',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRadioTile(String value) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      groupValue: _tipoSeleccionado,
      activeColor: Colors.blueAccent,
      onChanged: (v) => setState(() => _tipoSeleccionado = v!),
      contentPadding: EdgeInsets.zero,
    );
  }
}
