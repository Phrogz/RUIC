require 'nokogiri'

class RUIC
	VERSION = '0.1'
	attr_reader :app
	def self.run(ruic_path)
		script = File.read(ruic_path,encoding:'utf-8')
		Dir.chdir(File.dirname(ruic_path)) do
			self.new.instance_eval(script,ruic_path)
		end
	end
	def initialize
		@metadata = 'C:/Program Files (x86)/NVIDIA Corporation/UI Composer 8.0/res/DataModelMetadata/en-us/MetaData.xml'
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

module UIC
	VERSION = '0.1'
end

def RUIC(&block)
	Dir.chdir(File.dirname($0)) do
		RUIC.new.instance_eval(&block)
	end
end

require_relative 'ruic/asset_classes'
require_relative 'ruic/interfaces'
require_relative 'ruic/application'
require_relative 'ruic/behaviors'
require_relative 'ruic/statemachine'
require_relative 'ruic/presentation'
