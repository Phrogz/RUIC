# A `Presentation` represents a `.uip` presentation, created and edited by UI Composer Studio.
class UIC::Presentation
	include UIC::FileBacked

	# Create a new presentation. If you do not specify the `uip_path` to load from, you must
	# later set the `.file = `for the presentation, and then call the {#load_from_file} method.
	# @param uip_path [String] path to the `.uip` to load.
	def initialize( uip_path=nil )
		self.file = uip_path
		load_from_file if file_found?
	end

	# Load information for the presentation from disk.
	# If you supply a path to a `.uip` file when creating the presentation
	# this method is automatically called.
	# @return [nil]
	def load_from_file
		# TODO: this method assumes an application to find the metadata on; the metadata should be part of this class instance instead, shared with the app when present
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
			nil
		end

		rebuild_caches_from_document

		@asset_by_el  = {} # indexed by asset graph element
		@slides_for   = {} # indexed by asset graph element
		@slides_by_el = {} # indexed by slide state element
	end

	def to_xml
		doc.to_xml( indent:1, indent_text:"\t" )
		   .gsub( %r{(<\w+(?: [\w:]+="[^"]*")*)(/?>)}i, '\1 \2' )
		   .sub('"?>','" ?>')
	end

	def save_as(new_file)
		File.open(new_file,'w:utf-8'){ |f| f << to_xml }
	end

	# Update the presentation to be in-sync with the document.
	# Must be called whenever the in-memory representation of the XML document is changed.
	# Called automatically by all necessary methods; only necessary if script (dangerously)
	# manipulates the `.doc` of the presentation directly.
	#
	# @return [nil]
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
		nil
	end

	# Find an asset in the presentation based on its internal XML identifier.
	# @param id [String] the id of the asset (not an idref), e.g. `"Material_003"`.
	# @return [MetaData::Root] the found asset, or `nil` if could not be found.
	def asset_by_id( id )
		(@graph_by_id[id] && asset_for_el( @graph_by_id[id] ))
	end

	# @param asset [MetaData::Root] an asset in the presentation
	# @return [Integer] the index of the first slide where an asset is added (0 for master, non-zero for non-master).
	def slide_index(asset)
		# TODO: probably faster to .find the first @addsets_by_graph
		id = asset.el['id']
		slide = @logic.at(".//Add[@ref='##{id}']/..")
		(slide ? slide.xpath('count(ancestor::State) + count(preceding-sibling::State[ancestor::State])').to_i : 0) # the Scene is never added
	end

	# @param child_asset [MetaData::Root] an asset in the presentation.
	# @return [MetaData::Root] the scene graph parent of the child asset, or `nil` for the Scene.
	def parent_asset( child_asset )
		child_graph_el = child_asset.el
		unless child_graph_el==@scene || child_graph_el.parent.nil?
			asset_for_el( child_graph_el.parent )
		end
	end

	# @param parent_asset [MetaData::Root] an asset in the presentation.
	# @return [Array<MetaData::Root>] array of scene graph children of the specified asset.
	def child_assets( parent_asset )
		parent_asset.el.element_children.map{ |child| asset_for_el(child) }
	end

	# Get an array of all assets in the scene graph, in document order
	def assets
		@graph_by_id.map{ |id,graph_element| asset_for_el(graph_element) }
	end

	# @return [Hash] a mapping of image paths to arrays of the assets referencing them.
	def image_usage
		# TODO: this returns the same asset multiple times, with no indication of which property is using it; should switch to an Asset/Property pair, or some such.
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

	# @return [Array<String>] array of all image paths referenced by this presentation.
	def image_paths
		image_usage.keys
	end

	# Find or create an asset for a scene graph element.
	# @param el [Nokogiri::XML::Element] the scene graph element.
	def asset_for_el(el)
		(@asset_by_el[el] ||= el['class'] ? @class_by_ref[el['class']].new(self,el) : app.metadata.new_instance(self,el))
	end
	private :asset_for_el


	def referenced_files
		(
			(images + behaviors + effects + meshes + materials ).map(&:file)
			+ effects.flat_map(&:images)
			+ fonts
		).sort_by{ |f| parts = f.split(/[\/\\]/); [parts.length,parts] }
	end

	# @return [MetaData::Scene] the root scene asset for the presentation.
	def scene
		asset_for_el( @scene )
	end

	# Generate the script path for an asset in the presentation.
	#
	# * If `from_asset` is supplied the path will be relative to that asset (e.g. `"parent.parent.Group.Model"`).
	# * If `from_asset` is omitted the path will be absolute (e.g. `"Scene.Layer.Group.Model"`).
	#
	# @param asset [MetaData::Root] the asset to find the path to.
	# @param from_asset [MetaData::Root] the asset to find the path relative to.
	# @return [String] the script path to the element.
	def path_to( asset, from_asset=nil )
		el = asset.el

		to_parts = if el.ancestors('Graph')
			[].tap{ |parts|
				until el==@graph
					parts.unshift asset_for_el(el).name
					el = el.parent
				end
			}
		end
		if from_asset && from_asset.el.ancestors('Graph')
			from_el = from_asset.el
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

	# @return [Boolean] true if there any errors with the presentation.
	def errors?
		(!errors.empty?)
	end

	# @return [Array<String>] an array (possibly empty) of all errors in this presentation.
	def errors
		(file_found? ? [] : ["File not found: '#{file}'"])
	end

	# Find an element or asset in this presentation by scripting path.
	#
	# * If `root` is supplied, the path is resolved relative to that asset.
	# * If `root` is not supplied, the path is resolved as a root-level path.
	#
	# @example
	#  preso  = app.main
	#  scene  = preso.scene
	#  camera = scene/"Layer.Camera"
	#
	#  # Four ways to find the same layer
	#  layer1 = preso/"Scene.Layer"
	#  layer2 = preso.at "Scene.Layer"
	#  layer3 = preso.at "Layer", scene
	#  layer4 = preso.at "parent", camera
	#
	#  assert layer1==layer2 && layer2==layer3 && layer3==layer4
	#
	# @return [MetaData::Root] The found asset, or `nil` if it cannot be found.
	def at(path,root=@graph)
		name,path = path.split('.',2)
		root = root.el if root.respond_to?(:el)
		el = case name
			when 'parent' then root==@scene ? nil : root.parent
			when 'Scene'  then @scene
			else               root.element_children.find{ |el| asset_for_el(el).name==name }
		end
		path ? at(path,el) : asset_for_el(el) if el
	end
	alias_method :/, :at

	# Fetch the value of an asset's attribute on a particular slide. Slide `0` is the Master Slide, slide `1` is the first non-master slide.
	#
	# This method is used internally by assets; accessing attributes directly from the asset is generally more appropriate.
	#
	# @example
	#  preso = app.main_presentation
	#  camera = preso/"Scene.Layer.Camera"
	#
	#  assert preso.get_attribute(camera,'position',0) == camera['position',0]
	#
	# @param asset [MetaData::Root] the asset to fetch the attribute for.
	# @param attr_name [String] the name of the attribute to get the value of.
	# @param slide_name_or_index [String,Integer] the string name or integer index of the slide.
	def get_attribute( asset, attr_name, slide_name_or_index )
		graph_element = asset.el
		((addsets=@addsets_by_graph[graph_element]) && ( # State (slide) don't have any addsets
			( addsets[slide_name_or_index] && addsets[slide_name_or_index][attr_name] ) || # Try for a Set on the specific slide
			( addsets[0] && addsets[0][attr_name] ) # …else try the master slide
		) || graph_element[attr_name]) # …else try the graph
		# TODO: handle animation (child of addset)
	end

	# Set the value of an asset's attribute on a particular slide. Slide `0` is the Master Slide, slide `1` is the first non-master slide.
	#
	# This method is used internally by assets; accessing attributes directly from the asset is generally more appropriate.
	#
	# @example
	#  preso = app.main_presentation
	#  camera = preso/"Scene.Layer.Camera"
	#
	#  # The long way to set the attribute value
	#  preso.set_attribute(camera,'endtime',0,1000)
	#
	#  # …and the shorter way
	#  camera['endtime',0] = 1000
	#
	# @param asset [MetaData::Root] the asset to fetch the attribute for.
	# @param attr_name [String] the name of the attribute to get the value of.
	# @param slide_name_or_index [String,Integer] the string name or integer index of the slide.
	def set_attribute( asset, property_name, slide_name_or_index, str )
		graph_element = asset.el
		if attribute_linked?( asset, property_name )
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
					0.upto(slide_count).each{ |idx| set_attribute(asset,property_name,idx,str) }
				end
			else
				raise "TODO"
			end
		end
	end

	# @return [MetaData::Root] the component (or Scene) asset that owns the supplied asset.
	# @see MetaData::Root#component
	def owning_component( asset )
		asset_for_el( owning_component_element( asset.el ) )
	end

	# @return [MetaData::Root] the component asset that owns the supplied asset.
	# @see MetaData::Root#component
	def owning_component_element( graph_element )
		graph_element.at_xpath('(ancestor::Component[1] | ancestor::Scene[1])[last()]')
	end
	private :owning_component_element

	# @return [Nokogiri::XML::Element] the "time context" scene graph element that owns the supplied element.
	def owning_or_self_component_element( graph_element )
		graph_element.at_xpath('(ancestor-or-self::Component[1] | ancestor-or-self::Scene[1])[last()]')
	end
	private :owning_or_self_component_element

	# @return [Nokogiri::XML::Element] the logic-graph element representing the master slide for a scene graph element
	def master_slide_for( graph_element )
		comp = owning_or_self_component_element( graph_element )
		@logic.at("./State[@component='##{comp['id']}']")
	end
	private :master_slide_for

	# @param asset [MetaData::Root] the asset to get the slides for.
	# @return [SlideCollection] an array-like collection of all slides that the asset is available on.
	# @see MetaData::Root#slides
	def slides_for( asset )
		graph_element = asset.el
		@slides_for[graph_element] ||= begin
			slides = []
			master = master_slide_for( graph_element )
			slides << [master,0] if graph_element==@scene || (@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][0])
			slides.concat( master.xpath('./State').map.with_index{ |el,i| [el,i+1] } )
			slides.map!{ |el,idx| @slides_by_el[el] ||= app.metadata.new_instance(self,el).tap{ |s| s.index=idx; s.name=el['name'] } }
			UIC::SlideCollection.new( slides )
		end
	end

	# @return [Boolean] true if the asset exists on the supplied slide.
	# @see MetaData::Root#has_slide?
	def has_slide?( asset, slide_name_or_index )
		graph_element = asset.el
		if graph_element == @scene
			# The scene is never actually added, so we'll treat it just like the first add, which is on the master slide of the scene
			has_slide?( asset_for_el( @addsets_by_graph.first.first ), slide_name_or_index )
		else
			@addsets_by_graph[graph_element][slide_name_or_index] || @addsets_by_graph[graph_element][0]
		end
	end

	# @example
	#  preso  = app.main
	#  camera = preso/"Scene.Layer.Camera"
	#
	#  # Two ways of determining if an attribute for an asset is linked.
	#  if preso.attribute_linked?( camera, 'fov' )
	#  if camera['fov'].linked?
	#
	# @return [Boolean] true if this asset's attribute is linked on the master slide.
	# @see ValuesPerSlide#linked?
	def attribute_linked?( asset, attribute_name )
		graph_element = asset.el
		!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][1] && @addsets_by_graph[graph_element][1].key?(attribute_name))
	end

	# Unlinks a master attribute, yielding distinct values on each slide. If the asset is not on the master slide, or the attribute is already unlinked, no change occurs.
	#
	# @param asset [MetaData::Root] the master asset to unlink the attribute on.
	# @param attribute_name [String] the name of the attribute to unlink.
	# @return [Boolean] `true` if the attribute was previously linked; `false` otherwise.
	def unlink_attribute(asset,attribute_name)
		graph_element = asset.el
		if master?(asset) && attribute_linked?(asset,attribute_name)
			master_value = get_attribute( asset, attribute_name, 0 )
			slides_for( asset ).to_ary[1..-1].each do |slide|
				addset = slide.el.at_xpath( ".//*[@ref='##{graph_element['id']}']" ) || slide.el.add_child("<Set ref='##{graph_element['id']}'/>").first
				addset[attribute_name] = master_value
			end
			rebuild_caches_from_document
			true
		else
			false
		end
	end

	# Replace an existing asset with a new kind of asset.
	#
	# @param existing_asset [MetaData::Root] the existing asset to replace.
	# @param new_type [String] the name of the asset type, e.g. `"ReferencedMaterial"` or `"Group"`.
	# @param attributes [Hash] initial attribute values for the new asset.
	# @return [MetaData::Root] the newly-created asset.
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

	# @return [Boolean] `true` if the asset is added on the master slide.
	def master?(asset)
		graph_element = asset.el
		(graph_element == @scene) || !!(@addsets_by_graph[graph_element] && @addsets_by_graph[graph_element][0])
	end

	def find(options={})
		index = -1
		start = options.key?(:_under) ? options.delete(:_under).el : @graph
		[].tap do |result|
			start.xpath('./descendant::*').each do |el|
				asset = asset_for_el(el)
				next unless options.all? do |att,val|
					case att
						when :_type   then el.name == val
						when :_slide  then has_slide?(asset,val)
						when :_master then master?(asset)==val
						else
							if asset.properties[att.to_s]
								value = asset[att.to_s].value
								case val
									when Regexp  then val =~ value.to_s
									when Numeric then (val-value).abs < 0.001
									when Array   then value.to_a.zip(val).map{ |a,b| !b || (a-b).abs<0.001 }.all?
									else value == val
								end
							end
					end
				end
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