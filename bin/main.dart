
import 'package:args/args.dart';
import 'package:pesonet_frequency/pesonet_frequency.dart';

void main(List<String> arguments) async {
  final argParser = ArgParser();

  print ('This is the PESONET CSV files parser. It identifies if there are acconts (combination of BIC and Account Number) \n '
  + 'in the provided files that violate the more or equal than <frequency> parameter.'
  + '\n\n Usage options:\n');

  argParser.addOption("file", valueHelp: "filename",defaultsTo: ".",help: "File to process. Can only be a .CSV file from Pesonet or the directory containing the CSV files.");
  argParser.addOption("freq",valueHelp: "frequency", defaultsTo: "3", help: "Check the frequency. Any account with above or equal to this frequency of entries will be highlighted in the script output");

  print (argParser.usage);

  final results = argParser.parse(arguments);
  final String fileName = results["file"];
  final int frequency = int.parse(results["freq"]);
  print('---------------------------------------------------------------\n\n');
  print('Running the script with the following parameters: File/Dir: \'$fileName\', Checked frequency: $frequency');
  print('\n---------------------------------------------------------------\n\n');

  await Worker(path: fileName, frequency: frequency).run();

}
