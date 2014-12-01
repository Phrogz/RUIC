class UIC::RenderPlugin
	include UIC::FileBacked
	def initialize( file )
		self.file = file
	end
end

class UIC::Application::RenderPlugin < UIC::RenderPlugin
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