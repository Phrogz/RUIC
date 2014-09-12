# What is RUIC?
_TODO: Documentation in progress_

# Requirements
_TODO: Pure Ruby, except that you need Nokogiri to compile._

# Installing

    gem install ruic

# Using the RUIC DSL

_TODO: basically, `ruic myscript.ruic`; see test for examples_

# Known Limitations / TODO
_In decreasing priority…_

- Report on image assets, their sizes
- Report used assets (and where they are used)
- Report unused assets (in a format suitable for automated destruction)
- Report missing assets (and who was looking for them)
- Gobs more unit tests
- Parse .material files
- Parse .lua files (in case one references an image)
- Parse render plugins
- Read/edit animation tracks
- Find all colors, and where they are used
- Path to element
- `element/'relative.path.resolving'`
- Visual actions for State Machines
- Create new presentation assets (e.g. add a new sphere)
- Modify the scene graph of presentations
- Create new presentations/applications from code
- Report on image asset file formats (e.g. find PNGs, find DXT1 vs DXT3 vs DXT Luminance…)

# History
* _In development, no releases yet._

# License
Copyright © 2014 [Gavin Kistner](mailto:!@phrogz.net)

Licensed under the [MIT License](http://opensource.org/licenses/MIT). See the `LICENSE` file for more details.
