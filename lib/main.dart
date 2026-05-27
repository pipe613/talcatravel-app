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
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), 
          primary: const Color(0xFF0F172A), 
          secondary: const Color(0xFF059669), 
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
const String ipServidor = '34.237.2.241'; 
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
          backgroundColor: const Color(0xFF0F172A), 
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF60A5FA), 
          unselectedItemColor: const Color(0xFF64748B), 
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
// PANTALLA 1: CATÁLOGO DE TOURS (Sin Cambios)
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
              primary: Color(0xFF0F172A), 
              onPrimary: Colors.white, 
              onSurface: Color(0xFF0F172A), 
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
              child: tours.isEmpty
                  // MENSAJE VACÍO CON SCROLL FORZADO
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          alignment: Alignment.center,
                          child: const Text('No hay tours disponibles en este momento.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                        )
                      ],
                    )
                  // LISTA DE TOURS CON SCROLL FORZADO
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(), // Evita que se tranque si hay pocos tours
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
                                        color: const Color(0xFFEFF6FF), 
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
                                      backgroundColor: const Color(0xFF059669), 
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
// PANTALLA 2: MIS RESERVAS (ACTUALIZADA CON CRUD Y NOMBRE DE TOUR)
// ==========================================
class ReservasListScreen extends StatefulWidget {
  const ReservasListScreen({super.key});

  @override
  State<ReservasListScreen> createState() => _ReservasListScreenState();
}

class _ReservasListScreenState extends State<ReservasListScreen> {
  List reservas = [];
  List tours = []; // Nueva lista para mapear nombres
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData(); // Ahora carga Reservas y Tours
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      // Hacemos ambas peticiones en paralelo para mayor velocidad
      final resReservas = await http.get(Uri.parse(apiUrlReservas));
      final resTours = await http.get(Uri.parse(apiUrlTours));
      
      if (resReservas.statusCode == 200 && resTours.statusCode == 200) {
        setState(() {
          reservas = json.decode(utf8.decode(resReservas.bodyBytes));
          tours = json.decode(utf8.decode(resTours.bodyBytes));
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => isLoading = false);
    }
  }

  // Helper para buscar el nombre del tour basado en su ID
  String getTourName(int tourId) {
    final tour = tours.firstWhere(
      (t) => t['id'] == tourId,
      orElse: () => null,
    );
    return tour != null ? tour['nombre'] : 'Tour Eliminado/Desconocido';
  }

  // Lógica para ELIMINAR (Cancelar) reserva
  Future<void> _cancelarReserva(int reservaId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: const Text('¿Estás seguro de que deseas cancelar esta reserva? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$apiUrlReservas$reservaId/'));
      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva cancelada con éxito')));
        fetchData(); // Recargar datos
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cancelar la reserva')));
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error al cancelar: $e');
      setState(() => isLoading = false);
    }
  }

  // Lógica para EDITAR (Pasajeros) reserva
  // Lógica para EDITAR (Pasajeros y Fecha) reserva
  // Lógica para EDITAR (Pasajeros, Fecha y recálculo de Precio) reserva
  Future<void> _editarReserva(Map reserva) async {
    TextEditingController ctrl = TextEditingController(text: reserva['cantidad_pasajeros'].toString());
    DateTime fechaSeleccionada = DateTime.tryParse(reserva['fecha']) ?? DateTime.now().add(const Duration(days: 1));
    
    Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Modificar Reserva'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad de Pasajeros'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Fecha: ${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime.now(), 
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null && picked != fechaSeleccionada) {
                            setStateDialog(() => fechaSeleccionada = picked);
                          }
                        },
                        child: const Text('Cambiar'),
                      )
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.isEmpty || int.tryParse(ctrl.text) == null) return;
                    Navigator.pop(context, {
                      'pasajeros': int.parse(ctrl.text),
                      'fecha': '${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}'
                    });
                  },
                  child: const Text('Actualizar')
                ),
              ],
            );
          }
        );
      },
    );

    if (result != null) {
      setState(() => isLoading = true);
      
      // 1. EXTRAER EL PRECIO DEL TOUR CORRESPONDIENTE
      final tourRelacionado = tours.firstWhere(
        (t) => t['id'] == reserva['tour'],
        orElse: () => null,
      );
      
      // 2. CALCULAR EL NUEVO PRECIO TOTAL
      double precioUnitario = 0.0;
      if (tourRelacionado != null) {
        precioUnitario = double.tryParse(tourRelacionado['precio'].toString()) ?? 0.0;
      }
      double nuevoPrecioTotal = precioUnitario * result['pasajeros'];

      // 3. ENVIAR TODO AL BACKEND
      final body = {
        'cantidad_pasajeros': result['pasajeros'],
        'fecha': result['fecha'],
        'tour': reserva['tour'],
        'precio_total': nuevoPrecioTotal.toString(), // <-- ENVIAMOS EL NUEVO TOTAL
      };

      try {
        final response = await http.put(
          Uri.parse('$apiUrlReservas${reserva['id']}/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (response.statusCode == 200) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva y precio actualizados')));
          fetchData(); 
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
          setState(() => isLoading = false);
        }
      } catch (e) {
         print('Error al editar: $e');
         setState(() => isLoading = false);
      }
    }
  }

  // Modal Inferior (BottomSheet) de Opciones
  void _mostrarOpciones(Map reserva) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Gestionar Reserva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                title: const Text('Editar Reserva'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editarReserva(reserva);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Cancelar Reserva'),
                onTap: () {
                  Navigator.pop(ctx);
                  _cancelarReserva(reserva['id']);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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
              onRefresh: fetchData,
              color: const Color(0xFF2563EB),
              child: reservas.isEmpty
                  // MENSAJE VACÍO CON SCROLL FORZADO
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          alignment: Alignment.center,
                          child: const Text('No hay reservas activas.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                        )
                      ],
                    )
                  // LISTA DE RESERVAS CON SCROLL FORZADO
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(), // Garantiza la recarga siempre
                      padding: const EdgeInsets.all(16),
                      itemCount: reservas.length,
                      itemBuilder: (context, index) {
                        final res = reservas[index];
                        String nombreTour = getTourName(res['tour']);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _mostrarOpciones(res), 
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5), 
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.airplane_ticket, color: Color(0xFF059669), size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(nombreTour, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                                        const SizedBox(height: 4),
                                        Text('Salida: ${res['fecha']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                        Text('Pasajeros: ${res['cantidad_pasajeros']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${res['precio_total']}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF059669)),
                                      ),
                                      const SizedBox(height: 5),
                                      const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}