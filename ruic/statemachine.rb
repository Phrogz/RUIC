class UIC::Application::StateMachineAsset < UIC::Application::Asset
	xmlattribute :datamodel
	def visual_actions
		@app.doc
	end
	def machine
		UIC::StateMachine( @app.path_to(src) ).tap{ |o| o.asset=self }
	end
end

class UIC::StateMachine
	include UIC::FileBacked
	include UIC::ApplicationAsset
	def initialize( xml )
		@doc = Nokogiri.XML( xml )
	end
end

def UIC.StateMachine( scxml_path )
	UIC::StateMachine.new(File.read(scxml_path,encoding:'utf-8'))
		.tap{ |o| o.file = scxml_path }
end