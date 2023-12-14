import 'package:flutter/material.dart';
import 'db.dart';

class EditarGastoPage extends StatefulWidget {
  final Map<String, dynamic> gastoInfo;

  const EditarGastoPage({Key? key, required this.gastoInfo}) : super(key: key);

  @override
  EditarGastoPageState createState() => EditarGastoPageState();
}

class EditarGastoPageState extends State<EditarGastoPage> {
  TextEditingController auxiliarController = TextEditingController();
  TextEditingController gastoController = TextEditingController();
  TextEditingController fechaGastoController = TextEditingController();
  late DateTime selectedDate;

  List<String> tiposDeGasto = [];
  String selectedTipoGasto = '';

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _initializeFields();
    _loadTiposDeGasto();
  }

  void _initializeFields() {
    auxiliarController.text = widget.gastoInfo['AUXILIAR'];
    gastoController.text = widget.gastoInfo['GASTO'].toString();
    fechaGastoController.text = widget.gastoInfo['FECHA_GASTO'];
    selectedTipoGasto = widget.gastoInfo['TIPO_GASTO'];
  }

  void _loadTiposDeGasto() async {
    List<Map<String, dynamic>> tiposDeGastoDB = await obtenerTiposDeGasto();
    setState(() {
      tiposDeGasto =
          tiposDeGastoDB.map((tipo) => tipo['TIPO_GASTO'] as String).toList();
      if (!tiposDeGasto.contains(selectedTipoGasto)) {
        selectedTipoGasto = tiposDeGasto.isNotEmpty ? tiposDeGasto[0] : '';
      }
    });
  }

  void _guardarEdicion() async {
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
          content: Text(
              'Por favor, ingrese un valor numérico positivo para el gasto'),
          backgroundColor: Colors.cyan,
        ),
      );
      return;
    }

    await db.rawUpdate(
      'update gastos set tipo_gasto = ?, auxiliar = ?, gasto = ?, fecha_gasto = ? where id = ?',
      [
        selectedTipoGasto,
        auxiliarController.text,
        gastoValue,
        selectedDate.toLocal().toString().split(' ')[0],
        widget.gastoInfo['ID'],
      ],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edición de gasto realizada correctamente'),
        backgroundColor: Colors.cyan,
      ),
    );

    Navigator.pop(context, true); // Volvemos a la pantalla anterior
  }

  void mostrarDialogoTipoGasto() {
    TextEditingController nuevoTipoGastoController =
        TextEditingController(text: selectedTipoGasto);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Tipo de Gasto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nuevoTipoGastoController,
                decoration: const InputDecoration(
                  labelText: 'Editar Tipo de Gasto',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nuevoTipoGastoController.text.isNotEmpty) {
                  setState(() {
                    tiposDeGasto[tiposDeGasto.indexOf(selectedTipoGasto)] =
                        nuevoTipoGastoController.text;
                    selectedTipoGasto = nuevoTipoGastoController.text;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar Cambios'),
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
        title: const Text('Editar Gasto'),
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
              children: [
                Row(
                  children: [
                    const Text(
                      'Tipo de gasto',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.left, // Alineación a la izquierda
                    ),
                  ],
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
                  ],
                ),
                TextField(
                  controller: auxiliarController,
                  decoration: const InputDecoration(labelText: 'Auxiliar'),
                ),
                TextField(
                  controller: gastoController,
                  decoration: const InputDecoration(labelText: 'Gasto'),
                ),
                TextField(
                  controller: fechaGastoController,
                  decoration: InputDecoration(
                    labelText: 'Fecha del gasto',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () {
                        showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000, 1, 1),
                          lastDate: DateTime(2101, 12, 31),
                        ).then((date) {
                          if (date != null && date != selectedDate) {
                            setState(() {
                              selectedDate = date;
                              fechaGastoController.text =
                                  "${date.toLocal()}".split(' ')[0];
                            });
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _guardarEdicion();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text('Guardar Cambios'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Text('Cancelar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
