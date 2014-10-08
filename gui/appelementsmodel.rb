module UIC; end
class UIC::GUI::AppElementsModel < Qt::AbstractItemModel
	INVALIDINDEX = Qt::ModelIndex.new
	NODATA       = Qt::Variant.new
	def initialize(qtparent,app)
		super(qtparent)
		@root = El.new(app,0)
	end

	def columnCount( *any )
		2
	end

	def index( row, col, parent=INVALIDINDEX )
		parentEl = parent.valid? ? parent.internalPointer : @root
		if childEl=parentEl.child(row)
			createIndex(row,col,childEl)
		else
			INVALIDINDEX
		end
	end

	def headerData(section, orientation, role=Qt::DisplayRole)
		if orientation==Qt::Horizontal && role==Qt::DisplayRole
			case section
				when 0; Qt::Variant.new(tr("Name"))
				when 1; Qt::Variant.new(tr("Type"))
				else  ; NODATA
			end
		else
			NODATA
		end
	end

	def parent(child)
		if child.valid?
			parentEl = child.internalPointer.parent
			if parentEl.nil? || parentEl==@root
				INVALIDINDEX
			else
				createIndex(parentEl.row, 0, parentEl)
			end
		else
			INVALIDINDEX
		end
	end

	def rowCount( parent=INVALIDINDEX )
		parentEl = parent.valid? ? parent.internalPointer : @root
		parentEl.child_count
	end

	def data(index, role)
		if index.valid?
			case role
				when Qt::DisplayRole
					element = index.internalPointer
					case index.column
						when 0; Qt::Variant.new(element.displayName)
						when 1; Qt::Variant.new(element.displayType)
						else  ; NODATA
					end
				when Qt::DecorationRole
					if index.column==0
						Qt::Pixmap.new(':/resources/images/Objects-Scene-Normal.png')
					else
						NODATA
					end
				else
					NODATA
			end
		else
			NODATA
		end
	end
end

class UIC::GUI::AppElementsModel::El
	@by_el = {}
	class << self
		def [](el,row)
			@by_el[el] ||= self.new(el,row)
		end
	end

	attr_reader :row
	def initialize(el,row)
		@el    = el
		@isapp = el.is_a?( UIC::Application )
		@row   = row
	end
	def child_count
		(@isapp ? @el.presentations : @el.children).length
	end

	def child(offset)
		kids = @isapp ? @el.presentations : @el.children
		self.class[ @isapp ? kids[offset].scene : kids[offset], offset ] if kids[offset]
	end

	def parent
		unless @el.is_a?( UIC::Application )
			self.class[@el.parent || @el.presentation.app, @row]
		end
	end
	def displayName
		@el.type=='Scene' ? @el.path : @el.name
	end
	def displayType
		@el.type
	end
end