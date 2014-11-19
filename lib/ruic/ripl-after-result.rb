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
		super
		if after=config[:after_result]
			if after.respond_to?(:call)
				after.call(result)
			else
				puts after
			end
		end
	end
end