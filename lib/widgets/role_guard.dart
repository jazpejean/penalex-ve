import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/role_service.dart';
import '../config/app_colors.dart';
import '../widgets/app_bar_institucional.dart';

/// Widget que protege contenido según el rol del usuario
class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.requiredRole,
    required this.child,
    this.fallback,
    this.showAccessDenied = true,
  });

  final UserRole requiredRole;
  final Widget child;
  final Widget? fallback;
  final bool showAccessDenied;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: RoleService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return _buildAccessDenied(context);
        }

        final userRole = snapshot.data!;
        final hasAccess = _checkAccess(userRole);

        if (hasAccess) {
          return child;
        }

        return fallback ?? 
          (showAccessDenied ? _buildAccessDenied(context) : const SizedBox.shrink());
      },
    );
  }

  bool _checkAccess(UserRole userRole) {
    // Admin tiene acceso a todo
    if (userRole == UserRole.admin) return true;

    // Moderator tiene acceso a contenido de moderator y user
    if (requiredRole == UserRole.moderator && userRole == UserRole.moderator) {
      return true;
    }

    // User tiene acceso solo a contenido user
    if (requiredRole == UserRole.user) return true;

    return false;
  }

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
            appBar: AppBarInstitucional(
        title: 'Acceso Denegado',
        mostrarBack: true,

      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.error,
              ),
              const SizedBox(height: 24),
              const Text(
                'Acceso Restringido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No tienes permisos para acceder a esta sección.\nSe requiere rol: ${RoleService.getRoleDisplayName(requiredRole)}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: TemaGlobal.textoSecundario),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.azulMarino,
                  foregroundColor: AppColors.dorado,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget que muestra u oculta contenido según permisos
class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final String permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: RoleService.hasPermission(permission),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Wrapper para páginas completas que requieren un rol específico
class RoleProtectedPage extends StatelessWidget {
  const RoleProtectedPage({
    super.key,
    required this.requiredRole,
    required this.child,
  });

  final UserRole requiredRole;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: requiredRole,
      child: child,
      showAccessDenied: true,
    );
  }
}
