import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../pages/register_page.dart';
import '../services/auth_service.dart';
import '../pages/config_page.dart';

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
    // 1. OBTENER USUARIO ACTUAL
    final User? user =
        AuthService().currentUser ?? FirebaseAuth.instance.currentUser;
    // Detectar si es pantalla pequeña (móvil)
    final bool isMobile = MediaQuery.sizeOf(context).width < 800;
    final AuthService _authService = AuthService();

    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // Header Azul
          Container(
            height: 160,
            width: double.infinity,
            color: Colors.blueAccent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        if (!isMobile)
                          IconButton(
                            icon: Icon(
                              isDrawerPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color: Colors.white,
                            ),
                            tooltip: isDrawerPinned
                                ? 'Desfijar menú'
                                : 'Fijar menú',
                            onPressed: onPinToggle,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 2. SECCIÓN DE USUARIO DINÁMICA
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white24,
                          // Si hay foto en Google, úsala. Si no, icono por defecto
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          // Usamos Expanded para evitar overflow si el email es largo
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Mostrar nombre o parte del email, o 'Usuario' por defecto
                                user?.displayName ??
                                    user?.email?.split('@')[0] ??
                                    'Usuario',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                // Mostrar email completo
                                user?.email ?? 'Sin sesión',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
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
                    // Acción de filtro...
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración'),
                  onTap: () {
                    if (!isDrawerPinned) Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfigPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('¿Cerrar Sesión?'),
                        content: const Text(
                          '¿Estás seguro de que quieres salir?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Salir',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true) {
                      await _authService.signOut();

                      if (context.mounted) {
                        // Eliminamos todas las rutas de la pila y vamos a la pantalla inicial
                        // Esto hará que main.dart se vuelva a ejecutar o que AuthPage sea montado nuevamente
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (route) => false);
                      }
                    }
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
