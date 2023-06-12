#include <libtwili/runner.hpp>
#include <iostream>
#include <map>
#include <boost/json.hpp>
#include "options.hpp"
#include "json_render.hpp"
#include "documentation.hpp"
#include "package.hpp"

using namespace std;

void twilart(ostream&);

extern std::map<std::string, std::string> documentations;

boost::json::object load_config(const string& path)
{
  boost::json::object        result;
  boost::json::parse_options options;
  std::string                raw_json;
  std::ifstream              stream(path);

  raw_json.assign(istreambuf_iterator<char>(stream), istreambuf_iterator<char>());
  options.allow_comments = options.allow_trailing_commas = true;
  if (raw_json.length() > 0)
  {
    try
    {
      result = boost::json::parse(raw_json, {}, options).as_object();
    }
    catch (const exception& err)
    {
      cerr << "failed to load .twilidoc: " << err.what() << endl;
    }
  }
  return result;
}

int main (int argc, const char* argv[])
{
  TwiliParser parser;
  PackageList packages;
  Options options;
  boost::json::object config = load_config(".twilidoc");
  string output_dir = ".";

  if (!options(config,parser))
    return -1;
  if (!options(argc, argv, parser))
    return -1;
  options.output_file = options.output_dir + "/twili.json";
  twilart(cout);
  packages.load(options);
  if (!probe_and_run_parser(parser, options.clang_argc, options.clang_argv))
    return -1;
  if (options.doc_root.length() > 0)
  {
    cout << "- Loading documentation from " << options.doc_root << endl;
    load_documentations(options, parser, packages);
  }
  {
    JsonRenderer json_renderer(options);

    cout << "- Rendering JSON data to " << options.output_file << endl;
    json_renderer(parser, packages);
  }
  cout << "Done." << endl;
  return 0;
}
