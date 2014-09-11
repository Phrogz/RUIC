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

	HIER = { 'Asset'=>'AssetClass', 'Slide'=>'AssetClass' }
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
						presentation.get_asset_attribute(@el,property,0)
					else
						presentation.get_asset_attribute(@el,property)
					end
				end
				define_method("#{property.name}=") do |new_value|
					p "SET #{property.name} to #{new_value}"
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

	class String < self
		self.default = ''
		def get(str);       str || default; end
		def set(asset,value); asset[name] = value; end
	end
	MultiLineString = String

	class Float < self
		self.default = 0.0
		def get(str); (str || default).to_f; end
		def set(asset,value); asset[name] = value.to_f; end
	end
	class Long < self
		self.default = 0
		def get(str); (str || default).to_i; end
		def set(asset,value); asset[name] = value.to_i; end
	end
	class Boolean < self
		self.default = false
		def get(str); (str ? asset[name]=='True' : default); end
		def set(asset,value); asset[name] = value ? 'True' : 'False'; end
	end
	class Vector < self
		self.default = '0 0 0'
		def get(str); VectorValue.new(asset,self,str || default); end
		def set(asset,value)
			asset[name] = value ? 'True' : 'False'
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
		def initialize(asset,property,str)
			@asset=asset
			@name=property.name
			@x, @y, @z = str.split(/\s+/).map(&:to_f)
		end
		def x=(n); @asset[@name] = @asset[@name].split(/\s+/).tap{ |a| a[0]=n }.join(' '); end
		def y=(n); @asset[@name] = @asset[@name].split(/\s+/).tap{ |a| a[1]=n }.join(' '); end
		def z=(n); @asset[@name] = @asset[@name].split(/\s+/).tap{ |a| a[2]=n }.join(' '); end
		alias_method :r, :x
		alias_method :g, :y
		alias_method :b, :z
		alias_method :r=, :x=
		alias_method :g=, :y=
		alias_method :b=, :z=
		def inspect
			"<#{[x,y,z].join ' '}>"
		end
	end
end

class UIC::SlideCollection
	attr_reader :length
	def initialize(slides)
		@slides = slides
		@length = slides.length-1
		@slide_by_name = Hash[ slides.map{ |s| [s.name,s] } ]
	end
	def each(include_master=false)
		(include_master ? 0 : 1).upto(@length){ |i| yield(@slides[i] ) }
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
		@slide = slide
		@asset = asset
	end
	def method_missing(property_name,new_value=nil)
		if @asset.respond_to?(property_name)
			if property_name[/=$/]
			else
				@asset.presentation.get_asset_attribute( @asset.el, @asset.class.properties[property_name.to_s], @slide.name )
			end
		else
			super
		end
	end
end

class UIC::ValuesPerSlide
	def initialize(presentation,graph_element,property)
		@preso    = presentation
		@el       = graph_element
		@property = property
	end
	def [](slide_name_or_index)
		@preso.get_asset_attribute( @el, @property, slide_name_or_index )
	end
	def linked?
		@preso.attribute_linked?(@el,@property.name)
	end
	def values(with_master=false)
		@preso.slide_values(@el,@property,with_master)
	end
	def inspect
		"<multiple values for '#{property.name}' per slide>"
	end
	alias_method :to_s, :inspect
end