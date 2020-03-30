const gulp   = require("gulp");
const coffee = require("gulp-coffee");
const concat = require("gulp-concat");

const jsSources = [
  "js/jquery-1.12.4.js",
  "js/jquery.browser.filler.js",
  "js/jquery-ui-1.8.21.custom.min.js",
  "js/bootstrap-transition.js",
  "js/bootstrap-alert.js",
  "js/bootstrap-modal.js",
  "js/bootstrap-dropdown.js",
  "js/bootstrap-scrollspy.js",
  "js/bootstrap-tab.js",
  "js/bootstrap-tooltip.js",
  "js/bootstrap-popover.js",
  "js/bootstrap-button.js",
  "js/bootstrap-collapse.js", // optional ?
  "js/bootstrap-typeahead.js",
  "js/jquery.dataTables.min.js",
  // chart libraries
  "js/excanvas.js",
  "js/jquery.flot.min.js",
  "js/jquery.flot.pie.min.js",
  "js/jquery.flot.stack.js",
  "js/jquery.flot.resize.min.js",
  // other jquery plugins
  //"js/jquery.chosen.min.js",
  "js/jquery.uniform.min.js",
  "js/jquery.colorbox.min.js",
  "js/jquery.autogrow-textarea.js",
  "js/charisma.js",
  // C++ syntax highlightening
  "js/sh_main.js",
  "js/sh_cpp.min.js",
  // UML diagrams
  "js/json2.js",
  "js/raphael.js",
  "js/joint.js",
  "js/joint.arrows.js",
  "js/joint.dia.js",
  "js/joint.dia.uml.js",
  // Twilidoc source
  "js/twilidoc-uml.js",
  "js/twilidoc.js"
];

gulp.task("css", function() {
  return gulp.src("css/*.css")
        .pipe(concat("twilidoc.css"))
        .pipe(gulp.dest("dist/"));
});

gulp.task("coffee", function() {
  return gulp.src("src/*.coffee")
        .pipe(coffee())
        .pipe(gulp.dest("js/"));
});

gulp.task("js", function() {
  return gulp.src(jsSources)
        .pipe(concat("twilidoc.js"))
        .pipe(gulp.dest("dist/"));
});

gulp.task("scripts", gulp.series("coffee", "js"));

gulp.task("build", gulp.parallel("scripts", "css"));
