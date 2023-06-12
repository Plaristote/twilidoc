#pragma once
#include <string>
#include <list>
#include <boost/json.hpp>

class TwiliParser;

struct Options
{
  std::string         project_name, project_icon;
  std::string         output_file;
  std::string         output_dir;
  std::string         doc_root;
  std::string         initializer_name;
  int                 clang_argc;
  const char**        clang_argv;
  boost::json::object metadata;

  bool operator()(int ac, const char**av, TwiliParser& parser);
  bool operator()(const boost::json::object&, TwiliParser& parser);

private:
  std::list<std::string> cflags;
};
