#encoding:utf-8
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
	def self.run(ruic_path)
		script = File.read(ruic_path,encoding:'utf-8')
		Dir.chdir(File.dirname(ruic_path)) do
			self.new.instance_eval(script,ruic_path)
		end
	end
	def initialize( metadata=DEFAULTMETADATA )
		@metadata = metadata
		@apps = {}
	end
	def metadata(path)
		@metadata = path
	end
	def uia(path)
		meta = UIC.Meta @metadata
		name = @apps.empty? ? :app : :"app#{@apps.length+1}"
		@apps[name] = UIC.App(meta,path)
	end
	def method_missing(name,*a)
		@apps[name] || super
	end
	def assert(condition=:CONDITIONNOTSUPPLIED,msg=nil,&block)
		if block && condition==:CONDITIONNOTSUPPLIED || condition.is_a?(String)
			msg = condition.is_a?(String) ? condition : yield
			condition = msg.is_a?(String) ? eval(msg,block.binding) : msg
		end
		unless condition
			file, line, _ = caller.first.split(':')
			puts "#{msg && "#{msg} : "}assertion failed (#{file} line #{line})"
			exit 1
		end
	end
	def show(*a); puts *a.map(&:to_s); end
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