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

		@class_by_ref = {}
		@doc.xpath('/UIP/Project/Classes/*').each do |reference|
			path = app.path_to(reference['sourcepath'])
			raise "Cannot find file '#{path}' referenced by #{self.inspect}" unless File.exist?( path )
			metaklass = case reference.name
				when 'CustomMaterial'
					meta = Nokogiri.XML(File.read(path,encoding:'utf-8')).at('/*/MetaData')
					from = app.metadata.by_name[ 'MaterialBase' ]
					app.metadata.create_class( meta, from )
				when 'Effect'
					meta = Nokogiri.XML(File.read(path,encoding:'utf-8')).at('/*/MetaData')
					from = app.metadata.by_name[ 'Effect' ]
					app.metadata.create_class( meta, from )
				when 'Behavior'
					lua  = File.read(path,encoding:'utf-8')
					meta = lua[ /--\[\[(.+?)(?:--)?\]\]/m, 1 ]
					meta = Nokogiri.XML("<MetaData>#{meta}</MetaData>").root
					from = app.metadata.by_name[ 'Behavior' ]
					app.metadata.create_class( meta, from )
			end
			@class_by_ref[ "##{reference['id']}" ] = metaklass
		end

		@graph_by_id = {}
		@scene.traverse{ |x| @graph_by_id[x['id']]=x if x.is_a?(Nokogiri::XML::Element) }

		@graph_by_addset  = {}
		@addsets_by_graph = {}
		slideindex = {}
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

	def asset_by_id( id )
		@graph_by_id[id] && asset_for_el( @graph_by_id[id] )
	end

	# Find the index of the slide where an element is added
	def slide_index(graph_element)
		# TODO: probably faster to .find the first @addsets_by_graph
		slide = @logic.at(".//Add[@ref='##{graph_element['id']}']/..")
		slide ? slide.xpath('count(ancestor::State) + count(preceding-sibling::State[ancestor::State])').to_i : 0 # the Scene is never added
	end

	# Get an array of all assets in the scene graph, in document order
	def assets
		@graph_by_id.map{ |id,graph_element| asset_for_el(graph_element) }
	end

	# Returns a hash mapping image paths to arrays of the assets referencing them
	def image_usage
		assets # TODO: speed up by only finding Material/CustomMaterial/Effect/Behavior assets
			.flat_map do |asset|
				asset.properties.values
					.select{ |property| property.type=='Image' || property.type == 'Texture' }
					.flat_map do |property|
						asset[property.name].values.map do |value|
							[
								property.type=='img' ? value['sourcepath'] : value,
								asset
							]
						end
					end
		end.group_by(&:first).each{ |path,array| array.map!(&:last) }
	end

	def image_paths
		image_usage.keys
	end


	def asset_for_el(el)
		@asset_by_el[el] ||= el['class'] ? @class_by_ref[el['class']].new(self,el) : app.metadata.new_instance(self,el)
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

	def errors?
		!errors.empty?
	end

	def errors
		file_found? ? [] : ["File not found: '#{file}'"]
	end

	def at(path,root=@graph)
		name,path = path.split('.',2)
		node = root.element_children.find{ |el| @logic.at_xpath(".//State/Add[@ref='##{el['id']}'][@name='#{name}']") } || 
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
		comp = owning_or_self_component_element( graph_element )
		@logic.at("./State[@component='##{comp['id']}']")
	end

	def slides_for( graph_element )
		slides = []
		master = master_slide_for( graph_element )
		slides << [master,0] if graph_element==@scene || (@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][0])
		slides.concat( master.xpath('./State').map.with_index{ |el,i| [el,i+1] } )
		slides.map!{ |el,idx| @slides_by_el[el] ||= app.metadata.new_instance(self,el).tap{ |s| s.index=idx } }
		UIC::SlideCollection.new( slides )
	end

	def attribute_linked?(graph_element,attribute_name)
		!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][1].key?(attribute_name))
	end

	# Is this element added on the master slide?
	def master?(graph_element)
		(graph_element == @scene) || !!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][0])
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