Gem::Specification.new do |s|
  s.name        = "twilidoc"
  s.version     = "0.1.0"
  s.date        = "2020-03-30"
  s.summary     = "Webapp-styled Documentation Generator for C++"
  s.description = ""
  s.authors     = ["Michael Martin Moro"]
  s.email       = "michael@unetresgrossebite.com"
  s.homepage    = "https://github.com/Plaristote/twilidoc"
  s.files       = [
    "lib/twilidoc/hash.rb",
    "lib/twilidoc/string.rb",
    "lib/twilidoc/shell.rb",
    "lib/twilidoc/parse.rb",
    "lib/twilidoc/preprocessor.rb",
    "bin/twilidoc",
    "vendor/index.html",
    "vendor/dist/twilidoc.js",
    "vendor/dist/twilidoc.css",
    "vendor/img/glyphicons-halflings.png",
    "vendor/img/twilight-icon-2.png"
  ]
  s.executables << "twilidoc"
end
