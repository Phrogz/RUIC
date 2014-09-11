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

		@graph_by_addset  = {}
		@addsets_by_graph = {}
		@logic.search('Add,Set').each do |addset|
			graph = @graph_by_id[addset['ref'][1..-1]]
			@graph_by_addset[addset] = graph
			@addsets_by_graph[graph] ||= {}
			slide = addset.parent
			name  = slide['name']
			index = name == 'Master Slide' ? 0 : slide.index + 1
			@addsets_by_graph[graph][name]  = addset
			@addsets_by_graph[graph][index] = addset
		end

		@asset_by_el = {}
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

	def images
		@doc.search('Graph Image').map{ |el| UIC::Presentation::Image.new(el,self) }
	end

	def at(path,root=@graph)
		name,path = path.split('.',2)
		node = root.element_children.find{ |el| @logic.at_xpath("State/Add[@ref='##{el['id']}'][@name='#{name}']") } || 
		       root.element_children.find{ |el| el['id']==name }
		if node
			if path
				at(path,node)
			else
				@asset_by_el[node] ||= app.metadata.new_instance(self,node)
			end
		end
	end
	alias_method :/, :at

	def get_asset_attribute( graph_element, property, slide=nil )
		if slide
			property.get(
				# Try for a Set on the specific slide
				( @addsets_by_graph[graph_element][slide] && @addsets_by_graph[graph_element][slide][property.name] ) ||
				# …else try the master slide
				( @addsets_by_graph[graph_element][0] && @addsets_by_graph[graph_element][0][property.name] ) ||
				# …else try the graph
				graph_element[property.name]
			)
			# TODO: handle animation (child of addset)
		else
			raise "GENERATE ATTRIBUTE PROXY"
		end
	end

	def owning_component( graph_element )
		component = graph_element.at_xpath('(ancestor::Component[1] | ancestor::Scene[1])[last()]')
		@asset_by_el[component] ||= app.metadata.new_instance(self,component)
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
end

class Nokogiri::XML::Element
	def index # Find the index of this element amongs its siblings
		xpath('count(preceding-sibling::*)').to_i
	end
end