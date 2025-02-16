#include <libtwili/parser.hpp>
#include "json_render.hpp"
#include "package.hpp"
#include <sstream>
#include <map>
#include <regex>
#include <iostream>

using namespace std;

extern std::map<std::string, std::string> documentations;
extern std::map<std::string, std::string> excerpts;

static void merge_objects(boost::json::object& target, const boost::json::object& source)
{
  for (auto it = source.begin() ; it != source.end() ; ++it)
    target.emplace(it->key(), it->value());
}

template<typename MODEL>
static boost::json::object metadata_for(const Options& options, const MODEL& model)
{
  const string& target = model.from_file;
  boost::json::object result;

  for (auto it = options.metadata.begin() ; it != options.metadata.end() ; ++it)
  {
    regex pattern(it->key().data());

    if (sregex_iterator(target.begin(), target.end(), pattern) != sregex_iterator())
      merge_objects(result, it->value().as_object());
  }
  return result;
}

template<typename MODEL>
static std::string include_path_for(const MODEL& model, const boost::json::object& metadata)
{
  if (metadata.if_contains("include"))
    return metadata.at("include").as_string().data() + model.include_path;
  if (model.include_path.length() > 0)
    return model.include_path.substr(1);
  return model.include_path;
}

static string json_key_value(const string& a, const string& b)
{
  stringstream stream;
  stream << '"' << a << "\": \"" << b << '"';
  return stream.str();
}

static string json_key_value(const string& a, const vector<string>& b)
{
  stringstream stream;
  bool first = true;
  stream << '"' << a << "\": [";
  for (const string& entry : b)
  {
    if (!first)
      stream << ',';
    stream << '"' << entry << '"';
    first = false;
  }
  stream << ']';
  return stream.str();
}

static string json_key_value(const string& a, bool b)
{
  stringstream stream;
  stream << '"' << a << "\": " << (b ? "true" : "false");
  return stream.str();
}

static string json_key_value(const string& a, long long b)
{
  stringstream stream;
  stream << '"' << a << "\": " << b;
  return stream.str();
}

static string json_key_value(const string& a, int b)
{
  stringstream stream;
  stream << '"' << a << "\": " << b;
  return stream.str();
}

static string json_key_value(const string& a, const vector<pair<string, long long>>& flags)
{
  stringstream stream;
  bool first = true;

  stream << '"' << a << "\":[";
  for (const auto& flag : flags)
  {
    if (!first)
      stream << ',';
    stream
      << '{'
      << json_key_value("key", flag.first) << ','
      << json_key_value("value", flag.second)
      << '}';
    first = false;
  }
  stream << ']';
  return stream.str();
}

static string json_param_definition(const ParamDefinition& param)
{
  stringstream stream;

  stream << '{'
    << json_key_value("const", param.is_const) << ','
    << json_key_value("ref", param.is_reference) << ','
    << json_key_value("ptr", param.is_pointer) << ','
    << json_key_value("type", std::string(param));
  if (param.name.length() > 0)
    stream << ',' << json_key_value("name", param.name);
  if (param.type_alias.length() > 0)
    stream << ',' << json_key_value("alias", param.type_alias);
  stream << '}';
  return stream.str();
}

static string json_field_definition(const FieldDefinition& param, const std::string& doc_dir)
{
  stringstream stream;

  stream << '{'
    << json_key_value("const", param.is_const) << ','
    << json_key_value("ref", param.is_reference) << ','
    << json_key_value("ptr", param.is_pointer) << ','
    << json_key_value("type", std::string(param)) << ','
    << json_key_value("visibility", param.visibility) << ','
    << json_key_value("static", param.is_static);
  if (param.name.length() > 0)
    stream << ',' << json_key_value("name", param.name);
  if (param.type_alias.length() > 0)
    stream << ',' << json_key_value("alias", param.type_alias);
  if (doc_dir.length())
  {
    auto doc = documentations.find(doc_dir + "::" + param.name);
    if (doc != documentations.end())
      stream << ',' << json_key_value("doc", doc->second) << endl;
  }
  stream << '}';
  return stream.str();
}

static string json_template_parameter(const TemplateParameter& param)
{
  stringstream stream;

  stream << '{'
    << json_key_value("type", param.type) << ','
    << json_key_value("name", param.name);
  if (param.default_value.length() > 0)
    stream << ',' << json_key_value("default", param.default_value);
  stream << '}';
  return stream.str();
}

static string json_key_value(const string& a, const vector<ParamDefinition>& params)
{
  stringstream stream;
  bool first = true;

  stream << '"' << a << "\": [";
  for (const auto& param : params)
  {
    if (!first) stream << ',';
    stream << json_param_definition(param);
    first = false;
  }
  stream << ']';
  return stream.str();
}

