import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

late Database db;

Future<void> initializeDatabase() async {
  var databasePath = await getDatabasesPath();
  String databaseFilePath = join(databasePath, 'base.db');

  db = await openDatabase(
    databaseFilePath,
    version: 4,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE CARROS (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          TIPO TEXT(35),
          MODELO TEXT(35),
          MATRICULA TEXT(35),
          FECHA_REGISTRO TEXT(35)
        );
      ''');
      await db.execute('''
        CREATE TABLE GASTOS (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          CARRO_ID INTEGER,
          TIPO_GASTO TEXT(35),
          AUXILIAR TEXT(35),
          GASTO REAL,  
          FECHA_GASTO TEXT(35)
        );
      ''');
      await db.execute('''
        CREATE TABLE TIPOS_DE_GASTO (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          TIPO_GASTO TEXT(35) UNIQUE
        );
      ''');
      await db.execute('''
        CREATE TABLE TIPOS_DE_CARRO (
          ID INTEGER PRIMARY KEY AUTOINCREMENT,
          TIPO_CARRO TEXT(35) UNIQUE
        );
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 4) {
        await db.execute('''
          CREATE TABLE TIPOS_DE_CARRO (
            ID INTEGER PRIMARY KEY AUTOINCREMENT,
            TIPO_CARRO TEXT(35) UNIQUE
          );
        ''');
      }
    },
  );
}

Future<void> actualizarCarro(int id, String tipo, String modelo, String matricula, String fechaRegistro) async {
  await db.rawUpdate(
    'UPDATE CARROS SET TIPO = ?, MODELO = ?, MATRICULA = ?, FECHA_REGISTRO = ? WHERE ID = ?',
    [tipo, modelo, matricula, fechaRegistro, id],
  );
}

Future<List<Map<String, dynamic>>> obtenerTiposDeGasto() async {
  var resultadoConsulta = await db.rawQuery('select * from TIPOS_DE_GASTO');
  return resultadoConsulta;
}

Future<void> agregarTipoDeGasto(String tipoGasto) async {
  await db.rawInsert(
    'insert or ignore into TIPOS_DE_GASTO (TIPO_GASTO) values (?)',
    [tipoGasto.toUpperCase()],
  );
}

Future<void> eliminarTipoDeGasto(String tipoGasto) async {
  await db.rawDelete('DELETE FROM TIPOS_DE_GASTO WHERE TIPO_GASTO = ?', [tipoGasto.toUpperCase()]);
}

Future<List<Map<String, dynamic>>> obtenerTiposDeCarro() async {
  var resultadoConsulta = await db.rawQuery('select * from TIPOS_DE_CARRO');
  return resultadoConsulta;
}

Future<void> agregarTipoDeCarro(String tipoCarro) async {
  await db.rawInsert(
    'insert or ignore into TIPOS_DE_CARRO (TIPO_CARRO) values (?)',
    [tipoCarro.toUpperCase()],
  );
}

Future<void> eliminarTipoDeCarro(String tipoCarro) async {
  await db.rawDelete('delete from TIPOS_DE_CARRO where TIPO_CARRO = ?', [tipoCarro.toUpperCase()]);
}

Future<List<Map<String, dynamic>>> todosLosCarros() async {
  var resultadoConsulta = await db.rawQuery('select * from CARROS');
  return resultadoConsulta;
}

Future<void> agregarCarro(String tipo, String modelo, String matricula, String fechaRegistro) async {
  var existingCar = await db.rawQuery('SELECT * FROM CARROS WHERE MATRICULA = ?', [matricula]);

  if (existingCar.isNotEmpty) {
    print('Ya existe un carro con la matrícula ingresada.');
    return;
  }

  await db.rawInsert(
    'INSERT INTO CARROS (TIPO, MODELO, MATRICULA, FECHA_REGISTRO) VALUES (?, ?, ?, ?)',
    [tipo, modelo, matricula, fechaRegistro],
  );
}

Future<List<Map<String, dynamic>>> gastosPorCarro(int carroId) async {
  var resultadoConsulta = await db.rawQuery('select * from GASTOS where CARRO_ID = ?', [carroId]);
  return resultadoConsulta;
}

Future<void> eliminarCarro(int carroId) async {
  await db.rawDelete('delete from CARROS where ID = ?', [carroId]);
}

Future<List<Map<String, dynamic>>> todosLosGastos() async {
  var resultadoConsulta = await db.rawQuery('''
    SELECT GASTOS.*, CARROS.TIPO, CARROS.MATRICULA
    FROM GASTOS
    INNER JOIN CARROS ON GASTOS.CARRO_ID = CARROS.ID
  ''');
  return resultadoConsulta;
}

Future<void> eliminarGasto(int gastoId) async {
  await db.rawDelete('delete from GASTOS where ID = ?', [gastoId]);
}

Future<List<Map<String, dynamic>>> obtenerTodosLosGastos() async {
  var resultadoConsulta = await db.rawQuery('''
    SELECT GASTOS.*, CARROS.TIPO, CARROS.MATRICULA
    FROM GASTOS
    INNER JOIN CARROS ON GASTOS.CARRO_ID = CARROS.ID
  ''');
  return resultadoConsulta;
}

Future<List<String>> obtenerMatriculasDeCarros() async {
  var resultadoConsulta = await db.rawQuery('SELECT MATRICULA FROM CARROS');
  return resultadoConsulta.map((car) => car['MATRICULA'].toString()).toList();
}
