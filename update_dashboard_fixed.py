
import os

content = r'''import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isDrawerPinned = false; // Estado del menú fijado

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDrawerPinned = prefs.getBool('isDrawerPinned') ?? false;
    });
  }

  Future<void> _togglePin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDrawerPinned = !_isDrawerPinned;
    });
    await prefs.setBool('isDrawerPinned', _isDrawerPinned);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // 1. Definición del Menú Lateral (SideMenu) con Estilo Mejorado
    // -------------------------------------------------------------------------
    final sideMenu = Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // Header Azul con opción de fijar (PIN)
          Container(
            height: 160,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blueAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gestión RTM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isDrawerPinned ? Icons.push_pin : Icons.push_pin_outlined,
                        color: Colors.white,
                      ),
                      tooltip: _isDrawerPinned ? 'Desfijar menú' : 'Fijar menú',
                      onPressed: () {
                         _togglePin();
                         // Si es modal (no fijado) y lo estamos fijando, no hacemos pop.
                         // Pero si estamos en modal y pinchamos para fijar/desfijar...
                         // La lógica simple es: toggle y ya. El usuario decide cerrar si quiere.
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sección de Usuario
                Row(
                  children: const [
                     CircleAvatar(
                       backgroundColor: Colors.white24,
                       child: Icon(Icons.person, color: Colors.white),
                     ),
                     SizedBox(width: 12),
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Administrador',
                           style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                         ),
                         Text(
                           'En línea',
                           style: TextStyle(color: Colors.white70, fontSize: 12),
                         ),
                       ],
                     )
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de Opciones
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  selected: true,
                  onTap: () {
                    if (!_isDrawerPinned) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Registrar Vehículo'),
                  onTap: () {
                    // Acción de navegar
                    if (!_isDrawerPinned) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                ),
                
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'PRÓXIMOS VENCIMIENTOS',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                   leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                   title: const Text('RTM por vencer'),
                   subtitle: const Text('Menos de 10 días'),
                   onTap: () {
                      if (!_isDrawerPinned) Navigator.pop(context);
                      // Filtro futuro
                   },
                ),
                
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    if (!_isDrawerPinned) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // -------------------------------------------------------------------------
    // 2. Contenido Principal (MainContent) basado en la versión ESTABLE
    // -------------------------------------------------------------------------
    final mainContent = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100), // Mantengo el ancho que funcionaba
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de Página (Breadcrumb style)
            const Text(
              'Panel de Control',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Vista general de la flota', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // Buscador Global (Estilizado)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Buscar (Placa, Empresa, Tipo)',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Tabla Paginada (Estructura ESTABLE con Visual Mejorado)
            Expanded(
              child: Card( // Card wrapper para elevación visual
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('vehiculos').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error al cargar datos'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    List<Vehiculo> vehiculos = docs.map((d) => Vehiculo.fromFirestore(d)).toList();

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

                    // USO LA ESTRUCTURA EXACTA QUE FUNCIONABA BIEN:
                    return SizedBox(
                      width: double.infinity,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          cardColor: Colors.white,
                          dividerColor: Colors.grey.withOpacity(0.2),
                        ),
                        child: SingleChildScrollView(
                          child: PaginatedDataTable(
                            header: const Text('Listado de Vehículos', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // -------------------------------------------------------------------------
    // 3. Selección de Layout (Row Fijo vs Scaffold Normal)
    // -------------------------------------------------------------------------
    if (_isDrawerPinned) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Row(
          children: [
            sideMenu, // Menú siempre visible a la izquierda
            Expanded(child: mainContent), // Contenido a la derecha
          ],
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
    } else {
      // Layout Móvil / Sin Pin
      return Scaffold(
        backgroundColor: Colors.grey[50], // Fondo gris suave
        appBar: AppBar(
          title: const Text('Dashboard Flota'),
          centerTitle: true,
          elevation: 0,
        ),
        drawer: Drawer(child: sideMenu),
        body: mainContent,
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
          if (a.venceRTM == null && b.venceRTM == null) cmp = 0;
          else if (a.venceRTM == null) cmp = -1;
          else if (b.venceRTM == null) cmp = 1;
          else cmp = a.venceRTM!.compareTo(b.venceRTM!);
          break;
        case 4: // Vence SOAT
          if (a.venceSOAT == null && b.venceSOAT == null) cmp = 0;
          else if (a.venceSOAT == null) cmp = -1;
          else if (b.venceSOAT == null) cmp = 1;
          else cmp = a.venceSOAT!.compareTo(b.venceSOAT!);
          break;
        default:
          cmp = a.placa.compareTo(b.placa);
      }
      return _sortAscending ? cmp : -cmp;
    });
  }
}

// -------------------------------------------------------------------------
// 4. DataSource con Estilo Mejorado (Iconos, Clickable, Badges)
// -------------------------------------------------------------------------
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

    // Acción para navegar al detalle
    void navigateToDetail() {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Navegando a detalle: /vehicle/${vehiculo.placa}')),
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
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
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
               color: vehiculo.tipo == 'Carro' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: vehiculo.tipo == 'Carro' ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
             ),
             child: Text(
               vehiculo.tipo, 
               style: TextStyle(
                 fontWeight: FontWeight.bold,
                 fontSize: 12, 
                 color: vehiculo.tipo == 'Carro' ? Colors.blue[800] : Colors.green[800]
               ),
             ),
           )
        ),

        // 4. Vence RTM (Rojo si critico)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: rtmCritico ? BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ) : null,
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
                icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.grey),
                tooltip: 'Ver detalle',
                splashRadius: 20,
                onPressed: navigateToDetail,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                tooltip: 'Editar',
                splashRadius: 20,
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
'''

with open(r'c:\Users\Cesar_R\dev\gestion_rtm_2026\lib\pages\dashboard_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