static string json_key_value(const string& a, const TemplateParameters& params)
{
  stringstream stream;
  bool first = true;

  stream << '"' << a << "\": [";
  for (const auto& param : params)
  {
    if (!first) stream << ',';
    stream << json_template_parameter(param);
    first = false;
  }
  stream << ']';
  return stream.str();
}

static string json_key_value(const string& a, const vector<FieldDefinition>& fields, const std::string& doc_dir)
{
  stringstream stream;
  bool first = true;

  stream << '"' << a << "\":[";
  for (const auto& field : fields)
  {
    if (!first) stream << ',';
    stream << json_field_definition(field, doc_dir);
    first = false;
  }
  stream << ']';
  return stream.str();
}

static string json_key_value(const string& a, const vector<MethodDefinition>& methods, const string& doc_dir)
{
  bool first = true;
  stringstream stream;

  stream << '"' << a << "\": [" << endl;
  for (const auto& method : methods)
  {
    if (!first)
      stream << ',';
    stream
      << '{' << endl;
    if (method.template_parameters.size() > 0)
      stream << "  " << json_key_value("template_params", method.template_parameters) << ',' << endl;
    if (method.return_type)
      stream << "  \"returns\": " << json_param_definition(*method.return_type) << ',' << endl;
    if (method.is_pure_virtual)
      stream << "  " << json_key_value("virtual", 2) << ',' << endl;
    else if (method.is_virtual)
      stream << "  " << json_key_value("virtual", 1) << ',' << endl;
    if (method.is_variadic)
      stream << "  " << json_key_value("variadic", method.is_variadic) << ',' << endl;
    if (method.is_const)
      stream << "  " << json_key_value("const", method.is_const) << ',' << endl;
    if (doc_dir.length())
    {
      auto doc = documentations.find(doc_dir + "::" + method.name);
      if (doc != documentations.end())
        stream << json_key_value("doc", doc->second) << ',' << endl;
    }
    stream
      << "  " << json_key_value("static", method.is_static) << ',' << endl
      << "  " << json_key_value("name", method.name) << ',' << endl
      << "  " << json_key_value("visibility", method.visibility) << ',' << endl
      << "  " << json_key_value("params", method.params) << endl;
    stream << '}' << endl;
    first = false;
  }
  stream << ']' << endl;
  return stream.str();
}

static string json_key_escaped_value(const string& a, const string& b)
{
  stringstream stream;

  stream << '"' << a << "\": \"";
  for (int i = 0 ; i < b.length() ; ++i)
  {
    if (b[i] == '\n' || b[i] == '\r')
      continue ;
    if (b[i] == '\\' || b[i] == '"')
      stream << '\\';
    stream << b[i];
  }
  stream << '"';
  return stream.str();
}

static string json_key_value(const string& a, const PackageList& packages)
{
  stringstream stream;
  bool first = true;

  stream << '"' << a << "\": [";
  for (const auto& package : packages.packages)
  {
    if (!first) stream << ',';
    stream << '{'
           << json_key_value("package", package);
    if (packages.excerpts.find(package) != packages.excerpts.end())
      stream << ',' << json_key_escaped_value("excerpt", packages.excerpts.at(package));
    stream << '}';
    first = false;
  }
  stream << ']';
  return stream.str();
}

typedef void (JsonRenderer::*JsonRenderMethod)(TwiliParser&);

void JsonRenderer::operator()(TwiliParser& parser, const PackageList& packages)
{
  vector<JsonRenderMethod> renderers = {
    &JsonRenderer::render_types,
    &JsonRenderer::render_classes,
    &JsonRenderer::render_functions,
    &JsonRenderer::render_namespaces,
    &JsonRenderer::render_enums
  };

  source << '{' << endl;
  source << json_key_value("project", options.project_name) << ',' << endl;
  source << json_key_value("icon", options.project_icon) << ',' << endl;
  source << json_key_value("packages", packages) << endl;
  for (JsonRenderMethod renderer : renderers)
  {
    source << ',';
    (this->*renderer)(parser);
  }
  source << '}';
  source.close();
}

void JsonRenderer::render_types(TwiliParser& parser)
{
  bool first = true;

  source
    << "  \"types\": [" << endl;
  for (const auto& type : parser.get_types())
  {
    if (!first)
      source << ',' << endl;
    source
      << '{' << endl
      << json_key_value("kind", static_cast<int>(type.kind)) << ',' << endl
      << json_key_value("raw_name", type.raw_name) << ',' << endl
      << json_key_value("name", type.name) << ',' << endl
      << json_key_value("scopes", type.scopes) << ',' << endl
      << json_key_value("full_name", type.type_full_name) << ',' << endl
      << json_key_value("is_const", type.is_const) << ',' << endl
      << json_key_value("ref", type.is_reference) << ',' << endl
      << json_key_value("ptr", type.is_pointer) << endl
      << '}' << endl;
    first = false;
  }
  source << "  ]";
}

