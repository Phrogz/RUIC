module UIC::FileBacked
	attr_accessor :doc, :file
	def path_to( relative )
		File.expand_path( relative.gsub('\\','/'), File.dirname(file) )
	end
	def filename
		File.basename(file)
	end
	def file_found?
		!@file_not_found
	end
	def file=( new_path )
		@file = File.expand_path(new_path)
		@file_not_found = !File.exist?(new_path)
		# warn "Could not find file '#{new_path}'" unless file_found?
	end
end

module UIC::ElementBacked
	attr_accessor :owner, :el
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
		def xmlattribute(name,&block)
			define_method(name){ @el[name] }
			define_method("#{name}=", &(block || ->(new_value){ @el[name]=new_value.to_s }))
		end
  end	
end

module UIC::PresentableHash
	def to_s
		flat_map{ |k,v| [ k, *(v.is_a?(Array) ? v.map{|v2| "\t#{v2.to_s}" } : v) ] }
	end
end
