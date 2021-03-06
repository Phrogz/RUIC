# The `Application` represents the root of your NDD application, corresponding to a `.uia` file.
class NDD::Application
	include NDD::XMLFileBacked

	def inspect
		"<NDD::Application '#{File.basename(file)}'#{:' FILENOTFOUND' unless file_found?}>"
	end

	# @return [NDD::MetaData] the metadata loaded for this application
	attr_reader :metadata

	# @param metadata [NDD::MetaData] the `MetaData` to use for this application.
	# @param uia_path [String] path to a `.uia` file to load.
	#        If omitted you will need to later set the `.file = ` for the
	#        instance and then call {#load_from_file}.
	def initialize(metadata,uia_path=nil)
		@assets   = {}
		@metadata = metadata
		self.file = uia_path
	end

	# Loads the application from the file. If you pass the path to your `.uia`
	# to {#initialize} then this method is called automatically.
	#
	# @return [nil]
	def on_doc_loaded
		@assets  = @doc.search('assets *').map do |el|
			case el.name
				when 'behavior'     then NDD::Application::Behavior
				when 'statemachine' then NDD::Application::StateMachine
				when 'presentation' then NDD::Application::Presentation
				when 'renderplugin' then NDD::Application::RenderPlugin
			end.new(self,el)
		end.group_by{ |asset| asset.el.name }
		nil
	end

	# Find an asset by `.uia` identifier or path to the asset.
	# @example
	#   main1 = app['#main']
	#   main2 = app['MyMain.uip']
	#   main3 = app.main_presentation
	#   assert main1==main2 && main2==main3
	# @param asset_id_or_path [String] an idref like `"#status"` or a relative path to the asset like `"VehicleStatus.uip"` or `"scripts/Main.lua"`.
	# @return [NDD::Application::Behavior]
	# @return [NDD::Application::StateMachine]
	# @return [NDD::Application::Presentation]
	# @return [NDD::Application::RenderPlugin]
	def [](asset_id_or_path)
		all = assets
		if asset_id_or_path.start_with?('#')
			id = asset_id_or_path[1..-1]
			all.find{ |asset| asset.id==id }
		else
			full_path = File.expand_path(asset_id_or_path,File.dirname(file))
			all.find{ |asset| asset.file==full_path }
		end
	end

	# Files in the application directory not used by the application.
	#
	# @return [Array<String>] absolute paths of files in the directory not used by the application.
	def unused_files( hierarchy=false )
		unused = (directory_files - referenced_files).sort
		if hierarchy
			root = File.dirname(file)
			NDD.tree_hierarchy(root) do |dir|
				File.directory?(dir) ? Dir.chdir(dir){ Dir['*'].map{ |f| File.expand_path(f) } } : []
			end.map do |prefix,file|
				if file
					all = unused.select{ |path| path[/^#{file}/] }
					unless all.empty?
						size = NiceBytes.nice_bytes(all.map{ |f| File.size(f) }.inject(:+))
						partial = file.sub(/^#{root}\//o,'')
						if File.directory?(file)
							"%s %s (%d files, %s)" % [prefix,partial,all.length,size]
						else
							"%s %s (%s)" % [prefix,partial,size]
						end
					end
				else
					prefix
				end
			end.compact.join("\n")
		else
			unused
		end
	end

	# Files referenced by the application but not present in the directory.
	#
	# @return [Array<String>] absolute paths of files referenced but gone.
	def missing_files
		(referenced_files - directory_files).sort
	end

	# @return [Array<String>] absolute paths of files referenced by the application.
	def referenced_files
		# TODO: state machines can reference external scripts
		# TODO: behaviors can reference external scripts
		(
			[file] +
			assets.map{ |asset| absolute_path(asset.src) } +
			statemachines.flat_map(&:referenced_files) +
			presentations.flat_map(&:referenced_files)
		).uniq
	end

	# @return [Array<String>] absolute paths of all files present in the application directory (used or not).
	def directory_files
		dir = File.dirname(file)
		Dir.chdir(dir){ Dir['**/*.*'] }.map{ |f| File.expand_path(f,dir) }
	end

	# @return [Array] all assets referenced by the application. Ordered by the order they appear in the `.uia`.
	def assets
		@assets.values.inject(:+)
	end

	# @example
	#   main = app.main
	#   main = app.main_presentation # more-explicit alternative
	# @return [NDD::Application::Presentation] the main presentation rendered by the application.
	def main_presentation
		initial_id = @doc.at('assets')['initial']
		presos = presentations
		presos.find{ |pres| pres.id==initial_id } || presos.first
	end
	alias_method :main, :main_presentation

	# Change which presentation is rendered for the application.
	# @param presentation [NDD::Application::Presentation]
	# @return [NDD::Application::Presentation]
	def main_presentation=(presentation)
		# TODO: set to Presentation or Application::Presentation
		# TODO: create a unique ID if none exists
		@doc.at('assets')['initial'] = presentation.id
	end

	# @return [Hash] a mapping of image paths to arrays of elements/assets that reference that image.
	def image_usage
		# TODO: this returns the same asset multiple times, with no indication of which property is using it; should switch to Properties.
		Hash[
			(presentations + statemachines)
				.map(&:image_usage)
				.inject{ |h1,h2| h1.merge(h2){ |path,els1,els2| [*els1,*els2] } }
				.sort_by do |path,assets|
					parts = path.downcase.split '/'
					[ parts.length, parts ]
				end
		].tap{ |h| h.extend(NDD::PresentableHash) }
	end

	# @return [Array<String>] array of all image paths **used** by the application (not just in subfolders).
	def image_paths
		image_usage.keys
	end

	# @return [Array<NDD::Application::Presentation>] all presentations referenced by the application.
	def presentations
		@assets['presentation'] ||= []
	end

	# @return [Array<NDD::Application::Behavior>] all behaviors referenced by the application.
	def behaviors
		@assets['behavior'] ||= []
	end

	# @return [Array<NDD::Application::StateMachine>] all state machines referenced by the application.
	def statemachines
		@assets['statemachine'] ||= []
	end

	# @return [Array<NDD::Application::RenderPlugin>] all render plug-ins referenced by the application.
	def renderplugins
		@assets['renderplugin'] ||= []
	end

	# Save changes to this application and every asset to disk.
	def save_all!
		save!
		presentations.each(&:save!)
		# TODO: enumerate other assets and save them
	end

	# Find an element or asset in a presentation by scripting path.
	# @example
	#     # Four ways to find the same layer
	#     layer1 = app.at "main:Scene.Layer"
	#     layer2 = app/"main:Scene.Layer"
	#     layer3 = app.main.at "Scene.Layer"
	#     layer4 = app.main/"Scene.Layer"
	#
	#     assert layer1==layer2 && layer2==layer3 && layer3==layer4
	#
	# @return [MetaData::AssetBase] The found asset, or `nil` if it cannot be found.
	#
	# @see Presentation#at
	# @see MetaData::AssetBase#at
	def at(path)
		parts = path.split(':')
		preso = parts.length==2 ? self["##{parts.first}"] : main_presentation
		raise "Cannot find presentation for #{id}" unless preso
		preso.at(parts.last)
	end
	alias_method :/, :at
end

class << NDD
	# Create a new {NDD::Application}. Shortcut for `NDD::Application.new(...)`
	# @param metadata [NDD::MetaData] the MetaData to use for this application.
	# @param uia_path [String] a path to the .uia to load.
	# @return [NDD::Application]
	def Application(metadata,uia_path=nil)
		NDD::Application.new( metadata, uia_path )
	end
end

__END__
<?xml version="1.0" encoding="UTF-8" ?>
<application xmlns="http://nvidia.com/uicomposer"><assets/></application>

