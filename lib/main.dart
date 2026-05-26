import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TurismoApp());
}

class TurismoApp extends StatelessWidget {
  const TurismoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalcaTravel Tech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Colores base calcados del Dashboard web
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // slate-50
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // blue-600
          primary: const Color(0xFF0F172A), // slate-900 (Barra lateral)
          secondary: const Color(0xFF059669), // emerald-600 (Botones)
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        cardTheme: CardTheme(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

// ==========================================
// CONFIGURACIÓN GLOBAL DE RED
// ==========================================
const String ipServidor = '3.235.93.43'; 
const String apiUrlTours = 'http://$ipServidor:8000/api/tours/';
const String apiUrlReservas = 'http://$ipServidor:8000/api/reservas/';

// ==========================================
// PANTALLA PRINCIPAL Y NAVEGACIÓN
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const TourListScreen(),
    const ReservasListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F172A), // slate-900
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF60A5FA), // blue-400
          unselectedItemColor: const Color(0xFF64748B), // slate-500
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.travel_explore), label: 'Catálogo'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Reservas'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA 1: CATÁLOGO DE TOURS
// ==========================================
class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  List tours = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTours();
  }

  Future<void> fetchTours() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrlTours));
      if (response.statusCode == 200) {
        setState(() {
          tours = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando tours: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _reservarTour(BuildContext context, Map tour) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A), // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Color(0xFF0F172A), // Body text
            ),
          ),
          child: child!,
        );
      },
    );
    if (fecha == null) return;

    int pasajeros = 1;
    if (context.mounted) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          TextEditingController ctrl = TextEditingController(text: "1");
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.people_alt, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Pasajeros', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, ctrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
      if (result != null && int.tryParse(result) != null) {
        pasajeros = int.parse(result);
      } else {
        return;
      }
    }

    final fechaEnvio = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

    final body = {
      'tour': tour['id'],
      'fecha': fechaEnvio,
      'cantidad_pasajeros': pasajeros,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrlReservas),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (context.mounted) {
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text('¡Reserva confirmada!')]),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.body}'), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      print('Error creando reserva: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done, color: Color(0xFF60A5FA)),
            SizedBox(width: 10),
            Text('TalcaTravel Tech'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: fetchTours,
              color: const Color(0xFF2563EB),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tours.length,
                itemBuilder: (context, index) {
                  final tour = tours[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(tour['nombre'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF), // blue-50
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('\$${tour['precio']}', style: const TextStyle(fontSize: 18, color: Color(0xFF2563EB), fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Text(tour['destino'], style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                              const SizedBox(width: 16),
                              const Icon(Icons.schedule, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text('${tour['duracion_dias']} días', style: const TextStyle(color: Color(0xFF64748B), fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _reservarTour(context, tour),
                              icon: const Icon(Icons.bookmark_add, color: Colors.white, size: 18),
                              label: const Text('Agendar Reserva', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF059669), // emerald-600
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ==========================================
// PANTALLA 2: MIS RESERVAS
// ==========================================
class ReservasListScreen extends StatefulWidget {
  const ReservasListScreen({super.key});

  @override
  State<ReservasListScreen> createState() => _ReservasListScreenState();
}

class _ReservasListScreenState extends State<ReservasListScreen> {
  List reservas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReservas();
  }

  Future<void> fetchReservas() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrlReservas));
      if (response.statusCode == 200) {
        setState(() {
          reservas = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando reservas: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Reservas'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : RefreshIndicator(
              onRefresh: fetchReservas,
              color: const Color(0xFF2563EB),
              child: reservas.isEmpty
                  ? const Center(child: Text('No hay reservas activas.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reservas.length,
                      itemBuilder: (context, index) {
                        final res = reservas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5), // emerald-50
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 28),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tour ID: #${res['tour']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 4),
                                      Text('Salida: ${res['fecha']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                      Text('Pasajeros: ${res['cantidad_pasajeros']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${res['precio_total']}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}