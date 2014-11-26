# Supports classes that represent an XML file on disk (e.g. `.uia` and `.uip`).
module UIC::FileBacked
	# @return [Nokogiri::XML::Document] the Nokogiri document representing the instance.
	attr_accessor :doc

	# @return [String] the absolute path to the underlying file.
	attr_accessor :file

	# @param relative [String] a file path relative to this file.
	# @return [String] the full path resolved relative to this file.
	def resolve_file_path( relative )
		File.expand_path( relative.gsub('\\','/'), File.dirname(file) )
	end

	# @return [String] the name of the file (without any directories).
	def filename
		File.basename(file)
	end

	# @return [Boolean] `true` if the underlying file exists on disk.
	def file_found?
		@file && File.exist?(@file)
	end

	# Set the file for the class. Does **not** attempt to load the XML document.
	# @param new_path [String] the file path for this class.
	# @return [String]
	def file=( new_path )
		@file = File.expand_path(new_path)
	end

	# @return [String] the XML representation of the document.
	def to_xml
		doc.to_xml( indent:1, indent_text:"\t" )
	end

	# Overwrite the associated file on disk with the {#to_xml} representation of this class.
	# @return [true]
	def save!
		File.open(file,'w:utf-8'){ |f| f << to_xml }
		true
	end

	# Save to the supplied file path. Subsequent calls to {#save!} will save to the new file, not the original file name.
	def save_as(new_file)
		File.open(new_file,'w:utf-8'){ |f| f << to_xml }
		self.file = new_file
	end
end

# Supports classes that represent an XML element (e.g. `<presentation id="main" src="foo.uip"/>`).
module UIC::ElementBacked

	# @return [Object] the object in charge of this instance.
	attr_accessor :owner

	# @return [Nokogiri::XML::Element] the element backing this instance.
	attr_accessor :el

	# @private
	def self.included(base)
		base.extend(ClassMethods)
	end

	module ClassMethods
		# Add methods to instances of the class which gets/sets from an XML attribute.
		# @param name [String] the name of an XML attribute to expose.
		# @param getblock [Proc] a proc to run
		def xmlattribute(name,getblock=nil,&setblock)
			define_method(name){ getblock ? getblock[@el[name]] : @el[name] }
			define_method("#{name}="){ |new_value| @el[name] = (setblock ? setblock[new_value] : new_value).to_s }
		end
	end
end

module UIC::PresentableHash
	def to_s
		flat_map{ |k,v| [ k, *(v.is_a?(Array) ? v.map{|v2| "\t#{v2.to_s}" } : v) ] }
	end
end

# Create an array of rows representing a tree of elements.
# @param root [Object] the root of the tree.
# @param children [Block] a block that returns an array of child objects when passed an item in the tree.
# @return [Array<Array>] array of lines pairing the indent string for the line with the element, or `nil` if the indent line is a separator.
def UIC.tree_hierarchy( root, &children )
	queue = [[root,"",true]]
	[].tap do |results|
		until queue.empty?
			item,indent,last = queue.pop
			kids = children[item]
			extra = indent.empty? ? '' : last ? '└╴' : '├╴'
			results << [ indent+extra, item ]
			# results << [ indent, nil ] if last and kids.empty?
			indent += last ? '  ' : '│ '
			parts = kids.map{ |k| [k,indent,false] }.reverse
			parts.first[2] = true unless parts.empty?
			queue.concat parts
		end
	end
end
