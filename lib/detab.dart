
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:io';
import 'package:path/path.dart' as path;

final _version = '1.0';
final _programName = 'detab';
final _programHelp = r'''
Syntax: detab [options] [file ...]

options:
  -h, --help             Show this help message
  -t <n>, --tabsize <n>  Set tabulator size (default: 4)
  -d, --detab            Convert tabs to spaces (default)
  -e, --entab            Convert spaces to tabs
  -c, --crlf             Use CRLF line endings (default)
  -l, --lf               Use LF line endings

file                     File names or file name templates (wildcards * and ? allowed).
                         If no file names are specified, the program will search for files
                         in the current directory and all subdirectories.
                         If no files are found, the program will exit without error.
''';

void detabMain(List<String> arguments) async
{
  final fileTemplates = <String>[];
  bool setTabulator = false;
  int tabulator = 4;
  bool detab = true;
  bool crlf = true;

  print ('$_programName v$_version');

  if (arguments.isEmpty)
  {
    print(_programHelp);
    return;
  }

  // Parse arguments
  for (var arg in arguments)
  {
    if (setTabulator)
    {
      final t = int.tryParse(arg);
      if (t == null)
      {
        print('Invalid tabulator size: $arg');
        return;
      }
      tabulator = t;
      setTabulator = false;
    }
    else if (arg.startsWith('-'))
    {
      switch (arg)
      {
        case '-h':
        case '--help':
          print(_programHelp);
          return;

        case '-t':
        case '--tabsize':
          setTabulator = true;
          break;

        case '-d':
        case '--detab':
          detab = true;
          break;

        case '-e':
        case '--entab':
          detab = false;
          break;

        case '-c':
        case '--crlf':
          crlf = true;
          break;

        case '-l':
        case '--lf':
          crlf = false;
          break;

        default:
          print('Unknown option: $arg');
          return;
      }
    }
    else
    {
      fileTemplates.add(arg);
    }
  }

  print ("Search files...");
  final files = getFiles(fileTemplates);
  print ("${files.length} files found");
  
  for (var file in files)
  {
    final changed = processFile(fileName: file, entabMode: !detab, tabulator: tabulator, crlf: crlf);
    if (changed)
    {
      print('Changed: $file');
    }
  }
}

List<String> getFiles(List<String> fileTemplates)
{
  final files = <String>[];
  for (var fileTemplate in fileTemplates)
  {
    if (fileTemplate.contains('*') || fileTemplate.contains('?'))
    {
      final delim = fileTemplate.lastIndexOf("/");
      var dirName = "./";

      if (delim >= 0  )
      {
        dirName = fileTemplate.substring(0, delim);
        fileTemplate = fileTemplate.substring(delim + 1);
      }

      fileTemplate = RegExp.escape(fileTemplate);
      fileTemplate = '^'+fileTemplate.replaceAll(r'\*', '.*').replaceAll(r'\?', '.?')+r'$';
      final templateRegexp = RegExp(fileTemplate);

      final dir = Directory(dirName);
      if (dir.existsSync())
      {
        final list = dir.listSync(recursive: true);
        for (var f in list)
        {
          if (f is File && templateRegexp.hasMatch(path.basename(f.path)))
          {
            files.add(f.path);
          }
        }
      }
      else
      {
        print('Directory not found: $fileTemplate');
      }
      continue;
    }
    else
    {
      final file = File(fileTemplate);
      if (file.existsSync())
      {
        files.add(fileTemplate);
      }
    }
  }
  return files;
}

bool processFile({required String fileName,required bool entabMode,required int tabulator, required bool crlf})
{
  bool result = false;
  final lineRegex = RegExp(r'(\n|\r\n|\r)',multiLine: true);

  try
  {
    final file = File(fileName);
    final text = file.readAsStringSync();
    final lines = text.split(lineRegex);
    final sb = StringBuffer();

    if (lines.isNotEmpty && lines.last.isEmpty)
    {
      lines.removeLast();
    }

    for (var line in lines)
    {
      if (entabMode)
      {
        line = entab(line, tabulator);
      }
      else
      {
        line = detab(line, tabulator);
      }

      sb.write(line);
      sb.write(crlf ? '\r\n' : '\n');
    }

    final outText = sb.toString();

    if (outText != text)
    {
      final backPath = fileName + '.bak';
      final backFile = File(backPath);
      if (backFile.existsSync())
      {
        backFile.deleteSync();
      }
      file.renameSync(backPath);
      file.writeAsStringSync(outText);
      result = true;
    }
  }
  catch (e)
  {
    print('Error processing file: $fileName');
    print(e);
  }

  return result;
}


String detab(String line, int tabulator)
{
  final sb = StringBuffer();
  var pos = 0;
  for (var c in line.split(''))
  {
    if (c == '\t')
    {
      final spaces = tabulator - (pos % tabulator);
      sb.write(' ' * spaces);
      pos += spaces;
    }
    else
    {
      sb.write(c);
      pos++;
    }
  }
  return sb.toString();
}

String entab(String line, int tabulator)
{
  final sb = StringBuffer();
  var pos = 0;
  var spaces = 0;
  for (var c in line.split(''))
  {
    if (c == ' ')
    {
      spaces++;
      pos++;
    }
    else if (c == '\t')
    {
      spaces += tabulator - (pos % tabulator);
      pos += tabulator - (pos % tabulator);
    }
    else
    {
      if (spaces > 0)
      {
        final tabs = spaces ~/ tabulator;
        final spaces2 = spaces % tabulator;
        sb.write('\t' * tabs);
        sb.write(' ' * spaces2);
        pos += spaces;
        spaces = 0;
      }
      sb.write(c);
      pos++;
    }
  }
  return sb.toString();
}
