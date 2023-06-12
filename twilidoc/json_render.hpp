#pragma once
#include <filesystem>
#include <fstream>
#include "options.hpp"

class TwiliParser;
class PackageList;

class JsonRenderer
{
  const Options& options;
  std::ofstream source;
public:
  JsonRenderer(const Options& a) : options(a), source(options.output_file)
  {}

  void operator()(TwiliParser&, const PackageList&);

private:
  void render_types(TwiliParser&);
  void render_classes(TwiliParser&);
  void render_functions(TwiliParser&);
  void render_namespaces(TwiliParser&);
  void render_enums(TwiliParser&);
};
