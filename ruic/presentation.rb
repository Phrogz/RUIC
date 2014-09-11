class UIC::Application::PresentationAsset < UIC::Application::Asset
	xmlattribute :id do |new_id|
		initial_preso_id = @app.initial_presentation.id
		old_id = id
		super(new_id)
		@app.initial_presentation = self if initial_preso_id==old_id
	end
	xmlattribute :active

	def presentation
		@content ||= UIC.Presentation( app.path_to(src) ).tap{ |pres| pres.asset=self }
	end
end

class UIC::Presentation
	include UIC::FileBacked
	include UIC::ApplicationAsset
	def initialize( xml )
		@doc = Nokogiri.XML( xml )
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
			slidename = addset.parent['name']
			@addsets_by_graph[graph][slidename] = addset
		end

		@assets_by_el = {}
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
				@assets_by_el[node] ||= Asset.from(self,node)
			end
		end
	end
	alias_method :/, :at

end

def UIC.Presentation( uip_path )
	UIC::Presentation.new( File.read( uip_path, encoding:'utf-8' ) )
		.tap{ |p| p.file = uip_path }
end