import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'models.dart';

// Import screens (will be created)
import 'screens/login_screen.dart';
import 'screens/super_admin_dashboard.dart';
import 'screens/school_admin_dashboard.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/parent_form_screen.dart';
import 'screens/school_detail_screen.dart';
import 'screens/class_detail_screen.dart';
import 'screens/student_edit_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final currentUser = authProvider.currentUser;
        final isLoginRoute = state.matchedLocation == '/login';
        final isParentFormRoute = state.matchedLocation.startsWith('/parent-form');

        // Allow parent form without auth
        if (isParentFormRoute) {
          return null;
        }

        // Redirect to login if not authenticated
        if (!isAuthenticated && !isLoginRoute) {
          return '/login';
        }

        // Redirect authenticated users away from login
        if (isAuthenticated && isLoginRoute) {
          return _getHomeRouteForRole(currentUser!.role);
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/super-admin',
          builder: (context, state) => const SuperAdminDashboard(),
        ),
        GoRoute(
          path: '/school/:schoolId',
          builder: (context, state) {
            final schoolId = state.pathParameters['schoolId']!;
            return SchoolDetailScreen(schoolId: schoolId);
          },
        ),
        GoRoute(
          path: '/school-admin',
          builder: (context, state) => const SchoolAdminDashboard(),
        ),
        GoRoute(
          path: '/class/:schoolId/:classId',
          builder: (context, state) {
            final schoolId = state.pathParameters['schoolId']!;
            final classId = state.pathParameters['classId']!;
            return ClassDetailScreen(
              schoolId: schoolId,
              classId: classId,
            );
          },
        ),
        GoRoute(
          path: '/teacher',
          builder: (context, state) => const TeacherDashboard(),
        ),
        GoRoute(
          path: '/teacher/edit-student/:schoolId/:classId/:studentId',
          builder: (context, state) {
            final schoolId = state.pathParameters['schoolId']!;
            final classId = state.pathParameters['classId']!;
            final studentId = state.pathParameters['studentId']!;
            return StudentEditScreen(
              schoolId: schoolId,
              classId: classId,
              studentId: studentId,
            );
          },
        ),
        GoRoute(
          path: '/parent-form/:schoolId/:classId',
          builder: (context, state) {
            final schoolId = state.pathParameters['schoolId']!;
            final classId = state.pathParameters['classId']!;
            return ParentFormScreen(
              schoolId: schoolId,
              classId: classId,
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return '/super-admin';
      case UserRole.schoolAdmin:
        return '/school-admin';
      case UserRole.teacher:
        return '/teacher';
    }
  }
}