import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';
import 'main.dart';

class ConsultaPage extends StatefulWidget {
  const ConsultaPage({Key? key}) : super(key: key);

  @override
  ConsultaPageState createState() => ConsultaPageState();
}

class ConsultaPageState extends State<ConsultaPage> {
  late Future<List<Map<String, dynamic>>> _gastosFuture = todosLosGastos();
  TextEditingController searchController = TextEditingController();
  double? minAmount;
  double? maxAmount;

  List<Map<String, dynamic>> _filtrarGastos(
    String query,
    List<Map<String, dynamic>> gastos,
  ) {
    return gastos.where((gasto) {
      final matricula = gasto['MATRICULA'].toString().toLowerCase();
      final tipoGasto = gasto['TIPO_GASTO'].toString().toLowerCase();
      final auxiliar = gasto['AUXILIAR'].toString().toLowerCase();
      final fechaGasto = gasto['FECHA_GASTO'].toString().toLowerCase();
      final searchLower = query.toLowerCase();

      return matricula.contains(searchLower) ||
          tipoGasto.contains(searchLower) ||
          auxiliar.contains(searchLower) ||
          fechaGasto.contains(searchLower);
    }).toList();
  }

  Future<void> _showFilterDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar por monto'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto mínimo'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    double? parsedValue = double.tryParse(value);
                    if (parsedValue != null) {
                      minAmount = parsedValue;
                    } else {
                      // Manejar el caso en que la entrada no es un número válido.
                    }
                  }
                },
              ),
              const SizedBox(height: 8.0),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Monto máximo'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    double? parsedValue = double.tryParse(value);
                    if (parsedValue != null) {
                      maxAmount = parsedValue;
                    } else {
                      // Manejar el caso en que la entrada no es un número válido.
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (minAmount != null &&
                    maxAmount != null &&
                    maxAmount! >= minAmount!) {
                  setState(() {
                    _gastosFuture = todosLosGastos().then((gastos) {
                      return _filtrarGastosPorMonto(minAmount!, maxAmount!, gastos);
                    });
                  });
                  Navigator.of(context).pop();
                } else {
                  // Muestra un SnackBar si los campos no están llenos o si el monto máximo es menor que el mínimo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, llene ambos campos de monto y asegúrese de que el monto máximo sea mayor o igual al mínimo.',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.cyan,
                    ),
                  );
                }
              },
              child: const Text('Filtrar'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _filtrarGastosPorMonto(
    double minAmount, double maxAmount, List<Map<String, dynamic>> gastos,
  ) {
    return gastos.where((gasto) {
      final amount = gasto['GASTO'] as double;

      return amount >= minAmount && amount <= maxAmount;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PaginaPrincipal()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Consultar Gastos Totales'),
          backgroundColor: Colors.cyan,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PaginaPrincipal()),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (query) {
                        setState(() {
                          _gastosFuture = todosLosGastos()
                              .then((gastos) => _filtrarGastos(query, gastos));
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Buscar',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      ),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _gastosFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          var gastos = snapshot.data!;
                          var sumaGastos = gastos.fold<double>(
                              0, (sum, gasto) => sum + (gasto['GASTO'] as double));
                          return Column(
                            children: [
                              Text('Gastos Totales: \$${sumaGastos.toStringAsFixed(2)}'),
                              for (var gasto in gastos)
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromARGB(255, 236, 236, 236)
                                            .withOpacity(0.5),
                                        spreadRadius: 3,
                                        blurRadius: 7,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.cyan,
                                        child: Text(
                                          '\$',
                                          style: TextStyle(
                                              fontSize: 18.0,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Matrícula: ${gasto['MATRICULA']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Tipo de Gasto: ${gasto['TIPO_GASTO']}',
                                        ),
                                        Text(
                                          'Auxiliar: ${gasto['AUXILIAR']}',
                                        ),
                                        Text(
                                          'Fecha de Gasto: ${gasto['FECHA_GASTO']}',
                                        ),
                                      ],
                                    ),
                                    contentPadding: const EdgeInsets.all(0),
                                    trailing: SizedBox(
                                      width: 100, // Ajusta según sea necesario
                                      child: Center(
                                        child: Text(
                                          'Gasto: \$${gasto['GASTO'].toStringAsFixed(2)}',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
