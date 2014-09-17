class UIC::StateMachine
	include UIC::FileBacked
	def initialize( xml )
		@doc = Nokogiri.XML( xml )
	end

	def errors?
		!errors.empty?
	end

	def errors
		file_found? ? [] : ["File not found: '#{file}'"]
	end
end

def UIC.StateMachine( scxml_path )
	UIC::StateMachine.new(File.read(scxml_path,encoding:'utf-8'))
		.tap{ |o| o.file = scxml_path }
end

class UIC::Application::StateMachine < UIC::StateMachine
	include UIC::ElementBacked
	xmlattribute :id
	xmlattribute :src
	xmlattribute :datamodel
	def initialize(application,el)
		self.owner = application
		self.el    = el
		self.file  = application.path_to(src)
		super( File.read( file, encoding:'utf-8' ) )
	end
end