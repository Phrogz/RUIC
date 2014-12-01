module Ripl; end

# Allows [Ripl](https://github.com/cldwalker/ripl) to execute code or print a message after every result.
#
# @example 1) Printing a blank line after each result
#  require_relative 'ripl-after-result'
#  Ripl::Shell.include Ripl::AfterResult
#  Ripl.config.merge! after_result:"\n"
#
# @example 2) Executing arbitrary code with the result
#  results = []
#  require_relative 'ripl-after-result'
#  Ripl::Shell.include Ripl::AfterResult
#  Ripl.config.merge! after_result:proc{ |result| results << result }
module Ripl::AfterResult
	# @private no need to document the method
	def print_result(result)
		super unless result.nil? && config[:skip_nil_results]
		if after=config[:after_result]
			if after.respond_to?(:call)
				after.call(result)
			else
				puts after
			end
		end
	end
end

# Allows [Ripl](https://github.com/cldwalker/ripl) to wrap lines of output
# and/or prefix each line of the result with the `result_prompt`.
module Ripl::FormatResult
	# @private no need to document the method
	def format_result(result,conf={})
		conf=config if respond_to? :config
		result = conf[:to_s] ? result.to_s : result.inspect
		result = result.dup if result.frozen?
		if limit=conf[:result_line_limit]
			match = /^.{#{limit}}.+/o
			:go while result.sub!(match){ |line| line.sub /^(?:(.{,#{limit}})[ \t]+|(.{#{limit}}))/o, "\\1\\2\n" }
		end

		result.gsub( conf[:prefix_result_lines] ? /^/ : /\A/, conf[:result_prompt] )
	end
	module_function :format_result
end
