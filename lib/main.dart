import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pages/appointment_scheduler_page.dart';
// Importa TODAS tus páginas aquí
import 'pages/login_page.dart';
import 'pages/patient_dashboard_page.dart';
import 'pages/psychologist_dashboard_page.dart';
import 'pages/professionals_list_page.dart';
import 'pages/professional_detail_page.dart';
import 'pages/chat_page.dart';
import 'pages/psychologist_profile_page.dart';
import 'pages/register_page.dart';
void main() {
  runApp(const MyApp());
}

// Configuración de navegación con GoRouter
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthCheck();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/patient-dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const PatientDashboardPage();
      },
    ),
     GoRoute(
      path: '/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterPage();
      },
    ),
    GoRoute(
      path: '/psychologist-dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const PsychologistDashboardPage();
      },
    ),


   
    // Ruta principal para la lista de profesionales
    GoRoute(
      path: '/professionals',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfessionalsListPage();
      },
    

      // Ruta ANIDADA para el detalle de un profesional
      routes: <RouteBase>[
           GoRoute(
          path: ':id',
          builder: (BuildContext context, GoRouterState state) {
            final professionalId = state.pathParameters['id']!;
            return ProfessionalDetailPage(professionalId: professionalId);
          },
          // --- NUEVA RUTA ANIDADA PARA AGENDAR ---
          routes: <RouteBase>[
            GoRoute(
              path: 'schedule', // ej: /professionals/1/schedule
              builder: (BuildContext context, GoRouterState state) {
                final professionalId = state.pathParameters['id']!;
                // Pasamos el nombre del profesional como un extra
                final professionalName = state.extra as String? ?? 'Dr.';
                return AppointmentSchedulerPage(
                  professionalId: professionalId,
                  professionalName: professionalName,
                );
              },
            ),
          ],
        ),
      ],
      
    ),
      GoRoute(
      path: '/psychologist-profile',
      builder: (BuildContext context, GoRouterState state) {
        return const PsychologistProfilePage();
      },
    ),
     GoRoute(
      path: '/chat/:appointmentId', // ej: /chat/106
      builder: (BuildContext context, GoRouterState state) {
        final appointmentId = state.pathParameters['appointmentId']!;
        return ChatPage(appointmentId: appointmentId);
      },
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Psico SAS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Widget que chequea si el usuario está autenticado al iniciar la app
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: 'authToken');
    final userType = await _storage.read(key: 'userType');

    // Pequeña demora para que se vea la pantalla de carga
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (token != null && userType != null) {
      if (userType == 'psychologist' || userType == 'professional') {
        context.go('/psychologist-dashboard');
      } else {
        context.go('/patient-dashboard');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}