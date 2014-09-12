require 'set'

class UIC::MetaData
	class AssetClass
		@properties = {}
		def self.properties
			(ancestors[1].respond_to?(:properties) ? ancestors[1].properties : {}).merge(@properties)
		end
		attr_accessor :presentation, :el
		def initialize( presentation, element )
			@presentation = presentation
			@el = element
		end

		def type
			self.class.name.split('::').last
		end

		# Find the owning component
		def component
			presentation.owning_component(@el)
		end

		def component?
			@el.name == 'Component'
		end

		def slides
			presentation.slides_for(@el)
		end

		# Get the values of attributes on a specific slide
		def [](slide_name_or_index)
			if slide = slides[slide_name_or_index]
				UIC::SlideValues.new(slide,self)
			end
		end

		def to_xml
			@el.to_xml
		end
		alias_method :inspect, :to_xml

		def ==(other)
			(self.class==other.class) && (el==other.el)
		end
		alias_method :eql?, :==
	end

	attr_reader :by_name

	HIER = {}
	%w[Asset Slide Scene].each{ |s| HIER[s] = 'AssetClass' }
	%w[Node Behavior Effect Image Layer Material ReferencedMaterial RenderPlugin].each{ |s| HIER[s]='Asset' }
	%w[Camera Component Group Light Model Text].each{ |s| HIER[s]='Node' }

	SAMEONALLSLIDES = ::Set[*%w[ name ]]

	def initialize(xml)
		@by_name = {'AssetClass'=>AssetClass}

		doc = Nokogiri.XML(xml)
		hack_in_slide_names!(doc)

		HIER.each do |class_name,parent_class_name|
			parent_class = @by_name[parent_class_name]
			el = doc.root.at(class_name)
			@by_name[class_name] = create_class(el,parent_class)
		end

		@by_name['State'] = @by_name['Slide']
		@by_name['Slide'].instance_eval do
			define_method(:inspect) do
				"<Slide '#{name}' of #{@el['component'] || @el.parent['component']}>"
			end
		end
	end

	# Creates a class from MetaData.xml with accessors for the <Property> listed
	# Instances of the class are associated with a presentation and know how to 
	# get/set values in that XML based on value types, slides, defaults
	def create_class(el,parent_class)
		Class.new(parent_class) do
			@properties = Hash[ el.css("Property").map do |e|
				type = e['type'] || (e['list'] ? 'String' : 'Float')
				type = "Float" if type=="float"
				property = UIC::Property.const_get(type).new(e)
				define_method(property.name) do
					if SAMEONALLSLIDES.include?(property.name)
						property.get(self,0)
					else
						UIC::ValuesPerSlide.new(@presentation,self,property)
					end
				end
				define_method("#{property.name}=") do |new_value|
					property.set(self,new_value,nil)
				end
				[property.name,property]
			end ]
		end.tap{ |klass| UIC::MetaData.const_set(el.name,klass) }
	end

	def new_instance(presentation,el)
		@by_name[el.name].new(presentation,el)
	end

	def hack_in_slide_names!(doc)
		doc.at('Slide') << '<Property name="name" formalName="Name" type="String" default="Slide" hidden="True" />'
	end
end

def UIC.Meta(metadata_path)
	UIC::MetaData.new(File.read(metadata_path,encoding:'utf-8'))
end

class UIC::Property
	class << self; attr_accessor :default; end
	def initialize(el); @el = el; end
	def name; @name||=@el['name']; end
	def formal; @formal||=@el['formalName'] || @el['name']; end
	def description; @desc||=@el['description']; end
	def default; @def ||= (@el['default'] || self.class.default); end
	def get(asset,slide)
		asset.presentation.get_asset_attribute(asset,name,slide) || default
	end
	def set(asset,new_value,slide_name_or_index)
		asset.presentation.set_asset_attribute(asset,name,slide_name_or_index,new_value)
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
		def get(asset,slide); VectorValue.new(asset,self,slide,super); end
		def set(asset,new_value,slide_name_or_index)
			new_value = new_value.join(' ') if new_value.is_a?(Array)
			super( asset, new_value, slide_name_or_index )
		end
	end
	Rotation = Vector
	Color    = Vector

	ObjectRef  = String #TODO: a real class
	Import     = String #TODO: a real class
	Mesh       = String #TODO: a real class
	Renderable = String #TODO: a real class
	Image      = String #TODO: a real class
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
			"<#{self}>"
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
		@slides = slides
		@length = slides.length-1
		@slide_by_name = Hash[ slides.map{ |s| [s.name,s] } ]
	end
	def each
		0.upto(@length){ |i| yield(@slides[i] ) }
	end
	def [](index_or_name)
		index_or_name.is_a?(Fixnum) ? @slides[index_or_name] : @slide_by_name[index_or_name.to_s]
	end
	def inspect
		"[ #{@slides.map(&:inspect).join ', '} ]"
	end
end

class UIC::SlideValues
	def initialize(slide,asset)
		raise unless slide.is_a?(UIC::MetaData::Slide)
		raise unless asset.is_a?(UIC::MetaData::AssetClass)

		@slide = slide
		@asset = asset
		@el    = asset.el
		@preso = asset.presentation
	end
	def method_missing(property_name,new_value=nil)
		property_name = property_name.to_s
		property_name.sub!(/=$/,'') if setflag=property_name[/=$/]
		if @asset.respond_to?(property_name)
			property = @asset.class.properties[property_name]
			if setflag
				property.set( @asset, new_value, @slide.name )
			else
				property.get( @asset, @slide.name )
			end
		else
			super
		end
	end
end

class UIC::ValuesPerSlide
	def initialize(presentation,asset,property)
		raise unless presentation.is_a?(UIC::Presentation)
		raise unless asset.is_a?(UIC::MetaData::AssetClass)
		raise unless property.is_a?(UIC::Property)
		@preso    = presentation
		@asset    = asset
		@el       = asset.el
		@property = property
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
		"<multiple values for '#{property.name}' per slide>"
	end
	alias_method :to_s, :inspect
end