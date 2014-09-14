class UIC::Presentation
	include UIC::FileBacked
	def initialize( uip_path )
		self.file = uip_path
		load_from_file if file_found?
	end

	def load_from_file
		@doc = Nokogiri.XML( File.read( file, encoding:'utf-8' ) )
		@graph = @doc.at('Graph')
		@scene = @graph.at('Scene')
		@logic = @doc.at('Logic')

		@graph_by_id = {}
		@scene.traverse{ |x| @graph_by_id[x['id']]=x if x.is_a?(Nokogiri::XML::Element) }
		slideindex = {}

		@graph_by_addset  = {}
		@addsets_by_graph = {}
		@logic.search('Add,Set').each do |addset|
			graph = @graph_by_id[addset['ref'][1..-1]]
			@graph_by_addset[addset] = graph
			@addsets_by_graph[graph] ||= {}
			slide = addset.parent
			name  = slide['name']
			index = name == 'Master Slide' ? 0 : (slideindex[slide] ||= (slide.index('State') + 1))
			@addsets_by_graph[graph][name]  = addset
			@addsets_by_graph[graph][index] = addset
		end

		@asset_by_el  = {}
		@slides_by_el = {}
	end

	def asset_for_el(el)
		@asset_by_el[el] ||= app.metadata.new_instance(self,el)
	end

	attr_reader :addsets_by_graph
	protected :addsets_by_graph

	def referenced_files
		(
			(images + behaviors + effects + meshes + materials ).map(&:file)
			+ effects.flat_map(&:images)
			+ fonts
		).sort_by{ |f| parts = f.split(/[\/\\]/); [parts.length,parts] }
	end

	def scene
		asset_for_el( @scene )
	end

	def path_to( el )
		if el.ancestors('Graph')
			path = []
			until el==@graph
				path.unshift el==@scene ? 'Scene' : get_attribute(el,'name',0)
				el = el.parent
			end
			path.join('.')
		end
	end

	def at(path,root=@graph)
		name,path = path.split('.',2)
		node = root.element_children.find{ |el| @logic.at_xpath("State/Add[@ref='##{el['id']}'][@name='#{name}']") } || 
		       root.element_children.find{ |el| el['id']==name }
		if node
			if path
				at(path,node)
			else
				asset_for_el(node)
			end
		end
	end
	alias_method :/, :at

	def get_attribute( graph_element, property_name, slide_name_or_index )
		(addsets=@addsets_by_graph[graph_element]) && ( # State (slide) don't have any addsets
			( addsets[slide_name_or_index] && addsets[slide_name_or_index][property_name] ) || # Try for a Set on the specific slide
			( addsets[0] && addsets[0][property_name] ) # …else try the master slide
		) || graph_element[property_name] # …else try the graph
		# TODO: handle animation (child of addset)
	end

	def set_attribute( graph_element, property_name, slide_name_or_index, str )
		if attribute_linked?( graph_element, property_name )
			if @addsets_by_graph[graph_element]
				@addsets_by_graph[graph_element][0][property_name] = str
			else
				raise "TODO"
			end
		else
			if @addsets_by_graph[graph_element]
				if slide_name_or_index
					@addsets_by_graph[graph_element][slide_name_or_index][property_name] = str
				else
					master = master_slide_for( graph_element )
					slide_count = master.xpath('count(./State)').to_i
					0.upto(slide_count).each{ |idx| set_attribute(graph_element,property_name,idx,str) }
				end
			else
				raise "TODO"
			end
		end
	end

	def owning_component( graph_element )
		asset_for_el( owning_component_element( graph_element ) )
	end

	def owning_component_element( graph_element )
		graph_element.at_xpath('(ancestor::Component[1] | ancestor::Scene[1])[last()]')
	end

	def owning_or_self_component_element( graph_element )
		graph_element.at_xpath('(ancestor-or-self::Component[1] | ancestor-or-self::Scene[1])[last()]')
	end

	def master_slide_for( graph_element )
		comp   = owning_or_self_component_element( graph_element )
		@logic.at("./State[@component='##{comp['id']}']")
	end

	def slides_for( graph_element )
		master = master_slide_for( graph_element )
		kids   = master.xpath('./State')
		slides = [master,*kids].map{ |el| @slides_by_el[el] ||= app.metadata.new_instance(self,el) }
		UIC::SlideCollection.new( slides )
	end

	def attribute_linked?(graph_element,attribute_name)
		!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][1].key?(attribute_name))
	end
end

def UIC.Presentation( uip_path )
	UIC::Presentation.new( uip_path )
end

class UIC::Application::Presentation < UIC::Presentation
	include UIC::ElementBacked
	xmlattribute :id
	xmlattribute :src
	xmlattribute :id do |new_id|
		main_preso = app.main_presentation
		super(new_id)
		app.main_presentation=self if main_preso==self
	end
	xmlattribute :active

	def initialize(application,el)
		self.owner = application
		self.el    = el
		super( application.path_to(src) )
	end
	alias_method :app, :owner

	def path_to( el )
		"#{id}:#{super}"
	end
end

class Nokogiri::XML::Element
	def index(kind='*') # Find the index of this element amongs its siblings
		xpath("count(./preceding-sibling::#{kind})").to_i
	end
end