module UIC::FileBacked
	attr_accessor :doc, :file
	def path_to( relative )
		File.expand_path( File.join(File.dirname(file),relative) )
	end
	def filename
		File.basename(file)
	end
	def file_found?
		!@file_not_found
	end
	def file=( new_path )
		@file = new_path
		@file_not_found = !File.exist?(new_path)
		warn "Could not find file '#{new_path}'" unless file_found?
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
