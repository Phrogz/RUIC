# What is RUIC?
RUIC is a Ruby API for reading, analyzing, and manipulating application assets created by NVIDIA's [UI Composer](http://uicomposer.nvidia.com). Among other things, it allows you to:

* See if an application is missing any assets (e.g. images or meshes) and what parts of the application are looking for those.
* See if there are any files in the application folder that you can delete (e.g. images or materials that are no longer being used).
* Read and modify the attributes of elements on different slides.
* Batch change attributes (e.g. change all usage of one font or color to another).
* Procedurally generate many models with automated placement in your scene.

_Some of the features above are planned, but not yet implemented; see Known Limitations below._

## Table of Contents
* Installing RUIC
* Using the RUIC DSL
  * Creating and Accessing Applications
  * Working with Presentations
  * Writing Assertions
  * Locating MetaData.xml
* Known Limitations (aka TODO)
* History
* License



# Installing RUIC
RUIC can be installed via RubyGems (part of Ruby) via the command:

    gem install ruic   # May need `sudo gem install ruic` depending on your setup

Although RUIC is a pure-Ruby library, it relies on [Nokogiri](http://nokogiri.org) for all the XML processing and manipulation. Installing RUIC will also automatically install Nokogiri, which may require some compilation.



# Using the RUIC DSL

RUIC scripts are pure Ruby with a few convenience methods added. You run them via the `ruic` command-line script, e.g.

    ruic myscript.ruic  # or .rb extension, for syntax highlighting while editing


## Creating and Accessing Applications
RUIC scripts must start with `uia` commands to load an application and all its assets.
After this you can access the application as `app`:

```ruby
uia '../MyApp.uia'      # Relative to the ruic script file, or absolute
   
show app.file           #=> /var/projects/UIC/MyApp/main/MyApp.uia
show app.filename       #=> MyApp.uia

show app.assets.count   #=> 7
# You can ask for app.behaviors, app.presentations, app.statemachines, and app.renderplugins
# for arrays of specific asset types
```

_The `show` command prints the result output; it is simply a nicer alias for `puts`._

If you need to load multiple applications in the same script, subsequent `uia` commands will create
`app2`, `app3`, etc. for you to use.

```ruby
uia '../MyApp.uia'       # Available as 'app'
uia '../../v1/MyApp.uia' # Available as 'app2'
```


## Working with Presentations

```ruby
uia '../MyApp.uia'

main = app.main_presentation   # The presentation displayed as the main presentation (regardless of id)
sub  = app['#nav']             # You can ask for an asset based on the id in the .uia...
sub  = app['Navigation.uip']   # or based on the path to the file (relative to the .uia)


car = sub/"Scene.Vehicle.Group.Car"      # Find elements in a presentation by presentation path…
car = app/"nav:Scene.Vehicle.Group.Car"  # …or absolute application path

show car.name #=> Car
show car.type #=> Model                  # Scene, Layer, Camera, Light, Group, Model, Material,
                                         # Image, Behavior, Effect, ReferencedMaterial, Text,
                                         # RenderPlugin, Component, (custom materials)
```

## Writing Assertions


## Locating MetaData.xml
RUIC needs access to a UIC `MetaData.xml` file to understand the properties in the various XML files.
By default RUIC will look in the location specified by `RUIC::DEFAULTMETADATA`, e.g.  
`C:/Program Files (x86)/NVIDIA Corporation/UI Composer 8.0/res/DataModelMetadata/en-us/MetaData.xml`

If this file is in another location, you can tell the script where to find it either:

* on the command line: `ruic -m path/to/MetaData.xml myscript.ruic` 
* in the ruic script: `metadata 'path/to/MetaData.xml' # before any 'app' commands`



# Known Limitations (aka TODO)
_In decreasing priority…_

- Report on image assets, their sizes
- Report used assets (and where they are used)
- Report unused assets (in a format suitable for automated destruction)
- Report missing assets (and who was looking for them)
- Gobs more unit tests
- Parse .material files
- Navigate through scene graph hierarchy (parent, children)
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
