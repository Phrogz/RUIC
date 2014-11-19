#encoding: utf-8
class UIC::MetaData

	# The base class for all assets. All other classes are dynamically created when a `MetaData.xml` file is loaded.
	class AssetBase
		@properties = {}
		@name = "AssetBase"

		class << self
			# @return [String] The scene graph name of the asset.
			attr_reader :name

			# @return [Hash] a hash mapping attribute names to {Property} instances.
			def properties
				(ancestors[1].respond_to?(:properties) ? ancestors[1].properties : {}).merge(@properties)
			end

			# @private
			def inspect
				"<#{@name}>"
			end
		end

		# @return [Hash] a hash mapping attribute names to {Property} instances.
		def properties
			self.class.properties
		end

		# Find an asset by relative scripting path.
		#
		# @example
		#  preso = app.main
		#  layer = preso/"Scene.Layer"
		#  cam1  = app/"main:Scene.Layer.Camera"
		#  cam2  = preso/"Scene.Layer.Camera"
		#  cam3  = layer/"Camera"
		#  cam4  = cam1/"parent.Camera"
		#
		#  assert cam1==cam2 && cam2==cam3 && cam3==cam4
		#
		# @return [MetaData::AssetBase] The found asset, or `nil` if it cannot be found.
		#
		# @see Application#at
		# @see Presentation#at
		def at(sub_path)
			presentation.at(sub_path,@el)
		end
		alias_method :/, :at

		# @return [Presentation] the presentation that this asset is part of.
		attr_accessor :presentation

		# @return [Nokogiri::XML::Element] the internal XML element in the scene graph of the presentation.
		attr_accessor :el

		# Create a new asset. This is called for you automatically; you likely should not be using it.
		# @param presentation [Presentation] the presentation owning this asset.
		# @param element [Nokogiri::XML::Element] the internal XML element in the scene graph of the presentation.
		def initialize( presentation, element )
			@presentation = presentation
			@el = element
		end

		# @return [String] the type of this asset. For example: `"Model"`, `"Material"`, `"ReferencedMaterial"`, `"PathAnchorPoint"`, etc.
		def type
			self.class.name
		end

		# @return [AssetBase] the parent of this asset in the scene graph.
		# @see Presentation#parent_asset
		def parent
			presentation.parent_asset(self)
		end

		# @return [Array<AssetBase>] array of child assets in the scene graph. Children are in scene graph order.
		# @see Presentation#child_assets
		def children
			presentation.child_assets(self)
		end

		# Find descendant assets matching criteria.
		# This method is the same as (but more convenient than) {Presentation#find} using the `:_under` criteria.
		# See that method for documentation of the `criteria`.
		#
		# @example
		#  preso = app.main
		#  group = preso/"Scene.Layer.Vehicle"
		#  tires = group.find name:/^Tire/
		#
		#  # alternative
		#  tires = preso.find name:/^Tire/, _under:group
		#
		# @return [Array<AssetBase>]
		#
		# @see Presentation#find
		def find(criteria={},&block)
			criteria[:_under] ||= self
			presentation.find(criteria,&block)
		end

		# @return [AssetBase] the component or scene that owns this asset.
		#         If this asset is a component, does not return itself.
		# @see Presentation#owning_component
		def component
			presentation.owning_component(self)
		end

		# @return [Boolean] `true` if this asset is a component or Scene.
		def component?
			@el.name=='Component' || @el.name=='Scene'
		end

		# @return [Boolean] `true` if this asset is on the master slide.
		# @see Presentation#master?
		def master?
			presentation.master?(self)
		end

		# @return [Boolean] `true` if this asset is a Slide.
		def slide?
			false
		end

		# @param slide_name_or_index [Integer,String] the slide number of name to check for presence on.
		# @return [Boolean] `true` if this asset is present on the specified slide.
		# @see Presentation#has_slide?
		def has_slide?(slide_name_or_index)
			presentation.has_slide?(self,slide_name_or_index)
		end

		# @return [SlideCollection] an array-like collection of all slides that the asset is available on.
		# @see Presentation#slides_for
		def slides
			presentation.slides_for(self)
		end

		# @example
		#  logo = app/"main:Scene.UI.Logo"
		#  assert logo.master?             # It's a master object
		#
		#  show logo['endtime'].values     #=> [10000,500,1000,750]
		#  show logo['opacity'].values     #=> [100,0,0,100]
		#  logo1 = logo.on_slide(1)
		#  logo2 = logo.on_slide(2)
		#  show logo1['endtime']           #=> 500
		#  show logo2['endtime']           #=> 1000
		#  show logo1['opacity']           #=> 0
		#  show logo2['opacity']           #=> 0
		#
		#  logo2['opacity'] = 66
		#  show logo['opacity'].values     #=> [100,0,66,100]
		#
		# @param slide_name_or_index [Integer,String] the slide number or name to create the proxy for.
		# @return [SlideValues] a proxy that yields attribute values for a specific slide.
		def on_slide(slide_name_or_index)
			if has_slide?(slide_name_or_index)
				UIC::SlideValues.new( self, slide_name_or_index )
			end
		end

		# @return [String] the script path to this asset.
		# @see #path_to
		# @see Presentation#path_to
		def path
			@path ||= @presentation.path_to(self)
		end

		# @param other_asset [AssetBase] the asset to find the relative path to.
		# @return [String] the script path to another asset, relative to this one.
		# @see #path
		# @see Presentation#path_to
		def path_to(other_asset)
			@presentation.path_to(other_asset,self)
		end

		# @return [String] the name of this asset in the scene graph.
		def name
			properties['name'].get( self, presentation.slide_index(self) )
		end

		# Change the name of the asset in the scene graph.
		# @param new_name [String] the new name for this asset.
		# @return [String] the new name.
		def name=( new_name )
			@path = nil # invalidate the memoization
			properties['name'].set( self, new_name, presentation.slide_index(self) )
		end

		# Get the value(s) of an attribute.
		# If `slide_name_or_index` is omitted, creates a ValuesPerSlide proxy for the specified attribute.
		# @example
		#  logo = app/"main:Scene.UI.Logo"
		#  show logo.master?               #=> true  (it's a master object)
		#  show logo['endtime'].linked?    #=> false (the endtime property is unlinked)
		#  show logo['endtime'].values     #=> [10000,500,1000,750]
		#  show logo['endtime',0]          #=> 10000 (the master slide value)
		#  show logo['endtime',"Slide 1"]  #=> 500
		#  show logo['endtime',2]          #=> 1000
		#
		# @param attribute_name [String,Symbol] the name of the attribute.
		# @param slide_name_or_index [Integer,String] the slide number or name to find the value on.
		# @return [Object] the value of the property on the given slide.
		# @return [ValuesPerSlide] if no slide is specified.
		# @see #on_slide
		# @see Presentation#get_attribute
		def [](attribute_name, slide_name_or_index=nil)
			if property = properties[attribute_name.to_s]
				if slide_name_or_index
					property.get( self, slide_name_or_index ) if has_slide?(slide_name_or_index)
				else
					UIC::ValuesPerSlide.new(@presentation,self,property)
				end
			end
		end

		# Set the value of an attribute, either across all slides, or on a particular slide.
		#
		# @example
		#  logo = app/"main:Scene.UI.Logo"
		#  show logo.master?               #=> true  (it's a master object)
		#  show logo['endtime'].linked?    #=> false (the endtime property is unlinked)
		#  show logo['endtime'].values     #=> [10000,500,1000,750]
		#
		#  logo['endtime',1] = 99
		#  show logo['endtime'].values     #=> [10000,99,1000,750]
		#
		#  logo['endtime'] = 42
		#  show logo['endtime'].values     #=> [42,42,42,42]
		#  show logo['endtime'].linked?    #=> false (the endtime property is still unlinked)
		#
		# @param attribute_name [String,Symbol] the name of the attribute.
		# @param slide_name_or_index [Integer,String] the slide number or name to set the value on.
		# @param new_value [Numeric,String] the new value for the attribute.
		# @see Presentation#set_attribute
		def []=( attribute_name, slide_name_or_index=nil, new_value )
			if property = properties[attribute_name.to_s] then
				property.set(self,new_value,slide_name_or_index)
			end
		end

		# @return [String] the XML representation of the scene graph element.
		def to_xml
			@el.to_xml
		end

		# @private no need to document this
		def inspect
			"<asset #{@el.name}##{@el['id']}>"
		end

		# @private no need to document this
		def to_s
			"<#{type} #{path}>"
		end

		# @private no need to document this
		def ==(other)
			(self.class==other.class) && (el==other.el)
		end
		alias_method :eql?, :==
	end

	attr_reader :by_name

	HIER = {}

	%w[Asset Slide Scene].each{ |s| HIER[s] = 'AssetBase' }
	%w[Node Behavior Effect Image Layer MaterialBase PathAnchorPoint RenderPlugin].each{ |s| HIER[s]='Asset' }
	%w[Alias Camera Component Group Light Model Text Path].each{ |s| HIER[s]='Node' }
	%w[Material ReferencedMaterial].each{ |s| HIER[s]='MaterialBase' }

	def initialize(xml)

		@by_name = {'AssetBase'=>AssetBase}

		doc = Nokogiri.XML(xml)
		hack_in_slide_names!(doc)

		HIER.each do |class_name,parent_class_name|
			parent_class = @by_name[parent_class_name]
			el = doc.root.at(class_name)
			@by_name[class_name] = create_class(el,parent_class,el.name)
		end

		# Extend well-known classes with script interfaces after they are created
		@by_name['State'] = @by_name['Slide']
		@by_name['Slide'].instance_eval do
			attr_accessor :index, :name
			define_method :inspect do
				"<slide ##{index} of #{@el['component'] || @el.parent['component']}>"
			end
			define_method(:slide?){ true }
		end

		refmat = @by_name['ReferencedMaterial']
		@by_name['MaterialBase'].instance_eval do
			define_method :replace_with_referenced_material do
				type=='ReferencedMaterial' ? self : presentation.replace_asset( self, 'ReferencedMaterial', name:name )
			end
		end

		@by_name['Path'].instance_eval do
			define_method(:anchors){ find _type:'PathAnchorPoint' }
		end

	end

	# Creates a class from MetaData.xml with accessors for the <Property> listed.
	# Instances of the class are associated with a presentation and know how to
	# get/set values in that XML based on value types, slides, defaults.
	# Also used to create classes from effects, materials, and behavior preambles.
	def create_class(el,parent_class,name='CustomAsset')
		Class.new(parent_class) do
			@name = name.to_s
			@properties = Hash[ el.css("Property").map do |e|
				type = e['type'] || (e['list'] ? 'String' : 'Float')
				type = "Float" if type=="float"
				property = UIC::Property.const_get(type).new(e)
				[ property.name, UIC::Property.const_get(type).new(e) ]
			end ]
			def self.inspect
				@name
			end
		end
	end

	def new_instance(presentation,el)
		klass = @by_name[el.name] || create_class(el,@by_name['Asset'],el.name)
		klass.new(presentation,el)
	end

	def hack_in_slide_names!(doc)
		doc.at('Slide') << '<Property name="name" formalName="Name" type="String" default="Slide" hidden="True" />'
	end
