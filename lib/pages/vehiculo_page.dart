import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehiculo_model.dart';
import 'edit_vehiculo_page.dart';

class VehiculoPage extends StatelessWidget {
  final Vehiculo vehiculo;

  const VehiculoPage({super.key, required this.vehiculo});

  @override
  Widget build(BuildContext context) {
    void navigateToEdit() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditVehiculoPage(vehiculo: vehiculo)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${vehiculo.placa}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildVencimientosCard(),
            const SizedBox(height: 16),
            _buildFotosCard(context),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: navigateToEdit,
              child: const Text('Editar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildRow('Placa', vehiculo.placa, isBold: true),
            _buildRow('Empresa', vehiculo.empresa),
            _buildRow('Tipo', vehiculo.tipo),
            _buildRow('Fecha Matrícula', _formatDate(vehiculo.fechaMatricula)),
          ],
        ),
      ),
    );
  }

  Widget _buildVencimientosCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vencimientos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDateRow('RTM', vehiculo.venceRTM),
            _buildDateRow('SOAT', vehiculo.venceSOAT),
            if (vehiculo.tipo == 'Carro') ...[
              _buildDateRow('Botiquín', vehiculo.venceBotiquin),
              _buildDateRow('Extintor', vehiculo.venceExtintor),
              _buildDateRow('Todo Riesgo', vehiculo.venceTodoRiesgo),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFotosCard(BuildContext context) {
    final fotos = [
      {'label': 'Frente', 'url': vehiculo.fotoFrenteUrl},
      {'label': 'Trasera', 'url': vehiculo.fotoTraseraUrl},
      {'label': 'Lateral Der.', 'url': vehiculo.fotoLateralDerechoUrl},
      {'label': 'Lateral Izq.', 'url': vehiculo.fotoLateralIzquierdoUrl},
    ].where((f) => f['url'] != null).toList();

    if (fotos.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evidencia Fotográfica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: fotos
                  .map((f) => _buildFotoItem(context, f['label']!, f['url']!))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoItem(BuildContext context, String label, String url) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showFullImage(context, url),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              image: DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: Image.network(url, fit: BoxFit.contain)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, DateTime? date) {
    if (date == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diasRestantes = date.difference(now).inDays;
    Color color = Colors.black;
    if (diasRestantes < 0) {
      color = Colors.red;
    } else if (diasRestantes < 30) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(
                _formatDate(date),
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 8),
              _buildStatusIcon(diasRestantes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(int days) {
    if (days < 0) return const Icon(Icons.error, color: Colors.red, size: 16);
    if (days < 30) {
      return const Icon(Icons.warning, color: Colors.orange, size: 16);
    }
    return const Icon(Icons.check_circle, color: Colors.green, size: 16);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '---';
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
