#encoding: utf-8
require 'set'
$depth = 0
class UIC::Asset
	class Root
		@properties = {}
		class << self
			attr_reader :name
			def properties
				(ancestors[1].respond_to?(:properties) ? ancestors[1].properties : {}).merge(@properties)
			end

			def each
				(@by_name.values - [self]).each{ |klass| yield klass }
			end
			include Enumerable

			def inspect
				"<#{@name}>"
			end
		end

		def properties
			self.class.properties
		end

		attr_accessor :presentation, :el
		def initialize( presentation, element )
			@presentation = presentation
			@el = element
		end

		def type
			self.class.name
			# self.class.name.split('::').last
		end

		def parent
			presentation.parent_asset(@el)
		end

		def children
			presentation.child_assets(@el)
		end

		# Find the owning component (even if you are a component)
		def component
			presentation.owning_component(@el)
		end

		def component?
			@el.name == 'Component'
		end

		def master?
			presentation.master?(@el)
		end

		def slide?
			false
		end

		def has_slide?(slide_name_or_index)
			presentation.has_slide?(@el,slide_name_or_index)
		end

		def slides
			presentation.slides_for(@el)
		end

		def on_slide(slide_name_or_index)
			if has_slide?(slide_name_or_index)
				UIC::SlideValues.new( self, slide_name_or_index )
			end
		end

		def path
			@path ||= @presentation.path_to(@el)
		end

		def name
			properties['name'].get( self, presentation.slide_index(@el) )
		end

		def name=( new_name )
			properties['name'].set( self, new_name, presentation.slide_index(@el) )
		end

		# Get the value(s) of an attribute
		def [](attribute_name, slide_name_or_index=nil)
			# puts "Looking for #{attribute_name.inspect} on slide #{slide_name_or_index.inspect} of #{@el.name}##{@el['id']}"
			if property = properties[attribute_name]
				if slide_name_or_index
					property.get( self, slide_name_or_index ) if has_slide?(slide_name_or_index)
				else
					UIC::ValuesPerSlide.new(@presentation,self,property)
				end
			end
		end

		# Set the value of an attribute, either across all slides, or on a particular slide
		# el['foo']   = 42
		# el['foo',0] = 42
		def []=( attribute_name, slide_name_or_index=nil, new_value )
			if property = properties[attribute_name] then
				property.set(self,new_value,slide_name_or_index)
			end
		end

		def to_xml
			@el.to_xml
		end
		def inspect
			"<asset #{@el.name}##{@el['id']}>"
		end

		def to_s
			"<#{type} #{path}>"
		end

		def ==(other)
			(self.class==other.class) && (el==other.el)
		end
		alias_method :eql?, :==
	end

	attr_reader :by_name

	HIER = {}
	%w[Asset Slide Scene].each{ |s| HIER[s] = 'Root' }
	%w[Node Behavior Effect Image Layer Material MaterialBase ReferencedMaterial RenderPlugin].each{ |s| HIER[s]='Asset' }
	%w[Camera Component Group Light Model Text].each{ |s| HIER[s]='Node' }

	def initialize(xml)
		@by_name = {'Root'=>Root}

		doc = Nokogiri.XML(xml)
		hack_in_slide_names!(doc)

		HIER.each do |class_name,parent_class_name|
			parent_class = @by_name[parent_class_name]
			el = doc.root.at(class_name)
			@by_name[class_name] = create_class(el,parent_class,el.name)
			UIC::Asset.const_set( el.name, @by_name[class_name] ) # give the class instance a name by pointing a constant to it :/
		end

		@by_name['State'] = @by_name['Slide']
		@by_name['Slide'].instance_eval do
			attr_accessor :index, :name
			define_method :inspect do
				"<slide ##{index} of #{@el['component'] || @el.parent['component']}>"
			end
			define_method(:slide?){ true }
		end
	end

	# Creates a class from MetaData.xml with accessors for the <Property> listed.
	# Instances of the class are associated with a presentation and know how to 
	# get/set values in that XML based on value types, slides, defaults.
	# Also used to create classes from effects, materials, and behavior preambles.
	def create_class(el,parent_class,name='CustomAsset')
		Class.new(parent_class) do
			@name = name
			@properties = Hash[ el.css("Property").map do |e|
				type = e['type'] || (e['list'] ? 'String' : 'Float')
				type = "Float" if type=="float"
				property = UIC::Property.const_get(type).new(e)
				[ property.name, UIC::Property.const_get(type).new(e) ]
			end ]
		end
	end

	def new_instance(presentation,el)
		@by_name[el.name].new(presentation,el)
	end

	def hack_in_slide_names!(doc)
		doc.at('Slide') << '<Property name="name" formalName="Name" type="String" default="Slide" hidden="True" />'
	end
