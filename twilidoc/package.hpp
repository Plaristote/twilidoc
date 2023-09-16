#pragma once
#include <set>
#include <map>
#include "options.hpp"

struct PackageList
{
  std::set<std::string> packages;
  std::map<std::string, std::string> excerpts;

  void load(const Options&);
};
