class NDD::RenderPlugin
	include NDD::FileBacked
	def initialize( file )
		self.file = file
	end
end

class NDD::Application::RenderPlugin < NDD::RenderPlugin
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