static string add_metadata(const boost::json::object& metadata)
{
  stringstream source;

  if (metadata.if_contains("module"))
    source << json_key_value("module", string(metadata.at("module").as_string().data())) << ',' << endl;
  if (metadata.if_contains("link"))
    source << json_key_value("link", string(metadata.at("link").as_string().data())) << ',' << endl;
  if (metadata.if_contains("cmake"))
    source << json_key_value("cmake", string(metadata.at("cmake").as_string().data())) << ',' << endl;
  return source.str();
}

void JsonRenderer::render_classes(TwiliParser& parser)
{
  bool first = true;

  source
    << "  \"classes\": [" << endl;
  for (const auto& klass : parser.get_classes())
  {
    boost::json::object metadata = metadata_for(options, klass);
    auto doc = documentations.find(klass.full_name);
    auto excerpt = excerpts.find(klass.full_name);

    if (!first)
      source << ',' << endl;
    source
     << '{' << endl
     << json_key_value("type", klass.type) << ',' << endl
     << json_key_value("name", klass.name) << ',' << endl
     << json_key_value("full_name", klass.full_name) << ',' << endl
     << json_key_value("inherits", klass.bases) << ',' << endl
     << add_metadata(metadata)
     << json_key_value("include", include_path_for(klass, metadata)) << ',' << endl;
    if (klass.template_parameters.size() > 0)
      source << json_key_value("template_params", klass.template_parameters) << ',' << endl;
    if (doc != documentations.end())
      source << json_key_value("doc", doc->second) << ',' << endl;
    if (excerpt != excerpts.end())
      source << json_key_escaped_value("excerpt", excerpt->second) << ',' << endl;
    source
     << json_key_value("constructors", klass.constructors, "") << ',' << endl
     << json_key_value("methods", klass.methods, klass.full_name) << ',' << endl
     << json_key_value("fields", klass.fields, klass.full_name) << endl
     << '}' << endl;
     first = false;
  }
  source
    << "  ]";
}

void JsonRenderer::render_functions(TwiliParser& parser)
{
  bool first = true;

  source
    << "  \"functions\": [" << endl;
  for (const auto& func : parser.get_functions())
  {
    boost::json::object metadata = metadata_for(options, func);
    auto doc = documentations.find(func.full_name);
    auto excerpt = excerpts.find(func.full_name);

    if (!first)
      source << ',' << endl;
    source
      << '{' << endl
      << json_key_value("name", func.name) << ',' << endl;
    if (doc != documentations.end())
      source << json_key_value("doc", doc->second) << ',' << endl;
    if (excerpt != excerpts.end())
      source << json_key_escaped_value("excerpt", excerpt->second) << ',' << endl;
    if (func.return_type)
      source << "\"returns\": " << json_param_definition(*func.return_type) << ',' << endl;
    if (func.template_parameters.size() > 0)
      source << json_key_value("template_params", func.template_parameters) << ',' << endl;
    if (func.is_variadic)
      source << json_key_value("variadic", func.is_variadic) << ',' << endl;
    source
      << json_key_value("full_name", func.full_name) << ',' << endl
      << json_key_value("params", func.params) << ',' << endl
      << add_metadata(metadata)
      << json_key_value("include", include_path_for(func, metadata)) << endl
      << '}' << endl;
    first =  false;
  }
  source << "  ]";
}

void JsonRenderer::render_namespaces(TwiliParser& parser)
{
  bool first = true;

  source
    << "  \"namespaces\": [" << endl;
  for (const auto& ns : parser.get_namespaces())
  {
    if (!first)
      source << ',' << endl;
    source
      << '{' << endl
      << json_key_value("name", ns.name) << ',' << endl
      << json_key_value("full_name", ns.full_name) << endl
      << '}' << endl;
    first = false;
  }
  source
    << "  ]" << endl;
}

void JsonRenderer::render_enums(TwiliParser& parser)
{
  bool first = true;

  source
    << "\"enums\":[" << endl;
  for (const auto& en : parser.get_enums())
  {
    boost::json::object metadata = metadata_for(options, en);

    if (!first)
      source << ',' << endl;
    source
      << '{' << endl
      << json_key_value("name", en.name) << ',' << endl
      << json_key_value("full_name", en.full_name) << ',' << endl
      << add_metadata(metadata)
      << json_key_value("values", en.flags) << endl
      << '}' << endl;
    first = false;
  }
  source
    << ']' << endl;
}

