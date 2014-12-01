class UIC::Behavior
	include UIC::FileBacked
	def initialize( lua_path )
		self.file = lua_path
	end
	alias_method :lua, :file_content
end

class UIC::Application::Behavior < UIC::Behavior
	include UIC::ElementBacked
	# @!parse extend UIC::ElementBacked::ClassMethods
	xmlattribute :id
	xmlattribute :src
	def initialize(application,el)
		self.owner = application
		self.el    = el
		super( application.absolute_path(src) )
	end
end