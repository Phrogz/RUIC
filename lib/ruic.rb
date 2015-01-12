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
require_relative 'ruic/effect'
require_relative 'ruic/renderplugin'
require_relative 'ruic/statemachine'
require_relative 'ruic/presentation'
require_relative 'ruic/ripl'
require_relative 'ruic/nicebytes'

# The `RUIC` class provides the interface for running scripts using the special DSL,
# and for running the interactive REPL.
# See the {file:README.md README} file for description of the DSL.
class RUIC
	DEFAULTMETADATA = 'C:/Program Files (x86)/NVIDIA Corporation/UI Composer 8.0/res/DataModelMetadata/en-us/MetaData.xml'

	# Execute a script and/or launch the interactive REPL.
	#
	# If you both run a `:script` and then enter the `:repl` all local variables created
	# by the script will be available in the REPL.
	#
	#     # Just run a script
	#     RUIC.run script:'my.ruic'
	#
	#     # Load an application and then enter the REPL
	#     RUIC.run uia:'my.uia', repl:true
	#
	#     # Run a script and then drop into the REPL
	#     RUIC.run script:'my.ruic', repl:true
	#
	# The working directory for scripts is set to the directory of the script.
	#
	# The working directory for the repl is set to the directory of the first
	# loaded application (if any);
	# failing that, the directory of the script (if any);
	# failing that, the current directory.
	#
	# @option opts [String] :script A path to a `.ruic` script to run _(optional)_.
	# @option opts [String] :uia An `.uia` file to load (before running the script and/or REPL) _(optional)_.
	# @option opts [Boolean] :repl Pass `true` to enter the command-line REPL after executing the script (if any).
	# @return [nil]
	def self.run(opts={})
		opts = opts
		ruic = nil
		if opts[:script]
			script = File.read(opts[:script],encoding:'utf-8')
			Dir.chdir(File.dirname(opts[:script])) do
				ruic = self.new
				ruic.metadata opts[:metadata] if opts[:metadata]
				ruic.uia      opts[:uia]      if opts[:uia]
				ruic.env.eval(script,opts[:script])
			end
		end

		if opts[:repl]
			location = (ruic && ruic.app && ruic.app.respond_to?(:file) && ruic.app.file) || opts[:uia] || opts[:script] || '.'
			Dir.chdir( File.dirname(location) ) do
				ruic ||= self.new.tap do |r|
					r.metadata opts[:metadata] if opts[:metadata]
					r.uia      opts[:uia]      if opts[:uia]
				end
				require 'ripl/irb'
				require 'ripl/multi_line'
				require 'ripl/multi_line/live_error.rb'
				Ripl::MultiLine.engine = Ripl::MultiLine::LiveError
				Ripl::Shell.include Ripl::MultiLine.engine
				Ripl::Shell.include Ripl::AfterResult
				Ripl::Shell.include Ripl::FormatResult
				Ripl.config.merge! prompt:"", result_prompt:'#=> ', multi_line_prompt:'  ', irb_verbose:false, after_result:"\n", result_line_limit:200, prefix_result_lines:true, skip_nil_results:true
				ARGV.clear # So that RIPL doesn't try to interpret the options
				puts "(RUIC v#{RUIC::VERSION} interactive session; 'quit' or ctrl-d to end)"
				ruic.instance_eval{ puts @apps.map{ |n,app| "(#{n} is #{app.inspect})" } }
				puts "" # blank line before first input
				Ripl.start binding:ruic.env
			end
		end
	end

	# Creates a new environment for executing a RUIC script.
	# @param metadata [String] Path to the `MetaData.xml` file to use.
	def initialize( metadata=DEFAULTMETADATA )
		@metadata = metadata
		@apps = {}
	end

	# Set the metadata to use; generally called from the RUIC DSL.
	# @param path [String] Path to the `MetaData.xml` file, either absolute or relative to the working directory.
	def metadata(path)
		@metadata = path
	end

	# Load an application, making it available as `app`, `app2`, etc.
	# @param path [String] Path to the `*.uia` application file.
	# @return [UIC::Application] The new application loaded.
	def uia(path)
		meta = UIC.MetaData @metadata
		name = @apps.empty? ? :app : :"app#{@apps.length+1}"
		@apps[name] = UIC.Application(meta,path)
	end

	# @return [Binding] the shared binding used for evaluating the script and REPL
	def env
		@env ||= binding
	end

	# @private used as a one-off
	module SelfInspecting; def inspect; to_s; end; end

	# Used to resolve bare `app` and `app2` calls to a loaded {UIC::Application Application}.
	# @return [UIC::Application] the new application loaded.
	def method_missing(name,*a)
		@apps[name] || (name=~/^app\d*/ ? "(no #{name} loaded)".extend(SelfInspecting) : super)
	end

	# Simple assertion mechanism to be used within scripts.
	#
	# @example 1) simple call syntax
	#     # Provides a generic failure message
	#     assert a==b
	#     #=> assertion failed (my.ruic line 17)
	#
	#     # Provides a custom failure message
	#     assert a==b, "a should equal b"
	#     #=> a should equal b : assertion failed (my.ruic line 17)
	#
	# @example 2) block with string syntax
	#     # The code in the string to eval is also the failure message
	#     assert{ "a==b" }
	#     #=> a==b : assertion failed (my.ruic line 17)
	#
	# @param condition [Boolean] the value to evaluate.
	# @param msg [String] the nice error message to display.
	# @yieldreturn [String] the code to evaluate as a condition.
	def assert(condition=:CONDITIONNOTSUPPLIED,msg=nil,&block)
		if block && condition==:CONDITIONNOTSUPPLIED
			msg = yield
			condition = msg.is_a?(String) ? eval(msg,block.binding) : msg
		end
		condition || begin
			file, line, _ = caller.first.split(':')
			puts "#{"#{msg} : " unless msg.nil?}assertion failed (#{file} line #{line})"
			exit 1
		end
	end

	# Nicer name for `puts` to be used in the DSL, printing the
	# 'nice' string equivalent for all supplied arguments.
	def show(*a)
		a=a.first if a.length==1 && a.first.is_a?(Array)
		opts = { result_prompt:'# ', result_line_limit:200, prefix_result_lines:true, to_s:true }
		a.each{ |x| puts Ripl::FormatResult.format_result(x,opts) }
		nil # so that Ripl won't show the result
	end

	def inspect
		"<RUIC #{@apps.empty? ? "(no app loaded)" : Hash[ @apps.map{ |id,app| [id,File.basename(app.file)] } ]}>"
	end
end

# Run a series of commands inside the RUIC DSL.
#
# @example
#   require 'ruic'
#   RUIC do
#     uia 'test/MyProject/MyProject.uia'
#     show app
#     #=>UIC::Application 'MyProject.uia'>
#   end
#
# If no block is supplied, this is the same as {RUIC.run RUIC.run(opts)}.
# @option opts [String] :uia Optionally load an application before running the script.
def RUIC(opts={},&block)
	if block
		Dir.chdir(File.dirname($0)) do
			RUIC.new.tap do |r|
				r.metadata opts[:metadata] if opts[:metadata]
				r.uia      opts[:uia]      if opts[:uia]
			end.instance_eval(&block)
		end
	else
		RUIC.run(opts)
	end
end