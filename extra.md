# What Is eXtraCoffeeScript?

eXtraCoffeeScript is a variation of CoffeeScript with extra features: Iced Features, Import, CSON, Minify, etc.
eXtraCoffeeScript is a fork of [IcedCoffeeScript](https://github.com/maxtaco/coffee-script) which is a fork of CoffeeScript.

**eXtras:**

+ Iced Features: Introduced `await` and `defer` keywords, for more information please read [this](iced.md).
+ Import: Introduced `import` to import the external source before compiling. This feature is inspired by [Import](https://github.com/devongovett/import) but implement is totally different. Currently switch `--imports` or `-x` must be added to the executable to enable this feature.
+ CSON: Included cson library and executable to compile CSON to JSON. This feature is inspired by [cson.npm](https://github.com/balupton/cson.npm) but implement is  different. Currently use `xcson package.cson` to compile package.cson to package.json.
+Minify: Use [UglifyJS](https://github.com/mishoo/UglifyJS) to minify compiled javascript with extra switch `xcoffee --min` while using executable or option `min: true` while using library.


# Installing and Running

For now, eXtraCoffeeScript is under a heavy development period, so cannot be installed from npm package.

You can only checkout it from git repo and install from source:

    git clone https://yyfearth@github.com/yyfearth/coffee-script.git
    ./bin/cake install

This will give you libraries under `extra-coffee-script` and 
the binaries `xcoffee` and `xcake`, which are replacements
for `coffee` and `cake` respectively.  In almost all cases,
`xcoffee` should serve as a drop-in replacement for `coffee`,
since the IcedCoffeeScript language is a superset of CoffeeScript, and eXtraCoffeeScript only brings some extra features on it.

For more information about CS and ICS, you can also see
our <a href="http://maxtaco.github.com/coffee-script">brochure page</a>.

### For more language details please read the [Tutorial and Examples](iced.md)
