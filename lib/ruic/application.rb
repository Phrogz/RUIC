class UIC::Application
	include UIC::FileBacked

	attr_reader :metadata
	def initialize(metadata,uia_path)
		@metadata = metadata
		self.file = uia_path
		load_from_file if file_found?
	end

	def load_from_file
		self.doc  = Nokogiri.XML(File.read(file,encoding:'utf-8'))
		@assets   = @doc.search('assets *').map do |el|
			case el.name
				when 'behavior'     then UIC::Application::Behavior
				when 'statemachine' then UIC::Application::StateMachine
				when 'presentation' then UIC::Application::Presentation
				when 'renderplugin' then UIC::Application::RenderPlugin
			end.new(self,el)
		end.group_by{ |asset| asset.el.name }
	end

	def errors?
		!errors.empty?
	end

	def errors
		file_found? ? assets.flat_map(&:errors) : ["File not found: '#{file}'"]
	end

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

	def unused_files
		referenced_files - directory_files
	end

	def referenced_files
		# TODO: state machines can reference external scripts
		# TODO: behaviors can reference external scripts
		assets.map{ |asset| path_to(asset.src) }
		+ presentations.flat_map{ |pres| pres.presentation.referenced_files }
	end

	def assets
		@assets.values.inject(:+)
	end

	def main_presentation
		initial_id = @doc.at('assets')['initial']
		presos = presentations
		presos.find{ |pres| pres.id==initial_id } || presos.first
	end

	def main_presentation=(presentation)
		# TODO: set to Presentation or PresentationAsset
		# TODO: create a unique ID if none exists
		@doc.at('assets')['initial'] = presentation.id
	end

	def image_usage
		Hash[
			(presentations + statemachines)
				.map(&:image_usage)
				.inject{ |h1,h2| h1.merge(h2){ |path,els1,els2| [*els1,*els2] } }
				.sort_by do |path,assets|
					parts = path.downcase.split '/'
					[ parts.length, parts ]
				end
		].tap{ |h| h.extend(UIC::PresentableHash) }
	end

	def image_paths
		image_usage.keys
	end

	def presentations
		@assets['presentation'] ||= []
	end

	def behaviors
		@assets['behavior'] ||= []
	end

	def statemachines
		@assets['statemachine'] ||= []
	end

	def renderplugins
		@assets['renderplugin'] ||= []
	end

	def save_all
		save!
		presentations.each(&:save!)
	end

	def at(path)
		parts = path.split(':')
		preso = parts.length==2 ? self["##{parts.first}"] : main_presentation
		raise "Cannot find presentation for #{id}" unless preso
		preso.at(parts.last)
	end
	alias_method :/, :at

	def xml
		@doc.to_xml
	end
end

class << UIC
	def Application(metadata,uia_path)
		UIC::Application.new( metadata, uia_path )
	end
	alias_method :App, :Application
end

__END__
<?xml version="1.0" encoding="UTF-8" ?>
<application xmlns="http://nvidia.com/uicomposer"><assets/></application>

