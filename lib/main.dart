import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';
import 'administrar_carros.dart';
import 'registro_carros.dart';
import 'consulta.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabase();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  PaginaPrincipalState createState() => PaginaPrincipalState();
}

class PaginaPrincipalState extends State<PaginaPrincipal> {
  late Future<List<Map<String, dynamic>>> _carrosFuture;
  TextEditingController searchController = TextEditingController();
  String _filtroSeleccionado = 'Recientes';
  String _criterioBusqueda = '';

  @override
  void initState() {
    super.initState();
    _carrosFuture = todosLosCarros();
  }

  void actualizarCarros() {
    setState(() {
      _carrosFuture = todosLosCarros();
    });
  }

  Future<void> agregarCarro(String tipo, String modelo, String matricula, String fechaRegistro) async {
    await db.rawInsert(
      'insert into carros (tipo, modelo, matricula, fecha_registro) values (?, ?, ?, ?)',
      [tipo, modelo, matricula, fechaRegistro],
    );

    actualizarCarros();
  }

  List<Map<String, dynamic>> filtrarCarros(List<Map<String, dynamic>> carros) {
    switch (_filtroSeleccionado) {
      case 'Alfabeto':
        carros.sort((a, b) => a['MATRICULA'][0].toLowerCase().compareTo(b['MATRICULA'][0].toLowerCase()));
        break;
      case 'Recientes':
        carros.sort((a, b) => b['ID'].compareTo(a['ID']));
        break;
      case 'Antiguos':
        carros.sort((a, b) => a['ID'].compareTo(b['ID']));
        break;
    }
    return carros;
  }

  List<Map<String, dynamic>> buscarCarros(List<Map<String, dynamic>> carros) {
    if (_criterioBusqueda.isNotEmpty) {
      final String busquedaLowerCase = _criterioBusqueda.toLowerCase();
      return carros.where((carro) {
        return carro['TIPO'].toLowerCase().contains(busquedaLowerCase) ||
            carro['MODELO'].toLowerCase().contains(busquedaLowerCase) ||
            carro['MATRICULA'].toLowerCase().contains(busquedaLowerCase) ||
            carro['FECHA_REGISTRO'].toLowerCase().contains(busquedaLowerCase);
      }).toList();
    }
    return carros;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          title: const Text(''),
          backgroundColor: Colors.cyan,
          flexibleSpace: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.search),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              _criterioBusqueda = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Buscar carros...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: FutureBuilder(
        future: _carrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            var carros = List<Map<String, dynamic>>.from(snapshot.data as List<Map<String, dynamic>>);
            carros = filtrarCarros(carros);
            carros = buscarCarros(carros);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (carros.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Mis Carros:(${carros.length})',
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        DropdownButton<String>(
                          value: _filtroSeleccionado,
                          onChanged: (String? newValue) {
                            setState(() {
                              _filtroSeleccionado = newValue!;
                              actualizarCarros();
                            });
                          },
                          items: ['Alfabeto', 'Recientes', 'Antiguos'].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 12.0),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: carros.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay carros encontrados',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        )
                      : ListView.builder(
                          itemCount: carros.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdministrarTipoCarroPage(
                                      carroInfo: carros[index],
                                    ),
                                  ),
                                ).then((value) {
                                  actualizarCarros();
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(255, 236, 236, 236).withOpacity(0.5),
                                      spreadRadius: 3,
                                      blurRadius: 7,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: Hero(
                                    tag: 'carAvatar_$index',
                                    child: CircleAvatar(
                                      backgroundColor: Colors.cyan,
                                      child: Text(
                                        carros[index]['MATRICULA'][0].toUpperCase(),
                                        style: const TextStyle(fontSize: 24.0, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Matrícula: ${carros[index]['MATRICULA']}',
                                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Marca: ${carros[index]['TIPO']}',
                                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Modelo: ${carros[index]['MODELO']}',
                                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Fecha: ${carros[index]['FECHA_REGISTRO']}',
                                        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                      ),
                                      FutureBuilder(
                                        future: gastosPorCarro(carros[index]['ID'] as int),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text('Error: ${snapshot.error}');
                                          } else {
                                            var gastos = snapshot.data as List<Map<String, dynamic>>;
                                            double gastoTotal = gastos.fold(0.0, (sum, gasto) => sum + (gasto['GASTO'] as double? ?? 0.0));

                                            // Format the total expense to display only two decimal places
                                            String formattedGastoTotal = gastoTotal.toStringAsFixed(2);

                                            return Text(
                                              'Gasto Total: \$$formattedGastoTotal',
                                              style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
              ],
            );
          }
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConsultaPage(),
                ),
              );
            },
            icon: const Icon(
              Icons.info,
              size: 46.0,
              color: Colors.cyan,
            ),
          ),
          const SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarroPage(
                    onCarroAdded: agregarCarro,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.add,
                  size: 36.0,
                ),
                SizedBox(width: 8.0),
                Icon(
                  Icons.description,
                  size: 28.0,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}
