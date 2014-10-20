module UIC; end
class UIC::GUI::AppAttributesModel < Qt::AbstractItemModel
	INVALIDINDEX = Qt::ModelIndex.new
	NODATA       = Qt::Variant.new
	def initialize(qtparent,el)
		super(qtparent)
		@indexes = {} # indexed by [row,col]
		@root    = Qt::ModelIndex.new
		@el      = el
		el.properties.values.sort_by{ |p| p.formal.downcase }.each.with_index do |prop,i|
			@indexes[[i,0]] = createIndex( i, 0, Qt::Variant.new(prop.formal) )
			@indexes[[i,1]] = createIndex( i, 1, Qt::Variant.new(el[prop.name,0].to_s) )
		end
	end

	def columnCount( *any )
		2
	end

	def index( row, col, parent=INVALIDINDEX )
		@indexes[[row,col]]
	end

	def headerData(section, orientation, role=Qt::DisplayRole)
		if orientation==Qt::Horizontal && role==Qt::DisplayRole
			case section
				when 0; Qt::Variant.new(tr("Attribute"))
				when 1; Qt::Variant.new(tr("Value"))
				else  ; NODATA
			end
		else
			NODATA
		end
	end

	def parent(child)
		child.valid? ? @root : @INVALIDINDEX
	end

	def rowCount( parent=INVALIDINDEX )
		@rowcount ||= @el.properties.length
	end

	def data(index, role)
		if index.valid? && role == Qt::DisplayRole
			index.internal_pointer
		else
			NODATA
		end
	end
end
