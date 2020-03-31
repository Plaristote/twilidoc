Twilidoc
========

Twilidoc is a documentatin generator for C++. It has two major objectives:
- Non-intrusive documentation: no need to bloat your headers with annotations
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
Install the twilidoc gem

    gem install twilidoc

The ruby script from main.rb harvests data from your code to generate a json file describing your project:

    twilidoc -i project.yml -o doc

The input file project.yml contains some configuration values about where to find your headers and other informations
about your project.
It looks like this:

    name: "Your project's name"
    includes:
      - "include_directory"
      - "other_directory"
    description: |
      <h5>Homepage</h5>
      Your project's homepage.

The includes directories are searched recursively. You can also pair your headers with yml files to add further informations:

    SomeClass:
      overview: 'A quick description showed in popovers'
      detail: |
        <h2>Complete HTML documentation for your class.</h2>
        Types formatted as following: [SuchClass] will be replaced with buttons linking to the class' documentation.<br/>
        You may also include excerpts of code using the preformatted element: we'll SHJS to highlight your code:<br/>
        <pre>
        void main()
        {
          return 0; // This code has colors.
        }
        </pre>
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

    twilidoc -i project.yml -o doc -c preprocessed_headers.hpp

Then, if you update the documentation without having changed any headers, you can skip the preprocessor by
using the option `--source`, or `-s`:

    twilidoc -i project.yml -o doc -s preprocessed_headers.hpp

Caveats
==
* There might be some issues when commentaries and preprocessor code are met on the same lines.
* Template parameters are not clearly presented to the readers.
