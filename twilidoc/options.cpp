#include "options.hpp"
#include <libtwili/parser.hpp>
#include <list>
#include <iostream>

using namespace std;

enum OptionState
{
  InputsOption,
  OutputOption,
  DocOption,
  NoOption
};

static void print_help()
{
  cerr << "Options:" << endl
    << "  -i [ --input ] args\tlist of input files or directories" << endl
    << "  -o [ --output ] arg\toutput directory" << endl
    << "  -d [ --doc ] arg\troot directory of your documentation files" << endl
    << "  -c [ --clang ] args\tuse this option to start specifying clang's options (include paths, etc)" << endl;
}

bool Options::operator()(int ac, const char** av, TwiliParser& parser)
{
  OptionState state = NoOption;

  for (int i = 1 ; i < ac ; ++i)
  {
    if (av[i] == string("-h") || av[i] == string("--help"))
    {
      print_help();
      return false;
    }
    else if (av[i] == string("-i") || av[i] == string("--input"))
      state = InputsOption;
    else if (av[i] == string("-o") || av[i] == string("--output"))
      state = OutputOption;
    else if (av[i] == string("-d") || av[i] == string("--doc"))
      state = DocOption;
    else if (av[i] == string("-c") || av[i] == string("--clang"))
    {
      clang_argc = ac - i - 1;
      clang_argv = &av[i + 1];
      break ;
    }
    else 
    {
      switch (state)
      {
      case InputsOption:
        parser.add_directory(string(av[i]));
        break ;
      case OutputOption:
        output_dir = av[i];
        state = NoOption;
        break ;
      case DocOption:
        doc_root = av[i];
        state = NoOption;
        break ;
      default:
        cerr << "/!\\ Cannot read option \"" << av[i] << '"' << endl;
        print_help();
        return false;
      }
    }
  }
  return true;
}

bool Options::operator()(const boost::json::object& config, TwiliParser& parser)
{
  if (config.if_contains("project"))
    project_name = config.at("project").as_string();

  if (config.if_contains("logo"))
    project_icon = config.at("logo").as_string();

  if (config.if_contains("output"))
    output_dir = config.at("output").as_string();

  if (config.if_contains("docs"))
    doc_root = config.at("docs").as_string();

  if (config.if_contains("inputs"))
  {
    boost::json::array json_inputs = config.at("inputs").as_array();
    for (auto it = json_inputs.begin() ; it != json_inputs.end() ; ++it)
    {
      string tmp = it->as_string().c_str();
      parser.add_directory(tmp);
    }
  }

  if (config.if_contains("cflags"))
  {
    boost::json::array json_cflags = config.at("cflags").as_array();
    int i = 0;

    for (auto it = json_cflags.begin() ; it != json_cflags.end() ; ++it)
      cflags.push_back(it->as_string().c_str());
    clang_argc = cflags.size();
    clang_argv = new const char*[cflags.size()];
    for (const string& cflag : cflags)
      clang_argv[i++] = cflag.c_str();
  }

  if (config.if_contains("metadata"))
    metadata = config.at("metadata").as_object();
  return true;
}

