import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class Worker {
  final String path;
  final int frequency;
  final senderFrequencyRecords = Map<String, int>();
  final receiverFrequencyRecords = Map<String, int>();

  final outputFile =
      File('${DateFormat('yyyyMMdd-H:m:ss').format(DateTime.now())}.log');
  final Logger logger = new Logger('PesonetFrequency');

  Worker({this.path = ".", this.frequency = 3});

  void run() async {
    _initLogger();
    if (path.endsWith(".csv")) {
      //Assuming we are working with a single file
      try {
        await processFile(path);
      } on FileSystemException catch (e) {
        print(
            'Error occured when processing file \'${e.path}\'. Please make sure it\'s a valid ' +
                'PESONET file in CSV format.\n Error: ${e.message}');
        exit(-1);
      }
    } else {
      //Assuming we are working with a directory
      try {
        //Trying to open a directory and list the files
        _log('Processing CSV files in dir $path');
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
    _senderFrequencyCheck();
    _receiverFrequencyCheck();
  }

  void _senderFrequencyCheck() {
    _log('\n\nSending frequency check (BIC:Account)');
    _log('--------------------------------------------------');
    int count =
        _printSortedMapFrequency('Sending account ', senderFrequencyRecords);

    _log(
        '\nTotal records processed: ${senderFrequencyRecords.length}; Total velocity violations of ' +
            '${frequency} entries per sending account: ${count}\n\n');
  }

  void _receiverFrequencyCheck() {
    _log('\n\nReceiving frequency check (MIN)');
    _log('--------------------------------------------------');
    int count =
        _printSortedMapFrequency('Receiver MIN ', receiverFrequencyRecords);

    _log(
        '\nTotal records processed: ${senderFrequencyRecords.length}; Total velocity violations of ' +
            '${frequency} entries per sending account: ${count}\n\n');
  }

  int _printSortedMapFrequency(String accountName, Map<String, int> map) {
    int count = 0;

    final sortedMap = Map.fromEntries(
        map.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));

    sortedMap.forEach((key, value) {
      if (value >= frequency) {
        _log('$accountName $key has ${value} entries');
        count++;
      }
    });
    return count;
  }

  void _initLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      outputFile.writeAsStringSync("${rec.message}\n", mode: FileMode.append);
    });
  }

  Future processFile(String path) async {
    final input = new File(path).openRead();
    _log('Processing file $path');
    final fields = await input
        .transform(utf8.decoder)
        .transform(new CsvToListConverter())
        .toList();
    processCSVRecordsFrequency(fields);
  }

  void processCSVRecordsFrequency(List<List> fields) {
    for (var i = 0; i < fields.length; i++) {
      final account = '${fields[i][3]}:${fields[i][14]}';
      _processFrequency(account, senderFrequencyRecords);
      var min = '${fields[i][15]}';
      min = min.startsWith('0') ? min.substring(1) : min;
      _processFrequency(min, receiverFrequencyRecords);
    }
  }

  void _processFrequency(String account, Map<String, int> records) {
    if (records.containsKey(account)) {
      records[account]++;
    } else {
      records[account] = 1;
    }
  }

  void _log(String s) {
    print(s);
    logger.info(s);
  }
}
