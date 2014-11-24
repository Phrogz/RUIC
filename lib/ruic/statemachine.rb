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
	# @!parse extend UIC::ElementBacked::ClassMethods
	xmlattribute :id
	xmlattribute :src
	xmlattribute :datamodel
	attr_reader :visual_states
	attr_reader :visual_transitions
	def initialize(application,el)
		self.owner = application
		self.el    = el
		self.file  = application.resolve_file_path(src)
		super( File.read( file, encoding:'utf-8' ) )
		@visuals = @doc.at( "/application/statemachine[@ref='##{id}']/visual-states" )
		@visuals ||= @doc.root.add_child("<statemachine ref='##{id}'><visual-states/></statemachine>")
		@visual_states      = VisualStates.new( self, @visuals )
		@visual_transitions = VisualTransitions.new( self, @visuals )
	end
	alias_method :app, :owner

	def image_usage
		(
			visual_states.flat_map{ |vs| vs.enter_actions.flat_map{ |a| [a,vs] } } +
			visual_states.flat_map{ |vs| vs.exit_actions.flat_map{ |a| [a,vs] } } +
			visual_transitions.flat_map{ |vt| vt.actions.flat_map{ |a| [a,vt] } }
		).select do |visual_action,owner|
			visual_action.is_a?(UIC::Application::StateMachine::VisualAction::SetAttribute) &&
			visual_action.value[/\A(['"])[^'"]+\1\Z/] && # ensure that it's a simple string value
			visual_action.element.properties[ visual_action.attribute ].is_a?( UIC::Property::Image )
		end.group_by do |visual_action,owner|
			visual_action.value[/\A(['"])([^'"]+)\1\Z/,2]
		end.each do |image_path,array|
			array.map!(&:last)
		end
	end

	class UIC::Application::StateMachine::VisualStates
		include Enumerable
		def initialize(app_machine,visuals_el)
			@machine = app_machine
			@wrap    = visuals_el
			@by_el   = {}
		end
		def each
			@wrap.xpath('state').each{ |el| yield @by_el[el] ||= VisualState.new(el) }
		end
		def [](id)
			if el=@wrap.at("state[@ref='#{id}']")
				@by_el[el] ||= VisualState.new(el)
			end
		end
		def length
			@wrap.xpath('count(state)').to_i
		end
		alias_method :count, :length
	end

	class UIC::Application::StateMachine::VisualTransitions
		include Enumerable
		def initialize(app_machine,visuals_el)
			@machine = app_machine
			@wrap    = visuals_el
			@by_el   = {}
		end
		def each
			@wrap.xpath('transition').each{ |el| yield @by_el[el] ||= VisualState.new(el) }
		end
		def [](id)
			if el=@wrap.at("transition[@ref='#{id}']")
				@by_el[el] ||= VisualTransition.new(el)
			end
		end
		def length
			@wrap.xpath('count(transition)').to_i
		end
		alias_method :count, :length
	end

	class UIC::Application::StateMachine::VisualState
		def initialize(el)
			@el = el
		end
	end

	class UIC::Application::StateMachine::VisualTransition
		def initialize(el)
			@el = el
		end
	end


end