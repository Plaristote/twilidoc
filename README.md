Twilidoc
========

Twilidoc is a documentatin generator for C++. It has two major objectives:
- Non-intrusive documentation: I do not need nor do I like having comments in my headers. They only get harder to read.
- Easy, pretty and dynamic web interface

Twilidoc is composed of a Ruby script that probes C++ headers and generate a JSON object containing the description of your
project.
A Coffeescript application then use the JSON file to provide an easy to use interface to browse your project
classes and display the corresponding documentation for classes and their methods/attributes.

This is still experimental. Many features will be implemented along the way, there are a few known issues, and probably
a lot of unknown issues. Still, I've had it work perfectly with several projects including thousands of lines of code.

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
It looks like this:

    name: "Your project's name"
    includes:
      - "include_directory"
      - "other_directory"
    description: |
      <h5>Homepage</h5>
      You're project's homepage.

The includes directories are searched recursively. You can also pair your headers with yml files to add further informations:

    SomeClass:
      overview: 'A quick description showed in popovers'
      methods:
        #N.B: The names are optional. Just describe the method in the order of declaration in the header
        - name:  'SomeMethod'
          short: 'A short description of the method'
          desc:  'More details'
      attributes:
        - name:  'some_attribute'
        - short: 'desc is not mandatory'

The output (option -o) for the main.rb script is the directory where you have copied the charisma-doc directory.
That's all.

Skipping the preprocessor
===
Twilidoc can save a copy of the preprocessed headers. The preprocessor is usually the longest task during the
probe. You may save the headers using the option `--compile`, or `-c`:

    ruby main.rb -i project.yml -o doc -c preprocessed_headers.hpp

Then, if you update the documentation without having changed any headers, you can skip the preprocessor by
using the option `--source`, or `-s`:

    ruby main.rb -i project.yml -o doc -s preprocessed_headers.hpp

Further Documentation
==
`Sadly, this feature is not supported for Opera and Chrome`
You also have the possibility to write further documentation about a class by writing partial html files.
They will be appended to the documentation of the object you wish to document.

Everytime an object is loaded, Twilidoc will look for a 'docs/classname.html' file. For instance if your
class is named `MyNamespace::MyClass`, Twilidoc will try to load `docs/MyNamespace::MyClass.html`.

You may also use this feature to write samples of C++ code, which will automatically be provided with syntax
coloration.
Also note that writing `[MyNamespace::MyClass]` will create a link to the class' documentation.

Caveats
==
There might be some issues when commentaries and preprocessor code are met on the same lines.
As far as I know everything else seems to be working fine.

Feature Plan
==
+ Better UML widget
+ Support for git
--> Display for users who worked on a file
--> Display timeline of a class by using the modifications times and change count from git
--> Find the buggiest parts by using 
