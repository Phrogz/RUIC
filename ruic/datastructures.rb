module UIC; end

UIC::V3 = Struct.new(:x,:y,:z) do
	def inspect
		to_s
	end
	def to_s
		"<%g,%g,%g>" % [x,y,z]
	end
end

def UIC.V3(x=0,y=0,z=0)
	UIC::V3.new(x,y,z)
end
