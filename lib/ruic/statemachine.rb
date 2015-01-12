class UIC::StateMachine
	include UIC::XMLFileBacked
	def initialize( scxml )
		self.file = scxml
	end
	def inspect
		"<#{self.class} #{file}>"
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

		@visuals = app.doc.at( "/xmlns:application/xmlns:statemachine[@ref='##{id}']/xmlns:visual-states" )
		@visuals ||= app.doc.root.add_child("<statemachine ref='##{id}'><visual-states/></statemachine>")
		@visual_states      = VisualStates.new( self, @visuals )
		@visual_transitions = VisualTransitions.new( self, @visuals )

		self.file  = application.absolute_path(src)
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
			app.absolute_path( visual_action.value[/\A(['"])([^'"]+)\1\Z/,2] )
		end.each do |image_path,array|
			array.map!(&:last)
		end
	end

	# @return [Array<VisualAction>] all visual actions in the `.uia` for this state machine.
	def visual_actions
		visual_states.flat_map(&:enter_actions) +
		visual_states.flat_map(&:exit_actions) +
		visual_transitions.flat_map(&:actions)
	end

	def referenced_files
		visual_actions.map do |action|
			if action.is_a?(VisualAction::SetAttribute) && (el=action.element) && (path=action.value[ /\A(['"])([^'"]+)\1\Z/, 2 ])
				type=el.properties[ action.attribute ].type
				if action.attribute=='sourcepath' || action.attribute=='importfile' || type=='Texture'
					app.absolute_path( path.sub(/#.+$/,'') )
				elsif type=='Font'
					app.absolute_path( File.join( 'fonts', path.sub(/$/,'.ttf') ) )
				end
			end
		end.compact.uniq
	end

	class UIC::Application::StateMachine::VisualStates
		include Enumerable
		def initialize(app_machine,visuals_el)
			@machine = app_machine
			@wrap    = visuals_el
			@by_el   = {}
		end
		def each
			@wrap.xpath('xmlns:state').each{ |el| yield @by_el[el] ||= VisualState.new(el,@machine) }
		end
		def [](id)
			if el=@wrap.at("xmlns:state[@ref='#{id}']")
				@by_el[el] ||= VisualState.new(el,@machine)
			end
		end
		def length
			@wrap.xpath('count(xmlns:state)').to_i
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
			@wrap.xpath('xmlns:transition').each{ |el| yield @by_el[el] ||= VisualTransition.new(el,@machine) }
		end
		def [](id)
			if el=@wrap.at("xmlns:transition[@ref='#{id}']")
				@by_el[el] ||= VisualTransition.new(el,@machine)
			end
		end
		def length
			@wrap.xpath('count(xmlns:transition)').to_i
		end
		alias_method :count, :length
	end

	class UIC::Application::StateMachine::VisualState
		include UIC::ElementBacked

		# @!attribute ref
		#   @return [String] the `id` of the state in the state machine whose enter/exit will trigger the attached visual actions.
		xmlattribute :ref

		# @return [Nokogiri::XML::Element] the Nokogiri element in the `.uia` representing this visual state.
		attr_reader :el

		# @return [Application::StateMachine] the state machine containing the referenced state.
		attr_reader :machine

		def initialize(el,machine)
			@el = el
			@machine = machine
		end

		def enter_actions
			@el.xpath('xmlns:enter/*').to_a.map{ |el| VisualAction.create(el,self) }
		end

		def exit_actions
			@el.xpath('xmlns:exit/*').to_a.map{ |el| VisualAction.create(el,self) }
		end
	end

	class UIC::Application::StateMachine::VisualTransition
		include UIC::ElementBacked

		# @!attribute ref
		#   @return [String] the `uic:id` of the transition that will trigger the attached visual actions.
		xmlattribute :ref

		# @return [Nokogiri::XML::Element] the Nokogiri element in the `.uia` representing this visual state.
		attr_reader :el

		# @return [Application::StateMachine] the state machine containing the referenced state.
		attr_reader :machine

		def initialize(el,machine)
			@el = el
			@machine = machine
		end
		def actions
			@el.xpath('./*').to_a.map{ |el| VisualAction.create(el,self) }
		end
	end

	class UIC::Application::StateMachine::VisualAction
		include UIC::ElementBacked

		# @!attribute element
		#   @return [UIC::MetaData::AssetBase] the element in a UIC presentation affected by this action.
		xmlattribute(:element, lambda{ |path,action| (action.machine.app / path) }){ |element| element.path }

		# @return [Nokogiri::XML::Element] the Nokogiri element representing this action in the `.uia`.
		attr_reader :el

		# @return [VisualState,VisualTransition] the visual state or transition wrapping this action.
		attr_reader :owner

		# @return [Application::StateMachine] the state machine triggering this action.
		attr_reader :machine

		def self.create(el,owner)
			klass = case el.name
				when 'goto-slide'    then GotoSlide
				when 'call'          then Call
				when 'set-attribute' then SetAttribute
				when 'fire-event'    then FireEvent
				else                      Generic
			end
			klass.new(el,owner)
		end

		def initialize(el,owner)
			@el = el
			@owner = owner
			@machine = owner.machine
		end

		class UIC::Application::StateMachine::VisualAction::GotoSlide < self
			# TODO: xmlattributes
		end

		class UIC::Application::StateMachine::VisualAction::Call < self
			# TODO: xmlattributes
		end

		class UIC::Application::StateMachine::VisualAction::SetAttribute < self
			# @!attribute attribute
			#   @return [String] the name of the attribute to set.
			xmlattribute :attribute

			# @!attribute value
			#   @return [String] the Lua expression to evaluate as the new value.
			xmlattribute :value
		end

		class UIC::Application::StateMachine::VisualAction::FireEvent < self
			# TODO: xmlattributes
		end

		class UIC::Application::StateMachine::VisualAction::Generic
			# @return [Nokogiri::XML::Element] the Nokogiri element representing this action in the `.uia`.
			attr_reader :el

			# @return [VisualState,VisualTransition] the visual state or transition wrapping this action.
			attr_reader :owner

			# TODO: xmlattributes

			def initialize(el,owner)
				@el = el
				@owner = owner
				@machine = owner.machine
			end
		end
	end
end