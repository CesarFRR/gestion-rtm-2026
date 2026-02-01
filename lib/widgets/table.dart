import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehiculo_model.dart';
import '../pages/vehiculo_page.dart'; // Importamos la p?gina de detalle
import '../pages/edit_vehiculo_page.dart'; // Importamos la p?gina de edici?n

class VehiculosTable extends StatefulWidget {
  final List<Vehiculo> vehiculos;

  const VehiculosTable({super.key, required this.vehiculos});

  @override
  State<VehiculosTable> createState() => _VehiculosTableState();
}

class _VehiculosTableState extends State<VehiculosTable> {
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    // Creamos una copia para no mutar la lista original del padre
    final sortedVehiculos = List<Vehiculo>.from(widget.vehiculos);
    _sortList(sortedVehiculos);

    final source = VehiculoDataSource(sortedVehiculos, context);

    return SizedBox(
      width: double.infinity,
      child: Theme(
        data: Theme.of(context).copyWith(
          cardColor: Colors.white,
          dividerColor: Colors.grey.withValues(alpha: 50),
        ),
        child: SingleChildScrollView(
          child: PaginatedDataTable(
            header: const Text(
              'Listado de Vehículos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            rowsPerPage: 10,
            availableRowsPerPage: const [5, 10, 20],
            onRowsPerPageChanged: (value) {},
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            columns: [
              DataColumn(
                label: const Text('Placa'),
                onSort: (colIndex, ascending) => _sort(colIndex, ascending),
              ),
              DataColumn(
                label: const Text('Empresa'),
                onSort: (colIndex, ascending) => _sort(colIndex, ascending),
              ),
              DataColumn(
                label: const Text('Tipo'),
                onSort: (colIndex, ascending) => _sort(colIndex, ascending),
              ),
              DataColumn(
                label: const Text('Vence RTM'),
                onSort: (colIndex, ascending) => _sort(colIndex, ascending),
              ),
              DataColumn(
                label: const Text('Vence SOAT'),
                onSort: (colIndex, ascending) => _sort(colIndex, ascending),
              ),
              const DataColumn(label: Text('Acciones')),
            ],
            source: source,
            showCheckboxColumn: false,
          ),
        ),
      ),
    );
  }

  void _sort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _sortList(List<Vehiculo> list) {
    list.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0: // Placa
          cmp = a.placa.compareTo(b.placa);
          break;
        case 1: // Empresa
          cmp = a.empresa.compareTo(b.empresa);
          break;
        case 2: // Tipo
          cmp = a.tipo.compareTo(b.tipo);
          break;
        case 3: // Vence RTM
          if (a.venceRTM == null && b.venceRTM == null) {
            cmp = 0;
          } else if (a.venceRTM == null) {
            cmp = -1;
          } else if (b.venceRTM == null) {
            cmp = 1;
          } else {
            cmp = a.venceRTM!.compareTo(b.venceRTM!);
          }
          break;
        case 4: // Vence SOAT
          if (a.venceSOAT == null && b.venceSOAT == null) {
            cmp = 0;
          } else if (a.venceSOAT == null) {
            cmp = -1;
          } else if (b.venceSOAT == null) {
            cmp = 1;
          } else {
            cmp = a.venceSOAT!.compareTo(b.venceSOAT!);
          }
          break;
        default:
          cmp = a.placa.compareTo(b.placa);
      }
      return _sortAscending ? cmp : -cmp;
    });
  }
}

class VehiculoDataSource extends DataTableSource {
  final List<Vehiculo> vehiculos;
  final BuildContext context;
  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  VehiculoDataSource(this.vehiculos, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= vehiculos.length) return null;
    final vehiculo = vehiculos[index];

    // Cálculo para alerta de RTM (< 10 días).
    bool rtmCritico = false;
    if (vehiculo.venceRTM != null) {
      final now = DateTime.now();
      final diff = vehiculo.venceRTM!.difference(now).inDays;
      if (diff < 10) rtmCritico = true;
    }

    String formatDate(DateTime? date) {
      if (date == null) return '---';
      return dateFormat.format(date);
    }

    // Acci?n para navegar al detalle
    void navigateToDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VehiculoPage(vehiculo: vehiculo)),
      );
    }

    void navigateToEdit() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditVehiculoPage(vehiculo: vehiculo)),
      );
    }

    return DataRow.byIndex(
      index: index,
      cells: [
        // 1. Placa Clickable con Icono de Alerta
        DataCell(
          InkWell(
            onTap: navigateToDetail,
            child: Row(
              children: [
                if (vehiculo.tieneAlertaRoja) ...[
                  Tooltip(
                    message: 'Atención: RTM por vencer',
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  vehiculo.placa,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Empresa normal
        DataCell(Text(vehiculo.empresa)),

        // 3. Tipo con Badge de Color
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: vehiculo.tipo == 'Carro'
                  ? Colors.blue.withValues(alpha: 200)
                  : Colors.green.withValues(alpha: 200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vehiculo.tipo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87, // Letra blanca para mejor contraste
              ),
            ),
          ),
        ),

        // 4. Vence RTM (Rojo si critico)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: rtmCritico
                ? BoxDecoration(
                    color: Colors.red.withValues(alpha: 10),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              formatDate(vehiculo.venceRTM),
              style: TextStyle(
                color: rtmCritico ? Colors.red[900] : null,
                fontWeight: rtmCritico ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),

        // 5. SOAT normal
        DataCell(Text(formatDate(vehiculo.venceSOAT))),

        // 6. Acciones (Ver y Editar)
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: Colors.grey,
                ),
                tooltip: 'Ver detalle',
                splashRadius: 20,
                onPressed: navigateToDetail,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                tooltip: 'Editar',
                splashRadius: 20,
                onPressed: navigateToEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => vehiculos.length;

  @override
  int get selectedRowCount => 0;
}
