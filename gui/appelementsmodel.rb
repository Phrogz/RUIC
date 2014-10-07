class AppElementsModel < Qt::AbstractItemModel
	INVALID = Qt::ModelIndex.new
	def initialize(parent,app)
		super(parent)
		@app = app
		@rootEl = AppElement.new(app)
	end

	def columnCount( *any )
		2
	end

	def index( row, col, parent=INVALID )
		parentEl = parent.valid? ? parent.internalPointer : @rootEl
		if childEl=parentEl.child( row )
			createIndex(row,column,childEl)
		else
			INVALID
		end
	end

	def parent(child)
		if child.valid?
			parentEl = child.internalPointer.parent
			if parentEl.nil? || parentEl==@rootEl
				INVALID
			else
				createIndex(parentEl.row, 0, parentEl)
			end
		else
			INVALID
		end
	end

	def rowCount( parent=INVALID )
		parentEl = parent.valid? ? parent.internalPointer : @rootEl
		parentEl.children.length
	end

	def data(index, role)
		return Qt::Variant.new unless index.valid? && role==Qt::DisplayRole
	
		element = index.internalPointer
		case index.column
		when 0
			return Qt::Variant.new(node.nodeName)
		when 1
			for i in 0...attributeMap.length
				attribute = attributeMap.item(i)
				attributes << attribute.nodeName() + '="' + 
								attribute.nodeValue() + '"'
			end
			return Qt::Variant.new(attributes.join(" "))
		when 2
			if node.nodeValue.nil?
				return Qt::Variant.new
			else
				return Qt::Variant.new(node.nodeValue().split("\n").join(" "))
			end
		else
			return Qt::Variant.new
		end
	end

end

class AppElement
	def initialize(app)
	end
end