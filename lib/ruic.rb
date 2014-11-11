#encoding:utf-8
class RUIC; end
module UIC; end

require 'nokogiri'
require_relative 'ruic/version'
require_relative 'ruic/attributes'
require_relative 'ruic/assets'
require_relative 'ruic/interfaces'
require_relative 'ruic/application'
require_relative 'ruic/behaviors'
require_relative 'ruic/statemachine'
require_relative 'ruic/presentation'

class RUIC
	DEFAULTMETADATA = 'C:/Program Files (x86)/NVIDIA Corporation/UI Composer 8.0/res/DataModelMetadata/en-us/MetaData.xml'

	def self.run(opts={})
		opts = opts
		ruic = nil
		if opts[:script]
			script = File.read(opts[:script],encoding:'utf-8')
			Dir.chdir(File.dirname(opts[:script])) do
				ruic = self.new
				ruic.uia(opts[:uia]) if opts[:uia]
				ruic.env.eval(script,opts[:script])
			end
		end

		if opts[:repl]
			location = (ruic && ruic.app && ruic.app.respond_to?(:file) && ruic.app.file) || opts[:uia] || opts[:script] || '.'
			Dir.chdir( File.dirname(location) ) do
				ruic ||= self.new.tap{ |r| r.uia(opts[:uia]) if opts[:uia] }
				require 'ripl/irb'
				require 'ripl/multi_line'
				require 'ripl/multi_line/live_error.rb'
				require_relative 'ruic/ripl-after-result'
				Ripl::MultiLine.engine = Ripl::MultiLine::LiveError
				Ripl::Shell.include Ripl::MultiLine.engine
				Ripl::Shell.include Ripl::AfterResult
				Ripl.config.merge! prompt:"", result_prompt:'#=> ', multi_line_prompt:'  ', irb_verbose:false, after_result:"\n"
				ARGV.clear # So that RIPL doesn't try to interpret the options
				puts "(RUIC v#{RUIC::VERSION} interactive session; 'quit' or ctrl-d to end)"
				ruic.instance_eval{ puts @apps.map{ |n,app| "(#{n} is #{app.inspect})" } }
				puts "" # blank line before first input
				Ripl.start binding:ruic.env
			end
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

	def env
		@env ||= binding
	end

	module SelfInspecting
		def inspect
			to_s
		end
	end

	def method_missing(name,*a)
		@apps[name] || (name=~/^app\d*/ ? "(no #{name} loaded)".extend(SelfInspecting) : super)
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

	def inspect
		"<RUIC #{@apps.empty? ? "(no app loaded)" : Hash[ @apps.map{ |id,app| [id,File.basename(app.file)] } ]}>"
	end
end

def RUIC(opts={},&block)
	if block
		Dir.chdir(File.dirname($0)) do
			RUIC.new.tap{ |r| r.uia(opts[:uia]) if opts[:uia] }.instance_eval(&block)
		end
	else
		RUIC.run(opts)
	end
end