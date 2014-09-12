class UIC::Behavior
	include UIC::FileBacked
	attr_reader :lua
	def initialize( lua_path )
		self.file = lua_path
		load_from_file if file_found?
	end
	def load_from_file
		@lua = File.read(file,encoding:'utf-8')
	end
end

class UIC::Application::Behavior < UIC::Behavior
	include UIC::ElementBacked
	xmlattribute :id
	xmlattribute :src
	def initialize(application,el)
		self.owner = application
		self.el    = el
		super( application.path_to(src) )
	end
end