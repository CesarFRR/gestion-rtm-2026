import 'package:flutter/material.dart';
import '../pages/register_page.dart';

class SideMenu extends StatelessWidget {
  final bool isDrawerPinned;
  final VoidCallback onPinToggle;

  const SideMenu({
    super.key,
    required this.isDrawerPinned,
    required this.onPinToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        isDrawerPinned
                            ? Icons.push_pin
                            : Icons.push_pin_outlined,
                        color: Colors.white,
                      ),
                      tooltip: isDrawerPinned ? 'Desfijar menú' : 'Fijar menú',
                      onPressed: onPinToggle,
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'En línea',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
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
                    // Si no está fijado, cerramos el drawer al navegar naveguemos
                    // (aunque aquí ya estamos en Dashboard)
                    if (!isDrawerPinned) Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Registrar Vehículo'),
                  onTap: () {
                    if (!isDrawerPinned) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                ),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'PRÓXIMOS VENCIMIENTOS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  title: const Text('RTM por vencer'),
                  subtitle: const Text('Menos de 10 días'),
                  onTap: () {
                    if (!isDrawerPinned) Navigator.pop(context);
                    // Aquí iría la lógica de filtro
                  },
                ),

                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    if (!isDrawerPinned) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
