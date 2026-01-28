import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/vehiculo_model.dart';
import 'register_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Flota'), centerTitle: true),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                'Gestión RTM Flota',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Registrar Vehículo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                // Implementación futura
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Buscador Global
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar (Placa, Empresa, Tipo)',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Tabla Paginada
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('vehiculos')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar datos'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    List<Vehiculo> vehiculos = docs
                        .map((d) => Vehiculo.fromFirestore(d))
                        .toList();

                    // Filtrado
                    if (_searchQuery.isNotEmpty) {
                      vehiculos = vehiculos.where((v) {
                        return (v.placa.toLowerCase()).contains(_searchQuery) ||
                            (v.empresa.toLowerCase()).contains(_searchQuery) ||
                            (v.tipo.toLowerCase()).contains(_searchQuery);
                      }).toList();
                    }

                    // Ordenamiento
                    _sortList(vehiculos);

                    final source = VehiculoDataSource(vehiculos, context);

                    return SizedBox(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        child: PaginatedDataTable(
                          header: const Text('Listado de Vehículos'),
                          rowsPerPage: 10,
                          availableRowsPerPage: const [5, 10, 20],
                          onRowsPerPageChanged: (value) {
                            // Aquí podrías manejar estado de filas por página si quisieras
                          },
                          sortColumnIndex: _sortColumnIndex,
                          sortAscending: _sortAscending,
                          columns: [
                            DataColumn(
                              label: const Text('Placa'),
                              onSort: (colIndex, ascending) =>
                                  _sort(colIndex, ascending),
                            ),
                            DataColumn(
                              label: const Text('Empresa'),
                              onSort: (colIndex, ascending) =>
                                  _sort(colIndex, ascending),
                            ),
                            DataColumn(
                              label: const Text('Tipo'),
                              onSort: (colIndex, ascending) =>
                                  _sort(colIndex, ascending),
                            ),
                            DataColumn(
                              label: const Text('Vence RTM'),
                              onSort: (colIndex, ascending) =>
                                  _sort(colIndex, ascending),
                            ),
                            DataColumn(
                              label: const Text('Vence SOAT'),
                              onSort: (colIndex, ascending) =>
                                  _sort(colIndex, ascending),
                            ),
                            const DataColumn(label: Text('Acciones')),
                          ],
                          source: source,
                          showCheckboxColumn: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterPage()),
          );
        },
        child: const Icon(Icons.add),
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
        case 3: // Vence RTM
          if (a.venceRTM == null && b.venceRTM == null)
            cmp = 0;
          else if (a.venceRTM == null)
            cmp = -1;
          else if (b.venceRTM == null)
            cmp = 1;
          else
            cmp = a.venceRTM!.compareTo(b.venceRTM!);
          break;
        case 4: // Vence SOAT
          if (a.venceSOAT == null && b.venceSOAT == null)
            cmp = 0;
          else if (a.venceSOAT == null)
            cmp = -1;
          else if (b.venceSOAT == null)
            cmp = 1;
          else
            cmp = a.venceSOAT!.compareTo(b.venceSOAT!);
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
    // Si la fecha es null, rtmCritico es false.
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

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          Row(
            children: [
              if (vehiculo.tieneAlertaRoja) ...[
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                vehiculo.placa,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DataCell(Text(vehiculo.empresa)),
        DataCell(Text(vehiculo.tipo)),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: rtmCritico
                ? BoxDecoration(
                    color: Colors.red.withOpacity(0.2), // Rojo suave
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
        DataCell(Text(formatDate(vehiculo.venceSOAT))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Editar',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Editar ${vehiculo.placa}')),
                  );
                },
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
