module UIC::FileBacked
	attr_accessor :doc, :file
	def path_to( relative )
		File.expand_path( File.join(File.dirname(file),relative) )
	end
end

module UIC::ApplicationAsset
	attr_accessor :asset
end
