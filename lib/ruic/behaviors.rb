class NDD::Behavior
	include NDD::FileBacked
	def initialize( lua_path )
		self.file = lua_path
	end
	alias_method :lua, :file_content
end

class NDD::Application::Behavior < NDD::Behavior
	include NDD::ElementBacked
	# @!parse extend NDD::ElementBacked::ClassMethods
	xmlattribute :id
	xmlattribute :src
	def initialize(application,el)
		self.owner = application
		self.el    = el
		super( application.absolute_path(src) )
	end
end