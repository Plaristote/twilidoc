#include "package.hpp"
#include <iostream>

using namespace std;

void PackageList::load(const Options& options)
{
  for (auto it = options.metadata.begin() ; it != options.metadata.end() ; ++it)
  {
    boost::json::object section = it->value().as_object();

    if (section.if_contains("module"))
      packages.insert(section.at("module").as_string().data());
    else if (section.if_contains("package"))
      packages.insert(section.at("package").as_string().data());
  }
}
