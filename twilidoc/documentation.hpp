#pragma once
#include <string>
#include "options.hpp"

class TwiliParser;
class PackageList;

struct DocumentationContext
{
  TwiliParser&       parser;
  const std::string& full_name;
  std::string        html;
  std::string        json_value;
  std::string        filepath;
  std::string        excerpt;
  bool               excerpt_done;
};

void load_documentations(const Options& options, TwiliParser& parser, PackageList&);
