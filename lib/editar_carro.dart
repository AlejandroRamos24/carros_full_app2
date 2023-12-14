import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'db.dart';
import 'main.dart';

class EditarCarroPage extends StatefulWidget {
  final Map<String, dynamic> carroInfo;

  const EditarCarroPage({Key? key, required this.carroInfo}) : super(key: key);

  @override
  EditarCarroPageState createState() => EditarCarroPageState();
}

class EditarCarroPageState extends State<EditarCarroPage> {
  TextEditingController modeloController = TextEditingController();
  TextEditingController matriculaController = TextEditingController();
  TextEditingController fechaRegistroController = TextEditingController();
  String selectedMarcaDeCarro = '';
  List<String> marcasDeCarro = [];

  @override
  void initState() {
    super.initState();
    cargarMarcasDeCarro();
    selectedMarcaDeCarro = widget.carroInfo['TIPO'];
    modeloController.text = widget.carroInfo['MODELO'];
    matriculaController.text = widget.carroInfo['MATRICULA'];
    fechaRegistroController.text = widget.carroInfo['FECHA_REGISTRO'];
  }

  void cargarMarcasDeCarro() async {
    var marcas = await obtenerTiposDeCarro();
    setState(() {
      marcasDeCarro =
          marcas.map((map) => map['TIPO_CARRO'].toString()).toList();
      if (!marcasDeCarro.contains(selectedMarcaDeCarro)) {
        selectedMarcaDeCarro =
            marcasDeCarro.isNotEmpty ? marcasDeCarro.first : '';
      }
    });
  }

  void editarCarro() async {
    if (selectedMarcaDeCarro.isEmpty ||
        modeloController.text.isEmpty ||
        matriculaController.text.isEmpty ||
        fechaRegistroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son obligatorios'),
          backgroundColor: Colors.cyan,
        ),
      );
      return;
    }

    // Check for duplicate license plates before updating the car
    List<String> existingLicensePlates = await obtenerMatriculasDeCarros();
    var nuevaMatricula =
        matriculaController.text.toUpperCase(); // Convertir a mayúsculas

    if (existingLicensePlates.contains(nuevaMatricula) &&
        nuevaMatricula != widget.carroInfo['MATRICULA']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La matrícula ya existe. Ingrese una matrícula diferente.'),
          backgroundColor: Colors.cyan,
        ),
      );
      return;
    }

    if (!marcasDeCarro.contains(selectedMarcaDeCarro)) {
      setState(() {
        marcasDeCarro.add(selectedMarcaDeCarro);
      });
    }

    await actualizarCarro(
      widget.carroInfo['ID'],
      selectedMarcaDeCarro,
      modeloController.text,
      nuevaMatricula, // Utilizar la matrícula convertida a mayúsculas
      fechaRegistroController.text,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carro editado correctamente'),
        backgroundColor: Colors.cyan,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PaginaPrincipal()),
    );
  }

  void eliminarMarca() async {
    if (selectedMarcaDeCarro.isNotEmpty) {
      await eliminarTipoDeCarro(selectedMarcaDeCarro);
      cargarMarcasDeCarro();
      setState(() {
        selectedMarcaDeCarro =
            marcasDeCarro.isNotEmpty ? marcasDeCarro.first : '';
      });
    }
  }

  void mostrarDialogAgregarMarca() {
    TextEditingController nuevaMarcaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Nueva Marca'),
          content: TextField(
            controller: nuevaMarcaController,
            decoration: const InputDecoration(labelText: 'Nueva Marca'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String nuevaMarca = nuevaMarcaController.text;
                if (nuevaMarca.isNotEmpty && !marcasDeCarro.contains(nuevaMarca)) {
                  await agregarTipoDeCarro(nuevaMarca);
                  cargarMarcasDeCarro();
                  setState(() {
                    selectedMarcaDeCarro = nuevaMarca;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La marca ya existe o está vacía'),
                      backgroundColor: Colors.cyan,
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
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
        title: Text(
          'Editar Carro ${widget.carroInfo['TIPO']} ${widget.carroInfo['MODELO']}',
        ),
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
                  'Marca de carro',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: marcasDeCarro.contains(selectedMarcaDeCarro)
                            ? selectedMarcaDeCarro
                            : '',
                        items: marcasDeCarro.map((String marca) {
                          return DropdownMenuItem<String>(
                            value: marca,
                            child: Text(marca),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedMarcaDeCarro = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                  ),
                ),
                TextField(
                  controller: matriculaController,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                  ),
                ),
                InkWell(
                  onTap: () {
                    DatePicker.showDatePicker(
                      context,
                      showTitleActions: true,
                      minTime: DateTime(2000, 1, 1),
                      maxTime: DateTime(2101, 12, 31),
                      onConfirm: (date) {
                        setState(() {
                          fechaRegistroController.text =
                              "${date.year}-${date.month}-${date.day}";
                        });
                      },
                      currentTime: DateTime.now(),
                      locale: LocaleType.es,
                    );
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fechaRegistroController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de registro',
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          editarCarro();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          child: Text('Guardar Cambios'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
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