end

def UIC.MetaData(metadata_path)
	UIC::MetaData.new(File.read(metadata_path,encoding:'utf-8'))
end

class UIC::SlideCollection
	include Enumerable
	attr_reader :length
	def initialize(slides)
		@length = slides.length-1
		@slides = slides
		@lookup = {}
		slides.each do |s|
			@lookup[s.index] = s
			@lookup[s.name]  = s
		end
	end
	def each
		@slides.each{ |s| yield(s) }
	end
	def [](index_or_name)
		@lookup[ index_or_name ]
	end
	def inspect
		"[ #{@slides.map(&:inspect).join ', '} ]"
	end
	def to_ary
		@slides
	end
end

class UIC::ValuesPerSlide
	def initialize(presentation,asset,property)
		raise unless presentation.is_a?(UIC::Presentation)

		raise unless asset.is_a?(UIC::MetaData::AssetBase)
		raise unless property.is_a?(UIC::Property)
		@preso    = presentation
		@asset    = asset
		@el       = asset.el
		@property = property
	end
	def value
		values.first
	end
	def [](slide_name_or_index)
		@property.get( @asset, slide_name_or_index )
	end
	def []=(slide_name_or_index,new_value)
		@property.set( @asset, new_value, slide_name_or_index )
	end
	def linked?
		@preso.attribute_linked?( @asset, @property.name )
	end
	def unlink
		@preso.unlink_attribute( @asset, @property.name )
	end
	def link
		@preso.link_attribute( @asset, @property.name )
	end
	def values
		@asset.slides.map{ |s| self[s.name] }
	end
	def inspect
		"<Values of '#{@asset.name}.#{@property.name}' across slides>"
	end
	alias_method :to_s, :inspect
end

class UIC::SlideValues
	def initialize( asset, slide )
		@asset = asset
		@slide = slide
	end
	def [](attribute_name)
		@asset[attribute_name,@slide]
	end
	def []=( attribute_name, new_value )
		@asset[attribute_name,@slide] = new_value
	end
	def method_missing( name, *args, &blk )
		asset.send(name,*args,&blk)
	end
	def inspect
		"<#{@asset.inspect} on slide #{@slide.inspect}>"
	end
end