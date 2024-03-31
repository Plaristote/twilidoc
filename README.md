Twilidoc
========

Twilidoc is a documentatin generator for C++. It has two major objectives:
- Non-intrusive documentation: no need to bloat your headers with annotations
- Easy, pretty and dynamic web interface

Twilidoc uses [libtwili](https://github.com/Plaristote/libtwili), a C++ header inspector based on libclang, to probe your project's header, and generates a description of your project in JSON format that can then be opened using the [twilidoc-reader](https://github.com/Plaristote/twilidoc-reader).

All you need to do is add a simple configuration file giving general informations about your project: name, logo, some compiler option for libclang, and if you're generating documentation for a project made of several modules/packages, where each modules can be found.

You may then add additional documentation for each of your classes, methods, functions using MarkDown documents: this gives you the possibility of writing more exhaustive documentations, with code examples and URLs, without having to annotate your headers so much that they become bloated with comments.

What are you in for ?
==
Well, you can check out this url for a demonstration:
https://crails-framework.github.io/api-reference/

The source files used to generate this documentation can be found there:
https://github.com/crails-framework/api-reference

Install
==
If you do not have [build2](https://www.build2.org/) installed on your system, install it by following its [install guide](https://www.build2.org/install.xhtml).

Make sure libclang is also installed on your system.

The following command will then clone the twilidoc repository and build it along with its dependencies:

    git clone https://github.com/Plaristote/twilidoc.git

    bpkg create -d "build-gcc" cc config.cxx=g++

    cd build-gcc

    bpkg add --type dir ../twilidoc
    bpkg fetch
    bpkg build twilidoc '?sys:libclang/*'

You may then install twilidoc to your system using the following command:

    bpkg install twilidoc config.install.root=$INSTALL_DIRECTORY

Replacing $INSTALL_DIRECTORY with the name of the directory in which you want to perform the install (typically `/usr/local`, in which case you will also need to add the option `config.install.sudo=sudo`).

Usage
==

Create a `.twilidoc` file at the root of your project, such as:

```json
{
  "project": "My project name",
  "inputs": ["./include"], // your include folders here
  "cflags": [
    "-std=c++17",
    "-DTWILIDOC",
    "-I/usr/lib64/llvm13/lib/clang/13.0.1/include" // might vary depending on clang version
  ]
}
```

From the root of your project, you may then run the twilidoc compiler:

    twilidoc -o doc -d doc-src

- The `-d` option must point to the folder containing the MarkDown documents.
- The `-o` option must point to the folder where you the final result will be generated.

Once the command starts running, sit back and relax while twilidoc generates. If your project is big enough, it might take a while before the process completes.

The command should generate a `twili.json` file in the folder specified with the `-o` option. This JSON file will be loaded by the twilidoc-reader, making it able to display your project's documentation. You may download a pre-built version of the reader in the [twilidoc-reader](https://github.com/Plaristote/twilidoc-reader/releases) repository:

- extract the twilidoc-reader package in the `doc` folder
- start a HTTP server in the `doc` folder
- profit

Twilidoc Settings
==

The `.twilidoc` file can include many more options to customize your documentation. The `metadata` section
allows you to add contextual information depending on each scanned file pathes.

Include paths
=
For instance, if your library installs its header in a sub-folder, you will want all the documented include path
to be prefixed with that sub-folder name. In the following example, we add an object in the `metadata` section that
targets every filepath and defines `mylib` as prefix for all includes path:

```json
{
  "project": "My project name",
  "inputs": ["./include"],
  "metadata": {
    ".*": { "include": "mylib" }
  }
}
```

Using this configuration, the documentation for class defined in `include/myclass.hpp` would indicate that the
include directive to use would be `#include <mylib/myclass.hpp>`.

Modules
=
When you are documentating multiple libraries, rather than a single one, you may want to clearly document
which classes or functions belongs to which libraries. You may use the `metadata` section to describe such behaviors:

```json
{
  "project": "My project name",
  "inputs": ["./include"],
  "metadata": {
    "include/liba": { "module": "liba" },
    "include/libb": { "module": "libb" }
  }
}
```

With this configuration, symbols defined under the `include/liba` or `include/libb` folders will be documented as being part of the `liba` and `libb` package, and users will be able to consult the individual package documentation, as well as the symbols defined in this specific package.

Packages can have their own documentation, typically describing the library and installation instructions. Such documentations are provided in twilidoc's input path, within the `documents/packages` folder. For our example, the files would be `document/packages/liba.md` and `document/packages/libb.md`.