end

def UIC.Meta(metadata_path)
	UIC::Asset.new(File.read(metadata_path,encoding:'utf-8'))
end

class UIC::Property
	class << self; attr_accessor :default; end
	def initialize(el); @el = el; end
	def name; @name||=@el['name']; end
	def type; @type||=@el['type']; end
	def formal; @formal||=@el['formalName'] || @el['name']; end
	def description; @desc||=@el['description']; end
	def default; @def ||= (@el['default'] || self.class.default); end
	def get(asset,slide)
		if asset.slide? || asset.has_slide?(slide)
			asset.presentation.get_attribute(asset.el,name,slide) || default
		end
	end
	def set(asset,new_value,slide_name_or_index)
		asset.presentation.set_attribute(asset.el,name,slide_name_or_index,new_value)
	end
	def inspect
		"<#{type} '#{name}'>"
	end

	class String < self
		self.default = ''
	end
	MultiLineString = String

	class Float < self
		self.default = 0.0
		def get(asset,slide); super.to_f; end
	end
	class Long < self
		self.default = 0
		def get(asset,slide); super.to_i; end
	end
	class Boolean < self
		self.default = false
		def get(asset,slide); super=='True'; end
		def set(asset,new_value,slide_name_or_index)
			super( asset, new_value ? 'True' : 'False', slide_name_or_index )
		end
	end
	class Vector < self
		self.default = '0 0 0'
		def get(asset,slide)
			VectorValue.new(asset,self,slide,super)
		end
		def set(asset,new_value,slide_name_or_index)
			new_value = new_value.join(' ') if new_value.is_a?(Array)
			super( asset, new_value, slide_name_or_index )
		end
	end
	Rotation = Vector
	Color    = Vector
	class Image < self
		self.default = nil
		def get(asset,slide)
			if idref = super
				result = asset.presentation.asset_by_id( idref[1..-1] )
				slide ? result.on_slide( slide ) : result
			end
		end
		def set(asset,new_value,slide)
			raise "Setting image attributes not yet supported"
		end
	end
	class Texture < String
		def get(asset,slide)
			if path=super
				path.empty? ? nil : path
			end
		end
	end


	ObjectRef  = String #TODO: a real class
	Import     = String #TODO: a real class
	Mesh       = String #TODO: a real class
	Renderable = String #TODO: a real class
	Font       = String #TODO: a real class
	FontSize   = Long

	StringListOrInt = String #TODO: a real class

	class VectorValue
		attr_reader :x, :y, :z
		def initialize(asset,property,slide,str)
			@asset    = asset
			@property = property
			@slide    = slide
			@x, @y, @z = str.split(/\s+/).map(&:to_f)
		end
		def setall
			@property.set( @asset, to_s, @slide )
		end
		def x=(n); @x=n; setall end
		def y=(n); @y=n; setall end
		def z=(n); @z=n; setall end
		alias_method :r, :x
		alias_method :g, :y
		alias_method :b, :z
		alias_method :r=, :x=
		alias_method :g=, :y=
		alias_method :b=, :z=
		def inspect
			"<#{@asset.path}.#{@property.name}: #{self}>"
		end
		def to_s
			[x,y,z].join(' ')
		end
	end
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
end

class UIC::ValuesPerSlide
	def initialize(presentation,asset,property)
		raise unless presentation.is_a?(UIC::Presentation)
		raise unless asset.is_a?(UIC::Asset::Root)
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
		@preso.attribute_linked?(@el,@property.name)
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