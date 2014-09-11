class UIC::Application; end

class UIC::Application::Asset
	def self.xmlattribute(name,&block)
		define_method(name){ @el[name] }
		define_method("#{name}=", &(block || ->(new_value){ @el[name]=new_value.to_s }))
	end
	def self.from_element(el,app)
		klass = case el.name
			when 'behavior'     then UIC::Application::BehaviorAsset
			when 'statemachine' then UIC::Application::StateMachineAsset
			when 'presentation' then UIC::Application::PresentationAsset
			when 'renderplugin' then UIC::Application::RenderPluginAsset
		end
		klass.new(el,app)
	end
	attr_accessor :app, :el
	def initialize(el,app)
		self.app = app
		self.el  = el
	end
	xmlattribute :id
	xmlattribute :src do |new_src|
		# TODO: allow setting source to an instance, e.g. Presentation or Behavior
		@el[name] = new_src
		@content  = nil # remove the cache
	end
	def to_s
		@el.to_xml
	end
end



class UIC::Application::RenderPluginAsset < UIC::Application::Asset
	xmlattribute :args
end

