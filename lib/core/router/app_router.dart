import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/medicine.dart';
import '../../presentation/screens/auth/account_settings_screen.dart';
import '../../presentation/screens/auth/auth_welcome_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/auth/sign_up_screen.dart';
import '../../presentation/screens/auth/verify_email_screen.dart';
import '../../presentation/screens/backup/backup_dashboard_screen.dart';
import '../../presentation/screens/main_layout.dart';
import '../../presentation/screens/medicines/add_edit_medicine_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/my_profile_screen.dart';
import '../../presentation/screens/settings/app_updates_screen.dart';
import '../../presentation/screens/settings/developer_info_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/vault/prescription_vault_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String authWelcome = '/auth-welcome';
  static const String signUp = '/sign-up';
  static const String verifyEmail = '/verify-email';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String accountSettings = '/account-settings';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String medicines = '/medicines';
  static const String family = '/family';
  static const String history = '/history';
  static const String addEditMedicine = '/add-edit-medicine';
  static const String prescriptionVault = '/prescription-vault';
  static const String settings = '/settings';
  static const String myProfile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String dataBackup = '/data-backup';
  static const String appUpdates = '/app-updates';
  static const String developerInfo = '/developer-info';
}

CustomTransitionPage<void> _buildSmoothTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.03, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.authWelcome,
        name: 'authWelcome',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const AuthWelcomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'signUp',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const SignUpScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: VerifyEmailScreen(email: state.extra as String?),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        name: 'accountSettings',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const AccountSettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const MainLayout(initialTab: 0),
        ),
      ),
      GoRoute(
        path: AppRoutes.medicines,
        name: 'medicines',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const MainLayout(initialTab: 1),
        ),
      ),
      GoRoute(
        path: AppRoutes.family,
        name: 'family',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const MainLayout(initialTab: 2),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const MainLayout(initialTab: 3),
        ),
      ),
      GoRoute(
        path: AppRoutes.addEditMedicine,
        name: 'addEditMedicine',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: AddEditMedicineScreen(
            initialMedicine: state.extra as Medicine?,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.prescriptionVault,
        name: 'prescriptionVault',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const PrescriptionVaultScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.myProfile,
        name: 'myProfile',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const MyProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.dataBackup,
        name: 'dataBackup',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const BackupDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.appUpdates,
        name: 'appUpdates',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const AppUpdatesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.developerInfo,
        name: 'developerInfo',
        pageBuilder: (context, state) => _buildSmoothTransitionPage(
          context: context,
          state: state,
          child: const DeveloperInfoScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Route not found: ${state.error}'))),
  );
});
