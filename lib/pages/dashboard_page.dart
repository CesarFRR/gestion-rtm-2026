import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vehiculo_model.dart';
import '../widgets/sidebar.dart';
import '../widgets/table.dart';
import 'register_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
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
    final sideMenu = SideMenu(
      isDrawerPinned: _isDrawerPinned,
      onPinToggle: _togglePin,
    );

    // -------------------------------------------------------------------------
    // 2. Contenido Principal (MainContent) basado en la versión ESTABLE
    // -------------------------------------------------------------------------
    final mainContent = Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 1100,
        ), // Mantengo el ancho que funcionaba
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
            const Text(
              'Vista general de los vehículos',
              style: TextStyle(color: Colors.grey),
            ),
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Tabla Paginada (Modularizada)
            Expanded(
              child: Card(
                // Card wrapper para elevación visual
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
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

                    // Filtrado (se mantiene en el Dashboard porque el buscador es externo)
                    if (_searchQuery.isNotEmpty) {
                      vehiculos = vehiculos.where((v) {
                        return (v.placa.toLowerCase()).contains(_searchQuery) ||
                            (v.empresa.toLowerCase()).contains(_searchQuery) ||
                            (v.tipo.toLowerCase()).contains(_searchQuery);
                      }).toList();
                    }

                    // Renderizado de tabla modularizada
                    // El ordenamiento ahora es manejado internamente por VehiculosTable
                    return VehiculosTable(vehiculos: vehiculos);
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
}
