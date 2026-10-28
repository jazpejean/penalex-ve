import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';
import '../services/role_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/role_guard.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_bar_institucional.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await RoleService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    
    return _users.where((user) {
      final name = (user['name'] as String? ?? '').toLowerCase();
      final email = (user['email'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _changeUserRole(String userId, String userName, UserRole currentRole) async {
    UserRole? selectedRole = currentRole;

    final result = await showDialog<UserRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Cambiar rol de $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ignore: deprecated_member_use
            RadioListTile<UserRole>(
                title: Row(
                  children: [
                    Text(RoleService.getRoleIcon(UserRole.admin)),
                    const SizedBox(width: 8),
                    const Text('Administrador'),
                  ],
                ),
                subtitle: const Text('Acceso total al sistema'),
                value: UserRole.admin,
                // ignore: deprecated_member_use
                groupValue: selectedRole,
                // ignore: deprecated_member_use
                onChanged: (value) => setDialogState(() => selectedRole = value),
              ),
              // ignore: deprecated_member_use
              RadioListTile<UserRole>(
                title: Row(
                  children: [
                    Text(RoleService.getRoleIcon(UserRole.moderator)),
                    const SizedBox(width: 8),
                    const Text('Moderador'),
                  ],
                ),
                subtitle: const Text('Gestiona glosario y contenido'),
                value: UserRole.moderator,
                // ignore: deprecated_member_use
                groupValue: selectedRole,
                // ignore: deprecated_member_use
                onChanged: (value) => setDialogState(() => selectedRole = value),
              ),
              // ignore: deprecated_member_use
              RadioListTile<UserRole>(
                title: Row(
                  children: [
                    Text(RoleService.getRoleIcon(UserRole.user)),
                    const SizedBox(width: 8),
                    const Text('Usuario'),
                  ],
                ),
                subtitle: const Text('Acceso estándar'),
                value: UserRole.user,
                // ignore: deprecated_member_use
                groupValue: selectedRole,
                // ignore: deprecated_member_use
                onChanged: (value) => setDialogState(() => selectedRole = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulMarino,
                foregroundColor: AppColors.onAzulMarino,
              ),
              onPressed: () => Navigator.pop(context, selectedRole),
              child: Text('Cambiar'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != currentRole) {
      setState(() => _isLoading = true);
      
      final success = await RoleService.updateUserRole(userId, result);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rol actualizado a ${RoleService.getRoleDisplayName(result)}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        await _loadUsers();
      } else {
        if (mounted) {
          AppSnackBar.error(context, 'Error al actualizar el rol');
        }
      }
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleProtectedPage(
      requiredRole: UserRole.admin,
      child: Scaffold(
        drawer: const AppDrawer(currentRoute: '/admin_users'),
              appBar: AppBarInstitucional(
        title: 'Gestión de Usuarios',
        mostrarBack: true,
        mostrarHome: true,
      ),
        body: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: TemaGlobal.campoTexto,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Lista de usuarios
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: TemaGlobal.textoTenue,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No hay usuarios registrados'
                                    : 'No se encontraron usuarios',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: TemaGlobal.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final role = user['role'] as UserRole;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(role),
                                  child: Text(
                                    RoleService.getRoleIcon(role),
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                title: Text(
                                  user['name'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      user['email'] ?? 'Sin email',
                                      style: TextStyle(
                                        color: TemaGlobal.textoSecundario,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(role).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getRoleColor(role),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        RoleService.getRoleDisplayName(role),
                                        style: TextStyle(
                                          color: _getRoleColor(role),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  color: TemaGlobal.textoSecundario,
                                  onPressed: () => _changeUserRole(
                                    user['uid'] as String,
                                    user['name'] as String? ?? 'Usuario',
                                    role,
                                  ),
                                  tooltip: 'Cambiar rol',
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.moderator:
        return Colors.blue;
      case UserRole.user:
        return Colors.grey;
    }
  }
}
