import 'package:flutter/material.dart';
import 'db.dart';

class CarroPage extends StatefulWidget {
  final Function(String, String, String, String) onCarroAdded;

  const CarroPage({Key? key, required this.onCarroAdded}) : super(key: key);

  @override
  State<CarroPage> createState() => _CarroPageState();
}

class _CarroPageState extends State<CarroPage> {
  TextEditingController modeloController = TextEditingController();
  TextEditingController matriculaController = TextEditingController();
  TextEditingController fechaRegistroController = TextEditingController();
  DateTime? selectedDate;

  String selectedBrand = '';
  List<String> preDefinedBrands = [];

  @override
  void initState() {
    super.initState();
    loadPreDefinedBrands();
  }

  Future<void> loadPreDefinedBrands() async {
    var brands = await obtenerTiposDeCarro();
    if (brands.isNotEmpty) {
      preDefinedBrands =
          brands.map((map) => map['TIPO_CARRO'].toString()).toList();
      if (preDefinedBrands.isNotEmpty) {
        selectedBrand = preDefinedBrands.first;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Carro Nuevo'),
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
                        value: selectedBrand,
                        onChanged: (value) {
                          setState(() {
                            selectedBrand = value!;
                          });
                        },
                        items: preDefinedBrands
                            .map((brand) => DropdownMenuItem(
                                  value: brand,
                                  child: Text(brand),
                                ))
                            .toList(),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _agregarNuevaMarca,
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          onPressed: _eliminarMarca,
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ],
                ),
                TextField(
                  controller: modeloController,
                  decoration: const InputDecoration(labelText: 'Modelo'),
                ),
                TextField(
                  controller: matriculaController,
                  maxLength: 10, 
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    counterText: '', 
                  ),
                ),
                InkWell(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000, 1, 1),
                      lastDate: DateTime(2101, 12, 31),
                    );

                    if (pickedDate != null && pickedDate != selectedDate) {
                      setState(() {
                        selectedDate = pickedDate;
                        fechaRegistroController.text =
                            "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                      });
                    }
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
                ElevatedButton(
                  onPressed: agregarCarro,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Text('Guardar'),
                  ),
                ),
                const SizedBox(height: 16.0),
                const Visibility(
                  visible: true,
                  child: Text(
                    'Registros:',
                  ),
                ),
                Expanded(
                  child: FutureBuilder(
                    future: todosLosCarros(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData ||
                          (snapshot.data as List).isEmpty) {
                        return const Center(
                          child: Text('No hay registros para mostrar'),
                        );
                      }

                      var lista = snapshot.data as List<Map<String, dynamic>>;
                      return ListView.builder(
                        itemCount: lista.length,
                        itemBuilder: (context, index) {
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0.0),
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 136, 136, 136)),
                            ),
                            elevation: 0.0,
                            margin:
                                const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              title: Text(
                                '${lista[index]['TIPO']} - '
                                '${lista[index]['MODELO']} - '
                                '${lista[index]['MATRICULA']} - '
                                '${lista[index]['FECHA_REGISTRO']}',
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
        ),
      ),
    );
  }

  void agregarCarro() async {
    if (selectedBrand.isEmpty ||
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

    var existingCar = await todosLosCarros();
    var matricula = matriculaController.text.toUpperCase();

    if (existingCar.any((car) => car['MATRICULA'] == matricula)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un carro con la matrícula ingresada'),
          backgroundColor: Colors.cyan,
        ),
      );
      return;
    }

    widget.onCarroAdded(
      selectedBrand,
      modeloController.text,
      matricula,
      fechaRegistroController.text,
    );

    setState(() {
      modeloController.text = "";
      matriculaController.text = "";
      fechaRegistroController.text = "";
    });
  }

  void _agregarNuevaMarca() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String nuevaMarca = '';

        return AlertDialog(
          title: const Text('Agregar Nueva Marca'),
          content: TextField(
            onChanged: (value) {
              nuevaMarca = value.toUpperCase();
            },
            decoration: const InputDecoration(labelText: 'Nueva Marca'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nuevaMarca.isNotEmpty && !preDefinedBrands.contains(nuevaMarca)) {
                  await agregarTipoDeCarro(nuevaMarca);
                  await loadPreDefinedBrands();
                  setState(() {
                    selectedBrand = nuevaMarca;
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La marca ya existe o está vacía'),
                      backgroundColor: Colors.cyan,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarMarca() async {
    if (selectedBrand.isNotEmpty) {
      await eliminarTipoDeCarro(selectedBrand);
      await loadPreDefinedBrands();
      setState(() {
        selectedBrand = preDefinedBrands.isNotEmpty ? preDefinedBrands.first : '';
      });
    }
  }
}
