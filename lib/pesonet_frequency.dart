import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';

class Worker {
  final List<String> whitelisted = ['DBPHPHMMXXX:010590018'];
  final String path;
  final int frequency;
  final senderFrequencyRecords = Map<String, Records>();
  final receiverFrequencyRecords = Map<String, Records>();
  final blacklisted = List<String>();

  final outputFile =
      File('${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.log');

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

    //Printing blacklisted account
    _log('\nRecords with violations: \n');
    blacklisted.forEach((element) {
      _log('$element,SNDR_FRMT');
    });

    //Counting lines
    _printSortedMapFrequency(
        '\nSender Velocity Limit\n', 'LMT_VLCT_SNDR', senderFrequencyRecords);
    _printSortedMapFrequency('\nReceiver Velocity Limit\n', 'LMT_VLCT_RCVR',
        receiverFrequencyRecords);
  }

  int _printSortedMapFrequency(
      String title, String code, Map<String, Records> map) {
    int count = 0;

    final sortedMap = Map.fromEntries(map.entries.toList()
      ..sort((e1, e2) => e2.value.count.compareTo(e1.value.count)));
    // _log(title);
    sortedMap.forEach((key, value) {
      //If count is more than frequency - print the seqs that are violating
      if (value.count > frequency) {
        for (int i = frequency; i < value.seqs.length; i++) {
          _log('${value.seqs[i]},$code');
          count++;
        }
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
    fields.forEach((line) {
      final seq = line[0];
      final sender = '${line[14]}';
      if (sender.trim() == null || sender.trim() == '0') {
        blacklisted.add(seq);
      } else {
        final account = '${line[3]}:${line[14]}';

        if (whitelisted.indexOf(account) < 0) {
          _processFrequency(seq, account, senderFrequencyRecords);
        }
        var min = '${line[15]}';
        //Removing the heading 0
        min = min.startsWith('0') ? min.substring(1) : min;
        _processFrequency(line[0], min, receiverFrequencyRecords);
      }
    });
  }

  void _processFrequency(
      String seq, String account, Map<String, Records> records) {
    if (records.containsKey(account)) {
      records[account].append(seq);
    } else {
      records[account] = Records(seq);
    }
  }

  void _log(String s) {
    print(s);
    logger.info(s);
  }
}

class Records {
  var _count = 1;
  final List<String> _seqs = List<String>();

  Records(String seq) {
    _seqs.add(seq);
  }

  void append(String seq) {
    _count++;
    _seqs.add(seq);
  }

  int get count => _count;
  List<String> get seqs => _seqs;
}
