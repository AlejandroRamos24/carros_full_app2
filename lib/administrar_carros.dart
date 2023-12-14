import 'package:flutter/material.dart';
import 'db.dart';
import 'registro_gastos.dart';
import 'editar_carro.dart';
import 'editar_gasto.dart';

class AdministrarTipoCarroPage extends StatefulWidget {
  final Map<String, dynamic> carroInfo;

  const AdministrarTipoCarroPage({Key? key, required this.carroInfo}) : super(key: key);

  @override
  AdministrarTipoCarroPageState createState() => AdministrarTipoCarroPageState();
}

class AdministrarTipoCarroPageState extends State<AdministrarTipoCarroPage> {
  Future<List<Map<String, dynamic>>>? _gastosFuture = Future.value([]); // Inicializa con una lista vacía
  TextEditingController searchGastosController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _actualizarGastos();

    searchGastosController.addListener(() {
      _buscarGastos(searchGastosController.text);
    });
  }

  void _actualizarGastos() async {
    final gastos = await gastosPorCarro(widget.carroInfo['ID']);
    if (mounted) {
      setState(() {
        _gastosFuture = Future.value(gastos);
      });
    }
  }

  void _eliminarCarro(int carroId) async {
    await eliminarCarro(carroId);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  void _eliminarGasto(int gastoId) async {
    await eliminarGasto(gastoId);
    _actualizarGastos();
  }

  void _buscarGastos(String query) async {
    final gastos = await gastosPorCarro(widget.carroInfo['ID']);
    if (query.isNotEmpty) {
      final filteredGastos = gastos.where((gasto) =>
          gasto['TIPO_GASTO'].toString().toLowerCase().contains(query.toLowerCase()) ||
          gasto['AUXILIAR'].toString().toLowerCase().contains(query.toLowerCase()) ||
          gasto['GASTO'].toString().toLowerCase().contains(query.toLowerCase()) ||
          gasto['FECHA_GASTO'].toString().toLowerCase().contains(query.toLowerCase()));

      if (mounted) {
        setState(() {
          _gastosFuture = Future.value(filteredGastos.toList());
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _gastosFuture = Future.value(gastos);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar ${widget.carroInfo['TIPO']} ${widget.carroInfo['MODELO']} '),
        backgroundColor: Colors.cyan,
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
              ),
              elevation: 0.0,
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        side: const BorderSide(color: Color.fromARGB(255, 136, 136, 136)),
                      ),
                      elevation: 0.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Marca: ${widget.carroInfo['TIPO']}', style: const TextStyle(fontSize: 18)),
                                    Text('Modelo: ${widget.carroInfo['MODELO']}', style: const TextStyle(fontSize: 18)),
                                    Text('Matrícula: ${widget.carroInfo['MATRICULA']}', style: const TextStyle(fontSize: 18)),
                                    Text('Fecha: ${widget.carroInfo['FECHA_REGISTRO']}', style: const TextStyle(fontSize: 18)),
                                  ],
                                ),
                              ],
                            ),                    const SizedBox(height: 16),
                            Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildIconButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarCarroPage(carroInfo: widget.carroInfo),
                                ),
                              ).then((value) {
                                _actualizarGastos();
                              });
                            },
                            icon: Icons.edit,
                          ),
                          const SizedBox(width: 8),
                          _buildIconButton(
                            onPressed: () {
                              _showEliminarCarroDialog();
                            },
                            icon: Icons.delete,
                          ),
                        ],
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistroGastosPage(
                              carroId: widget.carroInfo['ID'],
                              tipoCarro: widget.carroInfo['TIPO'],
                            ),
                          ),
                        );
                      },
                      icon: Icons.add,
                      label: 'Agregar Gasto',
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildGastosList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _actualizarGastos();
        },
        backgroundColor: Colors.cyan,
        child: const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildIconButton({required VoidCallback onPressed, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: const Color.fromARGB(255, 136, 136, 136), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkResponse(
          onTap: onPressed,
          child: Icon(icon, size: 16, color: Colors.cyan),
        ),
      ),
    );
  }

  Widget _buildTextButton({required VoidCallback onPressed, required IconData icon, required String label}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.cyan,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: const BorderSide(color: Colors.cyan),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.cyan, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
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
                controller: searchGastosController,
                decoration: const InputDecoration(
                  hintText: 'Buscar gastos...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosList() {
    return FutureBuilder(
      future: _gastosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          var gastos = snapshot.data as List<Map<String, dynamic>>;
          int numeroDeGastos = gastos.length;

          return Column(
            children: [
              Visibility(
                visible: numeroDeGastos > 0,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: numeroDeGastos,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.black),
                      ),
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipo de Gasto: ${gastos[index]['TIPO_GASTO']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Auxiliar: ${gastos[index]['AUXILIAR']}'),
                            Text('Gasto: ${gastos[index]['GASTO']}'),
                            Text('Fecha: ${gastos[index]['FECHA_GASTO']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildIconButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarGastoPage(gastoInfo: gastos[index]),
                                  ),
                                ).then((value) {
                                  _actualizarGastos();
                                });
                              },
                              icon: Icons.edit,
                            ),
                            _buildIconButton(
                              onPressed: () {
                                _eliminarGasto(gastos[index]['ID']);
                              },
                              icon: Icons.delete,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Visibility(
                visible: numeroDeGastos == 0,
                child: const Text(
                  'No hay registros para mostrar.',
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _showEliminarCarroDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este carro?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _eliminarCarro(widget.carroInfo['ID']);
              },
              child: const Text('Sí, Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
