#include <md4c.h>
#include <md4c-html.h>
#include <libtwili/parser.hpp>
#include <fstream>
#include "documentation.hpp"
#include "package.hpp"
#include <map>
#include <regex>
#include <filesystem>
#include <iostream>
#include <crails/utils/split.hpp>

using namespace std;

std::map<std::string, std::string> documentations;
std::map<std::string, std::string> excerpts;

static std::string slasherize(const std::string& name)
{
  string result;

  for (int i = 0 ; i < name.length() ; ++i)
  {
    if (name[i] == ':' && name[i + 1] == ':')
    {
      result += '/';
      i++;
    }
    else
      result += name[i];
  }
  return result;
}

static string type_link(const string& uri, const string& type_name, const string& type_full_name, const string& target = "_self")
{
  return string("<a ")
    + "class=\"btn btn-outline-primary btn-sm btn-cpptype\" "
    + "data-cpptype=\"" + type_full_name + "\" "
    + "href=\"" + uri + "\" "
    + "target=\"" + target + "\">"
    + type_name
    + "</a>";
}

static const map<TypeKind, string> uri_scope_by_kind{
  {ClassKind,   "classes"},
  {StructKind,  "classes"},
  {TypedefKind, "typedef"},
  {EnumKind,    "enums"}
};

static string emplace_types(const string& source, const DocumentationContext& context)
{
  static const regex find_types("\\[(::)?[a-zA-Z_][a-zA-Z0-9:<>()_]*\\]", regex_constants::ECMAScript | regex_constants::optimize);
  const TwiliParser& cpp = context.parser;
  string output;
  size_t last_position = 0;

  auto matches = sregex_iterator(source.begin(), source.end(), find_types);

  for (auto it = matches ; it != sregex_iterator() ; ++it)
  {
    smatch match = *it;
    string type_name = source.substr(match.position(0) + 1, match.length(0) - 2);
    TypeDefinition type;
    optional<TypeDefinition> parent_type;

    type.declaration_scope = Crails::split<string, vector<string>>(context.full_name, ':');
    type.load_from(type_name, cpp.get_types());
    parent_type = type.find_parent_type(cpp.get_types());
    type.type_full_name = type.solve_type(cpp.get_types());
    if (type.type_full_name.length() > 0)
    {
      auto uri_scope = parent_type ? uri_scope_by_kind.find(parent_type->kind) : uri_scope_by_kind.end();
      string link;

      if (type_name.find("::") == 0)
        type.type_full_name = type_name;
      if (uri_scope != uri_scope_by_kind.end())
        link = "#/" + uri_scope->second + '/' + type.type_full_name;
      output += source.substr(last_position, match.position(0) - last_position);
      output += type_link(link, type_name, type.type_full_name);
      last_position = match.position(0) + match.length(0);
    }
    else
    {
      auto namespaces = cpp.get_namespaces();
      auto ns_it = std::find(namespaces.begin(), namespaces.end(), type_name);

      if (ns_it != namespaces.end())
      {
        output += source.substr(last_position, match.position(0) - last_position);
        output += type_link(
          "#/namespaces/" + ns_it->full_name,
          type_name,
          ns_it->full_name
        );
        last_position = match.position(0) + match.length(0);
      }
    }
  }
  output += source.substr(last_position);
  return output;
}

static void collect_excerpt(const string& source, DocumentationContext& context)
{
  auto end_position = source.find("</p>");

  if (context.excerpt.length() == 0)
  {
    auto start_position = source.find("<p>");
    if (start_position != string::npos)
      context.excerpt += source.substr(start_position, 256);
    return ;
  }
  if (end_position != string::npos)
  {
    context.excerpt += source.substr(0, end_position) + "</p>";
    context.excerpt_done = true;
  }
  else if (context.excerpt.length() + source.length() >= 256)
  {
    context.excerpt += source.substr(0, 256 - context.excerpt.length()) + "...</p>";
    context.excerpt_done = true;
  }
  else
    context.excerpt += source;
}

