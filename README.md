Twilidoc
========

Twilidoc is a documentatin generator for C++. It has two major objectives:
- Non-intrusive documentation: I do not need nor do I like having comments in my headers. They only get harder to read.
- Easy, pretty and dynamic web interface

Twilidoc is composed of a Ruby script that parses C++ and generate a JSON object containing the description of your
project.
An HTML/Javascript application then use the JSON file to provide an easy to use interface to browse your project
classes and display the corresponding documentation for classes and their methods/attributes.

What are you in for ?
==
Well you can check out this url for a demonstration:
http://fallout-equestria.googlecode.com/git/doc/blank.html

Howto
==
The ruby script from main.rb harvests data from your code to generate a json file describing your project:

    ruby main.rb -i project.yml -o doc

The input file project.yml contains some configuration values about where to find your headers and other informations
about your project.
It kinda looks like this:

    name: "You're project's name"
    includes:
      - "include_directory"
      - "other_directory"
    description: |
      <h5>Homepage</h5>
      You're project's homepage.

The includes directories are searched recursively. You can also pair your headers with yml files to add further informations:

    SomeClass:
      methods:
        - name:  'SomeMethod'
          short: 'A short description of the method'
          desc:  'More details'
      attributes:
        - name:  'some_attribute'
        - short: 'desc is not mandatory'
        
The output for the main.rb script is the directory where you have the charisma-doc installed.
That's all.

Unsupported features
==
The parser is not yet complete. Here is a list of unsupported C++ features:
- Templates
- Enums
