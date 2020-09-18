import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

class Worker {
  final String path;
  final int frequency;
  final records = Map<String, int>();

  Worker({this.path = ".", this.frequency = 3});

  void run() async {
    records.clear();
    print('Opening the dir');
    if (path.endsWith(".csv")) {
      //Assuming we are working with a single file
      try {
        await processFile(path);
      } on FileSystemException catch (e) {
        print(
            'Error occured when processing file \'${e.path}\'. Please make sure it\'s a valid '+
                'PESONET file in CSV format.\n Error: ${e.message}');
        exit(-1);
      }
    } else {
      //Assuming we are working with a directory
      try {
        //Trying to open a directory and list the files
        final dir = Directory(path).listSync();
        for (int i = 0; i < dir.length; i++) {
          if (dir[i].path.toLowerCase().endsWith(".csv")) {
            await processFile(dir[i].path);
          }
        }
        ;
      } on FileSystemException catch (e) {
        print('Error occured reading directory ${path}. Error : ${e.message}');
      }
    }

    //Counting lines
    processingOutput();
  }

  void processingOutput() {
    int count = 0;
    records.forEach((key, value) {
      if (value >= frequency) {
        print('Account $key has ${value} entries');
        count++;
      }
    });

    print('Total records processed: ${records
        .length}; Total velocity violations of '
        + '${frequency} entries per account: ${count}');
  }

  Future processFile(String path) async {
    final input = new File(path).openRead();
    print('Processing file: ${path}');
    final fields = await input
        .transform(utf8.decoder)
        .transform(new CsvToListConverter())
        .toList();
    processListOfCSVRecords(fields);
  }

  void processListOfCSVRecords(List<List> fields) {
    for (var i = 1; i < fields.length; i++) {
      final account = '${fields[i][3]}:${fields[i][14]}';
      if (records.containsKey(account)) {
        records[account]++;
      } else {
        records[account] = 1;
      }
    }
  }
}