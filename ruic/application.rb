class UIC::Application
	include UIC::FileBacked

	def initialize(metadata,xml=DATA.read)
		@metadata = metadata
		@doc      = Nokogiri.XML(xml)
		@assets   = @doc.search('assets *').map{ |element| UIC::Application::Asset.from_element(element,self) }
	end

	def [](asset_id)
		@assets.find{ |asset| asset.id==asset_id }
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
		@assets
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

	def presentations
		assets.select{ |asset| asset.is_a?(UIC::Application::PresentationAsset) }
	end

	# Mapping asset ID to an asset
	def asset
		Hash[ assets.map{ |p| [p.id,p] } ]
	end

	def behaviors
		assets.select{ |asset| asset.is_a?(UIC::Application::BehaviorAsset) }
	end

	def statemachines
		assets.select{ |asset| asset.is_a?(UIC::Application::StateMachineAsset) }
	end

	def plugins
		assets.select{ |asset| asset.is_a?(UIC::Application::PluginAsset) }
	end

	def save_all
		save!
		presentations.map(&:presentation).each(&:save!)
	end

	def at(path)
		parts = path.split(':')
		preso = parts.length==2 ? asset[parts.first] : main_presentation
		raise "Cannot find presentation for #{id}" unless preso
		preso.presentation.at(parts.last)
	end
	alias_method :/, :at

	def xml
		@doc.to_xml
	end
end

class << UIC
	def Application(metadata,uia_path)
		UIC::Application.new( metadata, File.read(uia_path,encoding:'utf-8') ).tap{ |app| app.file = uia_path }
	end
	alias_method :App, :Application
end

__END__
<?xml version="1.0" encoding="UTF-8" ?>
<application xmlns="http://nvidia.com/uicomposer"><assets/></application>

