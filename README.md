# What is RUIC?
RUIC is a Ruby API for reading, analyzing, and manipulating application assets created by NVIDIA's [UI Composer][1]. Among other things, it allows you to:

* See if an application is missing any assets (e.g. images or meshes) and what parts of the application are looking for those.
* See if there are any files in the application folder that you can delete (e.g. images or materials that are no longer being used).
* Read and modify the attributes of elements on different slides.
* Batch change attributes (e.g. change all usage of one font or color to another).
* Procedurally generate many models with automated placement in your scene.

_Some of the features above are planned, but not yet implemented; see Known Limitations below._

## Table of Contents
* [Installing RUIC](#installing-ruic)
* [Using the RUIC DSL](#using-the-ruic-dsl)
  * [Creating and Accessing Applications](#creating-and-accessing-applications)
  * [Working with Presentations](#working-with-presentations)
  * [Finding Many Assets](#finding-many-assets)
  * [Working with References](#working-with-references)
  * [Writing Assertions](#writing-assertions)
  * [Locating MetaData.xml](#locating-metadataxml)
* [Interactive RUIC](#interactive-ruic)
* [Known Limitations (aka TODO)](#known-limitations-aka-todo)
* [History](#history)
* [License & Contact](#license--contact)



# Installing RUIC
RUIC can be installed via RubyGems (part of Ruby) via the command:

    gem install ruic   # May need `sudo gem install ruic` depending on your setup

Although RUIC is a pure-Ruby library, it relies on [Nokogiri][2] for all the XML processing and manipulation. Installing RUIC will also automatically install Nokogiri, which may require some compilation.



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

_The `show` command prints the result; it is simply a nicer alias for `puts`._

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

show car.component?  #=> false           # Ask if an element is a component
assert car.component==sub.scene          # Ask for the owning component; may be the scene
```

## Finding Many Assets

```ruby
uia 'MyApp.uia'
main = app.main_presentation

every_asset   = main.find                                  # Array of matching assets
master_assets = main.find _master:true                     # Test for master/nonmaster
models        = main.find _type:'Model'                    # …or based on type
slide2_assets = main.find _slide:2                         # …or presence on slide
rectangles    = main.find sourcepath:'#Rectangle'          # …or attribute values
gamecovers    = main.find name:'Game Cover'                # …including the name

# Combine tests to get more specific
master_models = main.find _type:'Model', _master:true
slide2_rects  = main.find _type:'Model', _slide:2, sourcepath:'#Rectangle'
nonmaster_s2  = main.find _slide:2, _master:false
red_materials = main.find _type:'Material', diffuse:[1,0,0]

# You can match values more loosely
pistons       = main.find name:/^Piston/                   # Regex for batch finding
bottom_row    = main.find position:[nil,-200,nil]          # nil for wildcards in vectors

# Restrict the search to a sub-tree
group        = main/"Scene.Layer.Group"
group_models = group.find _type:'Model'                    # Orig asset is never included
group_models = main.find _under:group, _type:'Model'       # Or, use `_under` to limit

# Iterate the results as they are found
main.find _type:'Model', name:/^Piston/ do |model, index|  # Using the index is optional
	show "Model #{index} is named #{model.name}"
end
```

Notes:
* `nil` inside an array is a "wildcard" value, allowing you to test only specific values
* Numbers (both in vectors/colors/rotations and float/long values) must only be within `0.001` to match.
  * _For example, `attr:{diffuse:[1,0,0]}` will match a color with `diffuse=".9997 0.0003 0"`_
* Results of `find` are always in scene-graph order.


## Working with References

```ruby
uia 'MyApp.uia'
mat1 = app/"main:Scene.Layer.Sphere.Material" # A normal UIC Material
mat2 = app/"main:Scene.Layer.Cube.Material"   # A normal UIC Material
p mat2.type                                   #=> "Material"
ref = mat2.replace_with_referenced_material   # A very specific method :)
p ref.properties['referencedmaterial'].type   #=> "ObjectRef"
p ref['referencedmaterial',0].object          #=> nil
p ref['referencedmaterial',0].type            #=> :absolute
ref['referencedmaterial',0].object = mat1     #=> Sets an absolute reference
ref['referencedmaterial',0].type = :path      #=> Use a relative path instead

# Alternatively, you can omit the .object when setting the reference:
# ref['referencedmaterial',0] = mat1

mat3 = ref['referencedmaterial',1].object     #=> Get the asset pointed to
assert mat1 == mat3                           #=> They are the same! It worked!

app.save_all!                                 #=> Write presentations in place
```

## Writing Assertions


## Locating MetaData.xml
RUIC needs access to a UIC `MetaData.xml` file to understand the properties in the various XML files.
By default RUIC will look in the location specified by `RUIC::DEFAULTMETADATA`, e.g.
`C:/Program Files (x86)/NVIDIA Corporation/UI Composer 8.0/res/DataModelMetadata/en-us/MetaData.xml`

If this file is in another location, you can tell the script where to find it either:

* on the command line: `ruic -m path/to/MetaData.xml myscript.ruic`
* in your ruic script: `metadata 'path/to/MetaData.xml' # before any 'app' commands`


# Interactive RUIC
In addition to executing a standalone script, RUIC also has a REPL (like IRB) that allows you to
interactively execute and test changes to your application/presentations before saving.
There are two ways to enter interactive mode:

* If you invoke the `ruic` binary with a `.uia` file as the argument the interpreter will load
  the application and enter the REPL:
  ```
  $ ruic myapp.uia
  (RUIC v0.2.2 interactive session; 'quit' or ctrl-d to end)

  uia "test/projects/SimpleScene/SimpleScene.uia"
  #=> <UIC::Application 'SimpleScene.uia'>
  ```

* Alternatively, you can have RUIC execute a script and then enter the interactive REPL
  by supplying the `-i` command-line switch:
  ```
  $ ruic -i test/referencematerials.ruic
  (RUIC v0.2.2 interactive session; 'quit' or ctrl-d to end)

  app
  #=> <UIC::Application 'ReferencedMaterials.uia'>

  cubemat
  #=> <asset Material#Material_002>
  ```
  As shown above, all local variables created by the script continue to be available
  in the interactive session.


# Known Limitations (aka TODO)
_In decreasing priority…_

- Report on image assets, their sizes
- Report used assets (and where they are used)
- Report unused assets (in a format suitable for automated destruction)
- Report missing assets (and who was looking for them)
- Gobs more unit tests
- Parse .lua headers (in case one references an image)
- Parse render plugins
- Read/edit animation tracks
- Find all colors, and where they are used
- Visual actions for State Machines
- Create new presentation assets (e.g. add a new sphere)
- Modify the scene graph of presentations
- Create new presentations/applications from code
- Report on image asset file formats (e.g. find PNGs, find DXT1 vs DXT3 vs DXT Luminance…)


# History

## v0.3.0 - 2014-Nov-10
* Switch attribute filtering to use `attr:{ … }` instead of `attributes:{ … }`
* Attribute matching now requires that a requested attribute be present, or else the asset matching fails.
  * _For example, `main.find attr:{ diffusecolor:[nil,nil,nil] }` will now only find assets with a `diffusecolor` attribute._

## v0.2.5 - 2014-Nov-10
* Re-adds blank line after REPL result.

## v0.2.4 - 2014-Nov-10
* Fix bug with history editing in REPL (prompts no longer have a blank line before)
* Add temporary hack to make projects using Float2 load correctly

## v0.2.3 - 2014-Nov-7
* Cleaner mechanism for creating a truly blank binding

## v0.2.2 - 2014-Nov-7
* REPL shows version number when it starts

## v0.2.1 - 2014-Nov-7
* REPL mode after script maintains binding of script (all local variables remain available)
* Customized `.irbrc` files will not cause warnings

## v0.2.0 - 2014-Nov-7
* Add Presentation#save_as
* REPL working directory is same as .uia

## v0.1.0 - 2014-Nov-7
* Add REPL mode for ruic binary

## v0.0.1 - 2014-Nov-7
* Initial gem release
* Crawl presentations and modify attributes
* Batch find assets
* Save presentation changes back to disk



# License & Contact
RUIC is copyright ©2014 by Gavin Kistner and is licensed under the [MIT License][3]. See the `LICENSE` file for more details.

For bugs or feature requests please open [issues on GitHub][4]. For other communication you can [email the author directly](mailto:!@phrogz.net?subject=RUIC).

[1]: http://uicomposer.nvidia.com
[2]: http://nokogiri.org
[3]: http://opensource.org/licenses/MIT
[4]: https://github.com/Phrogz/RUIC/issues
