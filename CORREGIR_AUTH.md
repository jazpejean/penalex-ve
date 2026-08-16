# Correcciones para Auth - Reemplazos Manuales

Ejecuta estos comandos en tu terminal para corregir TODOS los errores de auth:

```bash
cd /home/jeanjazpe/Desktop/Penalex_VE

# Reemplazar imports
find lib/ -type f -name "*.dart" -exec sed -i "s|import '../providers/auth_provider.dart';|import '../services/auth_service.dart';|g" {} \;

# Reemplazar clase
find lib/ -type f -name "*.dart" -exec sed -i "s|AppAuthProvider|AuthService|g" {} \;

# Reemplazar métodos comunes
find lib/ -type f -name "*.dart" -exec sed -i "s|\.logout()|.signOut()|g" {} \;
find lib/ -type f -name "*.dart" -exec sed -i "s|\.userName|.currentUser?.displayName|g" {} \;
find lib/ -type f -name "*.dart" -exec sed -i "s|\.user|.currentUser|g" {} \;

# Limpiar y recompilar
flutter clean
flutter pub get
flutter run
```

## O manualmente archivo por archivo:

### 1. lib/pages/dashboard_screen.dart
```dart
// CAMBIAR:
import '../providers/auth_provider.dart';
final AppAuthProvider authProvider = context.watch<AppAuthProvider>();
final String nombreUsuario = authProvider.userName ?? 'Usuario';

// POR:
import '../services/auth_service.dart';
final authService = context.read<AuthService>();
final user = authService.currentUser;
final String nombreUsuario = user?.displayName ?? 'Usuario';
```

### 2. lib/widgets/app_drawer.dart
```dart
// CAMBIAR:
import '../providers/auth_provider.dart';
final AppAuthProvider authProvider = Provider.of<AppAuthProvider>(context, listen: false);
final User? user = authProvider.user;

// POR:
import '../services/auth_service.dart';
final authService = context.read<AuthService>();
final user = authService.currentUser;
```

### 3. lib/pages/verify_email_page.dart
```dart
// CAMBIAR:
import '../providers/auth_provider.dart';
final AppAuthProvider auth = context.read<AppAuthProvider>();
await auth.resendVerificationEmail();
await auth.logout();

// POR:
import '../services/auth_service.dart';
final authService = context.read<AuthService>();
await authService.sendVerificationEmail();
await authService.signOut();
```

### 4. lib/pages/reset_password_page.dart
```dart
// CAMBIAR:
import '../providers/auth_provider.dart';
final AppAuthProvider authProvider = context.read<AppAuthProvider>();

// POR:
import '../services/auth_service.dart';
final authService = context.read<AuthService>();
```

### 5. lib/pages/device_lock_screen.dart
```dart
// CAMBIAR:
import '../providers/auth_provider.dart';
context.read<AppAuthProvider>().logout()

// POR:
import '../services/auth_service.dart';
context.read<AuthService>().signOut()
```

---

## Después de corregir, ejecuta:

```bash
flutter clean
flutter pub get
flutter run
```
