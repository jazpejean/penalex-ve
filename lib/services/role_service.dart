import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Roles disponibles en la aplicación
enum UserRole {
  user,        // Usuario estándar
  admin,       // Administrador con acceso total
  moderator,   // Moderador (puede gestionar glosario y jurisprudencia)
}

/// Servicio para gestión de roles de usuarios
class RoleService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Caché local del rol del usuario actual
  static UserRole? _cachedRole;
  static String? _cachedUserId;

  /// Obtiene el rol del usuario actual
  static Future<UserRole> getUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('🔒 RoleService: Usuario no autenticado');
        return UserRole.user;
      }

      // Usar caché si es el mismo usuario
      if (_cachedUserId == user.uid && _cachedRole != null) {
        debugPrint('🔒 RoleService: Usando rol en caché para ${user.uid}: $_cachedRole');
        return _cachedRole!;
      }

      // Intentar obtener desde Custom Claims primero (más rápido)
      final idTokenResult = await user.getIdTokenResult();
      final customRole = idTokenResult.claims?['role'] as String?;

      if (customRole != null) {
        final role = _parseRole(customRole);
        _cachedRole = role;
        _cachedUserId = user.uid;
        debugPrint('🔒 RoleService: Rol desde Custom Claims: $role');
        return role;
      }

      // Si no hay Custom Claim, buscar en Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!doc.exists) {
        debugPrint('⚠️ RoleService: Documento de usuario no existe');
        return UserRole.user;
      }

      final data = doc.data();
      final roleString = data?['role'] as String? ?? 'user';
      final role = _parseRole(roleString);

      _cachedRole = role;
      _cachedUserId = user.uid;

      debugPrint('🔒 RoleService: Rol desde Firestore: $role');
      return role;
    } catch (e) {
      debugPrint('❌ RoleService: Error obteniendo rol: $e');
      return UserRole.user;
    }
  }

  /// Verifica si el usuario actual es administrador
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == UserRole.admin;
  }

  /// Verifica si el usuario actual es moderador o admin
  static Future<bool> isModerator() async {
    final role = await getUserRole();
    return role == UserRole.moderator || role == UserRole.admin;
  }

  /// Verifica si el usuario tiene permiso para una acción específica
  static Future<bool> hasPermission(String permission) async {
    final role = await getUserRole();

    switch (permission) {
      case 'manage_users':
      case 'manage_roles':
      case 'view_analytics':
      case 'manage_ai_config':
        return role == UserRole.admin;

      case 'manage_glossary':
      case 'manage_jurisprudence':
      case 'manage_laws':
        return role == UserRole.admin || role == UserRole.moderator;

      case 'use_ai':
      case 'create_calculations':
      case 'create_schedules':
        return true; // Todos los usuarios autenticados

      default:
        debugPrint('⚠️ RoleService: Permiso desconocido: $permission');
        return false;
    }
  }

  /// Actualiza el rol de un usuario en Firestore
  /// NOTA: Para actualizar Custom Claims, se necesita una Cloud Function
  static Future<bool> updateUserRole(String userId, UserRole newRole) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ RoleService: Usuario no autenticado');
        return false;
      }

      // Verificar que el usuario actual sea admin
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) {
        debugPrint('❌ RoleService: Usuario actual no es admin');
        return false;
      }

      // Actualizar en Firestore
      await _firestore.collection('users').doc(userId).update({
        'role': _roleToString(newRole),
        'roleUpdatedAt': FieldValue.serverTimestamp(),
        'roleUpdatedBy': currentUser.uid,
      });

      debugPrint('✅ RoleService: Rol actualizado a $newRole para usuario $userId');

      // Limpiar caché si es el usuario actual
      if (userId == currentUser.uid) {
        _cachedRole = null;
        _cachedUserId = null;
      }

      return true;
    } catch (e) {
      debugPrint('❌ RoleService: Error actualizando rol: $e');
      return false;
    }
  }

  /// Obtiene una lista de todos los usuarios con sus roles (solo admin)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final isCurrentUserAdmin = await isAdmin();
      if (!isCurrentUserAdmin) {
        debugPrint('❌ RoleService: Acceso denegado - no es admin');
        return [];
      }

      final snapshot = await _firestore.collection('users').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'name': data['name'] ?? 'Sin nombre',
          'email': data['email'] ?? 'Sin email',
          'role': _parseRole(data['role'] as String? ?? 'user'),
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ RoleService: Error obteniendo usuarios: $e');
      return [];
    }
  }

  /// Establece el rol inicial de un usuario recién registrado
  static Future<void> setInitialRole(String userId, {UserRole role = UserRole.user}) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'role': _roleToString(role),
        'roleCreatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ RoleService: Rol inicial establecido: $role para $userId');
    } catch (e) {
      debugPrint('❌ RoleService: Error estableciendo rol inicial: $e');
    }
  }

  /// Limpia la caché de roles (útil al cerrar sesión)
  static void clearCache() {
    _cachedRole = null;
    _cachedUserId = null;
    debugPrint('🔒 RoleService: Caché limpiada');
  }

  /// Convierte string a UserRole
  static UserRole _parseRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }

  /// Convierte UserRole a string
  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.user:
        return 'user';
    }
  }

  /// Obtiene el nombre legible del rol
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.moderator:
        return 'Moderador';
      case UserRole.user:
        return 'Usuario';
    }
  }

  /// Obtiene el ícono para cada rol
  static String getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '👑';
      case UserRole.moderator:
        return '🛡️';
      case UserRole.user:
        return '👤';
    }
  }
}