static void md_callback(const MD_CHAR* output, MD_SIZE length, void* userdata)
{
  DocumentationContext* context = reinterpret_cast<DocumentationContext*>(userdata);
  string source(output, length);

  if (!context->excerpt_done)
    collect_excerpt(source, *context);
  context->html += emplace_types(source, *context);
}

static std::string get_documentation(const std::string& doc_root, DocumentationContext& context)
{
  const string relative_path = slasherize(context.full_name);
  filesystem::path path = doc_root + relative_path + ".md";

  //cout << "looking for file " << path << endl;
  if (filesystem::exists(path))
  {
    //cout << "- found doc file" << endl;
    ifstream file(path.string());
    string source;

    source.assign(istreambuf_iterator<char>(file),
                  istreambuf_iterator<char>());
    context.filepath = relative_path + ".html";
    md_html(source.c_str(), source.length(), md_callback, &context, 0, 0);
  }
  return context.html;
}

static void write_documentation(const DocumentationContext& context, const std::string& output_root)
{
  string relative_path = "/docs" + context.filepath;
  string twilidoc_path = output_root + relative_path;
  filesystem::create_directories(filesystem::path(twilidoc_path).parent_path());
  ofstream stream(twilidoc_path);
  stream << context.html;
  documentations.emplace(context.full_name, relative_path.substr(1));
  excerpts.emplace(context.full_name, context.excerpt);
}

static void load_package_doumentations(const std::string& doc_root, const std::string& output_root, TwiliParser& cpp, PackageList& list)
{
  for (const string& package : list.packages)
  {
    string path("/packages/" + package);
    DocumentationContext context{cpp, path};

    if (get_documentation(doc_root, context).length() > 0)
    {
      cout << "- Package doc detected: " << package << endl;
      string twilidoc_path = output_root + path + ".html";
      filesystem::create_directories(filesystem::path(twilidoc_path).parent_path());
      ofstream stream(twilidoc_path);
      stream << context.html;
      list.excerpts.emplace(package, context.excerpt);
    }
  }
}

static void load_homepage(const std::string& doc_root, const std::string& output_root, TwiliParser& cpp)
{
  string homepage_name("/twilidoc_home");
  DocumentationContext context{cpp, homepage_name};

  if (get_documentation(doc_root, context).length() > 0)
  {
    cout << "- Homepage detected" << endl;
    string twilidoc_path = output_root + "/docs/twilidoc_home.html";
    filesystem::create_directories(filesystem::path(twilidoc_path).parent_path());
    ofstream stream(twilidoc_path);
    stream << context.html;
  }
  else
    cout << "- No homepage found (looked for " << doc_root << "/twilidoc_home.md)" << endl;
}

static void load_method_documentations(const ClassDefinition& klass, const Options& options, TwiliParser& cpp)
{
  for (const auto& method : klass.methods)
  {
    string method_fullname = klass.full_name + "::" + method.name;
    DocumentationContext method_context{cpp, method_fullname};

    get_documentation(options.doc_root, method_context);
    if (method_context.html.length() > 0)
      write_documentation(method_context, options.output_dir);
  }
}

static void load_class_documentations(const Options& options, TwiliParser& cpp)
{
  for (const auto& klass : cpp.get_classes())
  {
    DocumentationContext class_context{cpp, klass.full_name};

    get_documentation(options.doc_root, class_context);
    if (class_context.html.length() > 0)
      write_documentation(class_context, options.output_dir);
    load_method_documentations(klass, options, cpp);
  }
}

static void load_function_documentations(const Options& options, TwiliParser& cpp)
{
  for (const auto& func : cpp.get_functions())
  {
    DocumentationContext class_context{cpp, func.full_name};

    get_documentation(options.doc_root, class_context);
    if (class_context.html.length() > 0)
      write_documentation(class_context, options.output_dir);
  }
}

void load_documentations(const Options& options, TwiliParser& cpp, PackageList& package)
{
  load_class_documentations(options, cpp);
  load_function_documentations(options, cpp);
  load_package_doumentations(options.doc_root, options.output_dir, cpp, package);
  load_homepage(options.doc_root, options.output_dir, cpp);
}
