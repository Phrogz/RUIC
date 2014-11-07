class UIC::Presentation
	include UIC::FileBacked
	def initialize( uip_path )
		self.file = uip_path
		load_from_file if file_found?
	end

	def load_from_file
		@doc = Nokogiri.XML( File.read( file, encoding:'utf-8' ), &:noblanks )
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
					app.metadata.create_class( meta, from, reference.name )
				when 'Effect'
					meta = Nokogiri.XML(File.read(path,encoding:'utf-8')).at('/*/MetaData')
					from = app.metadata.by_name[ 'Effect' ]
					app.metadata.create_class( meta, from, reference.name )
				when 'Behavior'
					lua  = File.read(path,encoding:'utf-8')
					meta = lua[ /--\[\[(.+?)(?:--)?\]\]/m, 1 ]
					meta = Nokogiri.XML("<MetaData>#{meta}</MetaData>").root
					from = app.metadata.by_name[ 'Behavior' ]
					app.metadata.create_class( meta, from, reference.name )
			end
			@class_by_ref[ "##{reference['id']}" ] = metaklass
		end

		rebuild_caches_from_document

		@asset_by_el  = {} # indexed by asset graph element
		@slides_for   = {} # indexed by asset graph element
		@slides_by_el = {} # indexed by slide state element
	end

	def to_xml
		@doc.to_xml( indent:1, indent_text:"\t" )
		    .gsub( %r{(<\w+(?: [\w:]+="[^"]*")*)(/?>)}i, '\1 \2' )
		    .sub('"?>','" ?>')
	end

	def save!
		File.open(file,'w:utf-8'){ |f| f << to_xml }
	end

	def save_as(new_file)
		File.open(new_file,'w:utf-8'){ |f| f << to_xml }
	end

	def rebuild_caches_from_document
		@graph_by_id = {}
		@scene.traverse{ |x| @graph_by_id[x['id']]=x if x.is_a?(Nokogiri::XML::Element) }

		@graph_by_addset  = {}
		@addsets_by_graph = {}
		slideindex = {}
		@logic.xpath('.//Add|.//Set').each do |addset|
			graph = @graph_by_id[addset['ref'][1..-1]]
			@graph_by_addset[addset] = graph
			@addsets_by_graph[graph] ||= {}
			slide = addset.parent
			name  = slide['name']
			index = name == 'Master Slide' ? 0 : (slideindex[slide] ||= (slide.index('State') + 1))
			@addsets_by_graph[graph][name]  = addset
			@addsets_by_graph[graph][index] = addset
		end
	end

	def asset_by_id( id )
		(@graph_by_id[id] && asset_for_el( @graph_by_id[id] ))
	end

	# Find the index of the slide where an element is added
	def slide_index(graph_element)
		# TODO: probably faster to .find the first @addsets_by_graph
		slide = @logic.at(".//Add[@ref='##{graph_element['id']}']/..")
		(slide ? slide.xpath('count(ancestor::State) + count(preceding-sibling::State[ancestor::State])').to_i : 0) # the Scene is never added
	end

	def parent_asset( child_graph_el )
		unless child_graph_el==@scene || child_graph_el.parent.nil?
			asset_for_el( child_graph_el.parent )
		end
	end

	def child_assets( parent_graph_el )
		parent_graph_el.element_children.map{ |child| asset_for_el(child) }
	end

	# Get an array of all assets in the scene graph, in document order
	def assets
		@graph_by_id.map{ |id,graph_element| asset_for_el(graph_element) }
	end

	# Returns a hash mapping image paths to arrays of the assets referencing them
	def image_usage
		asset_types = app.metadata.by_name.values + @class_by_ref.values

		image_properties_by_type = asset_types.flat_map do |type|
			type.properties.values
			    .select{ |property| property.type=='Image' || property.type == 'Texture' }
			    .map{ |property| [type,property] }
		end.group_by(&:first).tap{ |x| x.each{ |t,a| a.map!(&:last) } }

		Hash[ assets.each_with_object({}) do |asset,usage|
			if properties = image_properties_by_type[asset.class]
				properties.each do |property|
					asset[property.name].values.compact.each do |value|
						value = value['sourcepath'] if property.type=='Image'
						unless value.nil? || value.empty?
							value = value.gsub('\\','/').sub(/^.\//,'')
							usage[value] ||= []
							usage[value] << asset
						end
					end
				end
			end
		end.sort_by do |path,assets|
			parts = path.downcase.split '/'
			[ parts.length, parts ]
		end ].tap{ |h| h.extend(UIC::PresentableHash) }
	end

	def image_paths
		image_usage.keys
	end

	def asset_for_el(el)
		(@asset_by_el[el] ||= el['class'] ? @class_by_ref[el['class']].new(self,el) : app.metadata.new_instance(self,el))
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

	def path_to( el, from_el=nil )
		to_parts = if el.ancestors('Graph')
			[].tap{ |parts|
				until el==@graph
					parts.unshift asset_for_el(el).name
					el = el.parent
				end
			}
		end
		if from_el && from_el.ancestors('Graph')
			from_parts = [].tap{ |parts|
				until from_el==@graph
					parts.unshift asset_for_el(from_el).name
					from_el = from_el.parent
				end
			}
			until to_parts.empty? || from_parts.empty? || to_parts.first!=from_parts.first
				to_parts.shift
				from_parts.shift
			end
			to_parts.unshift *(['parent']*from_parts.length)
		end
		to_parts.join('.')
	end

	def errors?
		(!errors.empty?)
	end

	def errors
		(file_found? ? [] : ["File not found: '#{file}'"])
	end

	def at(path,root=@graph)
		name,path = path.split('.',2)
		el = case name
			when 'parent' then root==@scene ? nil : root.parent
			when 'Scene'  then @scene
			else               root.element_children.find{ |el| asset_for_el(el).name==name }
		end
		path ? at(path,el) : asset_for_el(el) if el
	end
	alias_method :/, :at

	def get_attribute( graph_element, property_name, slide_name_or_index )
		((addsets=@addsets_by_graph[graph_element]) && ( # State (slide) don't have any addsets
			( addsets[slide_name_or_index] && addsets[slide_name_or_index][property_name] ) || # Try for a Set on the specific slide
			( addsets[0] && addsets[0][property_name] ) # …else try the master slide
		) || graph_element[property_name]) # …else try the graph
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
		@slides_for[graph_element] ||= begin
			slides = []
			master = master_slide_for( graph_element )
			slides << [master,0] if graph_element==@scene || (@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][0])
			slides.concat( master.xpath('./State').map.with_index{ |el,i| [el,i+1] } )
			slides.map!{ |el,idx| @slides_by_el[el] ||= app.metadata.new_instance(self,el).tap{ |s| s.index=idx; s.name=el['name'] } }
			UIC::SlideCollection.new( slides )
		end
	end

	def has_slide?( graph_element, slide_name_or_index )
		if graph_element == @scene
			# The scene is never actually added, so we'll treat it just like the first add, which is on the master slide of the scene
			has_slide?( @addsets_by_graph.first.first, slide_name_or_index )
		else
			@addsets_by_graph[graph_element][slide_name_or_index] || @addsets_by_graph[graph_element][0]
		end
	end

	def attribute_linked?(graph_element,attribute_name)
		!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][1] && @addsets_by_graph[graph_element][1].key?(attribute_name))
	end

	def unlink_attribute(graph_element,attribute_name)
		if master?(graph_element) && attribute_linked?(graph_element,attribute_name)
			master_value = get_attribute( graph_element, attribute_name, 0 )
			slides_for( graph_element ).to_ary[1..-1].each do |slide|
				addset = slide.el.at_xpath( ".//*[@ref='##{graph_element['id']}']" ) || slide.el.add_child("<Set ref='##{graph_element['id']}'/>").first
				addset[attribute_name] = master_value
			end
			rebuild_caches_from_document
			true
		end
	end

	def replace_asset( existing_asset, new_type, attributes={} )
		old_el = existing_asset.el
		new_el = old_el.replace( "<#{new_type}/>" ).first
		attributes['id'] = old_el['id']
		attributes.each{ |att,val| new_el[att.to_s] = val }
		asset_for_el( new_el ).tap do |new_asset|
			unsupported_attributes = ".//*[name()='Add' or name()='Set'][@ref='##{old_el['id']}']/@*[name()!='ref' and #{new_asset.properties.keys.map{|p| "name()!='#{p}'"}.join(' and ')}]"
			@logic.xpath(unsupported_attributes).remove
			rebuild_caches_from_document
		end
	end

	# Is this element added on the master slide?
	def master?(graph_element)
		(graph_element == @scene) || !!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][0])
	end

	def find(options={})
		index = -1
		start = options[:under] ? options[:under].el : @graph
		(options[:attributes]||={})[:name]=options[:name] if options[:name]
		[].tap do |result|
			start.xpath('./descendant::*').each do |el|
				next if options.key?(:type)   && el.name    != options[:type]
				next if options.key?(:slide)  && !has_slide?(el,options[:slide])
				next if options.key?(:master) && master?(el)!= options[:master]
				asset = asset_for_el(el)
				next if options.key?(:attributes) && options[:attributes].any?{ |att,val|
					if asset.properties[att.to_s]
						value = asset[att.to_s].value
						case val
							when Regexp  then val !~ value.to_s
							when Numeric then (val-value).abs >= 0.001
							when Array   then value.to_a.zip(val).map{ |a,b| b && (a-b).abs>=0.001 }.any?
							else value != val
						end
					end
				}
				yield asset, index+=1 if block_given?
				result << asset
			end
		end
	end

	def inspect
		"<#{self.class} #{File.basename(file)}>"
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

	def path_to( el, from=nil )
		"#{id}:#{super}"
	end
end

class Nokogiri::XML::Element
	def index(kind='*') # Find the index of this element amongs its siblings
		xpath("count(./preceding-sibling::#{kind})").to_i
	end
end