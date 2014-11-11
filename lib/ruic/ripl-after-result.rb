module Ripl::AfterResult
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