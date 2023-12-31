import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';

class RegistroGastosPage extends StatefulWidget {
  final int carroId;
  final String tipoCarro;

  const RegistroGastosPage({Key? key, required this.carroId, required this.tipoCarro}) : super(key: key);

  @override
  RegistroGastosPageState createState() => RegistroGastosPageState();
}

class RegistroGastosPageState extends State<RegistroGastosPage> {
  TextEditingController auxiliarController = TextEditingController();
  TextEditingController gastoController = TextEditingController();
  TextEditingController fechaGastoController = TextEditingController();
  late DateTime selectedDate;

  String selectedTipoGasto = '';
  List<String> tiposDeGasto = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    cargarTiposDeGasto();
  }

  void cargarTiposDeGasto() async {
    List<Map<String, dynamic>> tiposGasto = await obtenerTiposDeGasto();
    setState(() {
      tiposDeGasto = tiposGasto.map((tipo) => tipo['TIPO_GASTO'].toUpperCase() as String).toList();
      selectedTipoGasto = tiposDeGasto.isNotEmpty ? tiposDeGasto[0] : '';
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2101, 12, 31),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fechaGastoController.text = "${picked.year}-${picked.month}-${picked.day}";
      });
    }
  }

  void guardarGasto() async {
    if (selectedTipoGasto.isEmpty ||
        auxiliarController.text.isEmpty ||
        gastoController.text.isEmpty ||
        fechaGastoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son obligatorios'),
          backgroundColor: Colors.cyan,
        ),
      );
      return;
    }

    double? gastoValue = double.tryParse(gastoController.text);

    if (gastoValue == null || gastoValue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingrese un valor numérico positivo para el gasto'),
          backgroundColor: Colors.cyan,
        ),
      );
      return;
    }

    // Redondear el valor a dos decimales y convertir a cadena
    String gastoString = gastoValue.toStringAsFixed(2);

    await db.rawInsert(
      'insert into gastos (carro_id, tipo_gasto, auxiliar, gasto, fecha_gasto) values (?, ?, ?, ?, ?)',
      [
        widget.carroId,
        selectedTipoGasto,
        auxiliarController.text,
        double.parse(gastoString), // Convertir de nuevo a double después del redondeo
        selectedDate.toLocal().toString().split(' ')[0],
      ],
    );

    setState(() {
      auxiliarController.text = '';
      gastoController.text = '';
      fechaGastoController.text = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gasto registrado correctamente'),
        backgroundColor: Colors.cyan,
      ),
    );
  }

  void mostrarDialogoTipoGasto({bool esEdicion = false, String? tipoGastoEditar}) {
    TextEditingController nuevoTipoGastoController =
        TextEditingController(text: esEdicion ? tipoGastoEditar : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(esEdicion ? 'Editar Tipo de Gasto' : 'Agregar Nuevo Tipo de Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nuevoTipoGastoController,
                decoration: InputDecoration(
                  labelText: esEdicion ? 'Editar Tipo de Gasto' : 'Nuevo Tipo de Gasto',
                ),
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
            ElevatedButton(
              onPressed: () async {
                String nuevoTipoGasto = nuevoTipoGastoController.text.trim();

                if (nuevoTipoGasto.isEmpty) {
                  // Show a message if the type of expense is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El tipo de gasto está vacío'),
                      backgroundColor: Colors.cyan,
                    ),
                  );
                } else if (tiposDeGasto.contains(nuevoTipoGasto.toUpperCase())) {
                  // Show a message if the type of expense already exists
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El tipo de gasto ya existe'),
                      backgroundColor: Colors.cyan,
                    ),
                  );
                } else {
                  // Add the new type of expense
                  await agregarTipoDeGasto(nuevoTipoGasto);
                  cargarTiposDeGasto();
                  Navigator.of(context).pop();
                }
              },
              child: Text(esEdicion ? 'Guardar Cambios' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Gastos - ${widget.tipoCarro}'),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 0.0,
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de gasto',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedTipoGasto,
                        items: tiposDeGasto.map((String tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTipoGasto = newValue!;
                          });
                        },
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            mostrarDialogoTipoGasto();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            if (selectedTipoGasto.isNotEmpty) {
                              eliminarTipoDeGasto(selectedTipoGasto).then((_) {
                                cargarTiposDeGasto();
                                setState(() {
                                  if (tiposDeGasto.contains(selectedTipoGasto)) {
                                    selectedTipoGasto = selectedTipoGasto;
                                  } else {
                                    selectedTipoGasto = tiposDeGasto.isNotEmpty ? tiposDeGasto[0] : '';
                                  }
                                });
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                TextField(
                  controller: auxiliarController,
                  decoration: const InputDecoration(labelText: 'Auxiliar'),
                ),
                TextField(
                  controller: gastoController,
                  decoration: const InputDecoration(labelText: 'Gasto'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                InkWell(
                  onTap: () {
                    _selectDate(context);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fechaGastoController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de gasto',
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    guardarGasto();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Text('Guardar'),
                  ),
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Visibility(
                        visible: true,
                        child: Text(
                          'Registros:',
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder(
                          future: gastosPorCarro(widget.carroId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                              return const Center(
                                child: Text('No hay registros para mostrar'),
                              );
                            }

                            var gastos = snapshot.data as List<Map<String, dynamic>>;
                            return ListView.builder(
                              itemCount: gastos.length,
                              itemBuilder: (context, index) {
                                return Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0.0),
                                    side: const BorderSide(color: Color.fromARGB(255, 136, 136, 136)),
                                  ),
                                  elevation: 0.0,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    title: Text(
                                      '${gastos[index]['TIPO_GASTO']} - '
                                      '${gastos[index]['AUXILIAR']} - '
                                      '${gastos[index]['GASTO']} - '
                                      '${gastos[index]['FECHA_GASTO']}',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
