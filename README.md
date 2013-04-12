Twilidoc
========

Twilidoc is a documentatin generator for C++. It has two major objectives:
- Non-intrusive documentation: I do not need nor do I like having comments in my headers. They only get harder to read.
- Easy, pretty and dynamic web interface

Twilidoc is composed of a Ruby script that parses C++ and generate a JSON object containing the description of your
project.
An HTML/Javascript application then use the JSON file to provide an easy to use interface to browse your project
classes and display the corresponding documentation for classes and their methods/attributes.

Unsupported features
==
The parser is not yet complete. Here is a list of unsupported C++ features:
- Templates
- Enums
- Namespaces (wip)

Howto
==
TODO
