class RUIC; end
module UIC; end

require 'nokogiri'
require 'ruic/version'
require 'ruic/asset_classes'
require 'ruic/interfaces'
require 'ruic/application'
require 'ruic/behaviors'
require 'ruic/statemachine'
require 'ruic/presentation'

class RUIC
	DEFAULTMETADATA = 'C:/Program Files (x86)/NVIDIA Corporation/UI Composer 8.0/res/DataModelMetadata/en-us/MetaData.xml'
	attr_reader :app
	def self.run(ruic_path)
		script = File.read(ruic_path,encoding:'utf-8')
		Dir.chdir(File.dirname(ruic_path)) do
			self.new.instance_eval(script,ruic_path)
		end
	end
	def initialize
		@metadata = DEFAULTMETADATA
	end
	def metadata(path)
		@metadata = path
	end
	def uia(path)
		meta = UIC.Meta @metadata
		@app = UIC.App(meta,path)
	end
	def assert(condition)
		raise "Failed" unless condition
	end
end

def RUIC(file_path=nil,&block)
	if block
		Dir.chdir(File.dirname($0)) do
			RUIC.new.instance_eval(&block)
		end
	else
		RUIC.run(file_path)
	end
end