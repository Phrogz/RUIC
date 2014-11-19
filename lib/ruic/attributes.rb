#encoding: utf-8
class UIC::Property
	class << self; attr_accessor :default; end
	def initialize(el); @el = el; end
	def name; @name||=@el['name']; end
	def type; @type||=@el['type']; end
	def formal; @formal||=@el['formalName'] || @el['name']; end
	def min; @el['min']; end
	def max; @el['max']; end
	def description; @desc||=@el['description']; end
	def default; @def ||= (@el['default'] || self.class.default); end
	def get(asset,slide)
		if asset.slide? || asset.has_slide?(slide)
			asset.presentation.get_attribute(asset,name,slide) || default
		end
	end
	def set(asset,new_value,slide_name_or_index)
		asset.presentation.set_attribute(asset,name,slide_name_or_index,new_value)
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
	Float2   = Vector
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
				path.empty? ? nil : path.gsub( '\\', '/' ).sub( /^.\// ,'' )
			end
		end
	end

	class ObjectRef < self
		self.default = nil
		def get(asset,slide)
			ref  = super
			type = :absolute
			obj  = nil
			unless ref=='' || ref.nil?
				type = ref[0]=='#' ? :absolute : :path
				ref = type==:absolute ? asset.presentation.asset_by_id( ref[1..-1] ) : asset.presentation.at( ref, asset )
			end
			ObjectReference.new(asset,self,slide,ref,type)
		end
		def set(asset,new_object,slide)
			get(asset,slide).object = new_object
		end
	end

	class ObjectReference
		attr_reader :object, :type
		def initialize(asset,property,slide,object=nil,type=nil)
			@asset    = asset
			@name     = property.name
			@slide    = slide
			@object   = object
			@type     = type
		end
		def object=(new_object)
			raise "ObjectRef must be set to an asset (not a #{new_object.class.name})" unless new_object.is_a?(UIC::MetaData::Root)
			@object = new_object
			write_value!
		end
		def type=(new_type)
			raise "ObjectRef types must be either :absolute or :path (not #{new_type.inspect})" unless [:absolute,:path].include?(new_type)
			@type = new_type
			write_value!
		end
		private
		def write_value!
			path = case @object
				when NilClass then ""
				else case @type
					when :absolute then "##{@object.el['id']}"
					when :path     then @asset.presentation.path_to( @object, @asset ).sub(/^[^:.]+:/,'')
					# when :root     then @asset.presentation.path_to( @object ).sub(/^[^:.]+:/,'')
				end
			end
			@asset.presentation.set_attribute( @asset, @name, @slide, path )
		end
	end

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
			to_a.join(' ')
		end
		def to_a
			[x,y,z]
		end
	end
end
