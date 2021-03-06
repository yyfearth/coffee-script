// Generated by eXtraCoffeeScript 1.6.2
(function() {
  var fs, path;

  fs = require('fs');

  path = require('path');

  exports.imports = function(code, options) {
    var chk_file, cwd, filename, imported, parse, regex, regex_g;
    if (options == null) {
      options = {};
    }
    regex = options.regex || /^\s*import\s+(['"])(.+)\1[;\s]*$/;
    regex.pos = options.regex_pos || 2;
    regex_g = new RegExp(regex.source, 'gm');
    if (!regex.test) {
      return code;
    }
    chk_file = function(filename) {
      var e, stats;
      try {
        stats = fs.lstatSync(filename);
        return !stats.isDirectory();
      } catch (_error) {
        e = _error;
        return false;
      }
    };
    filename = options.filename || null;
    cwd = process.cwd();
    imported = {};
    return (parse = function(code, filename) {
      return code.replace(regex_g, function(match) {
        var dir, ext, exts, f, import_code, is_js, rmk, _filename, _is_js;
        match = match.match(regex);
        dir = filename ? path.dirname(fs.realpathSync(filename)) : cwd;
        _filename = f = path.resolve(dir, match[regex.pos]);
        if (!chk_file(_filename)) {
          _filename = null;
          exts = ['.coffee', '.js'];
          while (!_filename && (ext = exts.shift())) {
            if (chk_file(f + ext)) {
              _filename = f + ext;
            }
          }
          if (!_filename) {
            throw "In " + filename + ", cannot find import: " + f;
          }
        }
        if (imported[_filename]) {
          throw "In " + filename + ", find duplicate import: " + _filename;
        }
        is_js = /\.js$/.test(filename);
        _is_js = /\.js$/.test(_filename);
        if (is_js && !_is_js) {
          throw "In " + filename + ", Js file cannot include non-js file " + _filename;
        }
        import_code = fs.readFileSync(_filename, 'utf8');
        imported[_filename] = true;
        import_code = parse(import_code, _filename);
        if (is_js !== _is_js) {
          import_code = "`" + (import_code.replace(/`/g, '\\x60')) + "`";
        }
        rmk = /\.js$/.test(filename) ? "/* imported " + _filename + " */" : "### imported " + _filename + " ###";
        return "" + rmk + "\n" + import_code + "\n\n";
      });
    })(code, filename);
  };

}).call(this);
