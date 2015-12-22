#encoding: utf-8
require_relative 'window_qrc'
require_relative '../lib/ruic'

class NDD::GUI < Qt::MainWindow
	NVGREEN = Qt::Color.fromRgb(115,185,0)
	slots	:open, :saveAll

	def initialize(parent=nil, &block)
		super(parent)
		@ui = Ui_MainWin.new
		setup_interface!
		connect_menus!
		# instance_exec(&block) if block
	end

	def setup_interface!
		@ui.setupUi(self)
		@ui.inspector.vertical_header.resize_mode = Qt::HeaderView::Fixed
		@ui.inspector.vertical_header.default_section_size = 18
	end

	def connect_menus!
		connect @ui.actionOpen,    SIGNAL(:triggered), SLOT(:open)
		connect @ui.actionSaveAll, SIGNAL(:triggered), SLOT(:saveAll)
		connect @ui.actionQuit,    SIGNAL(:triggered), SLOT(:close)
	end

	def open
		recent = $prefs.value('RecentProjects').value
		recent = recent ? recent.last : Dir.pwd
		# TODO: ensure that the file/directory exists
    path = Qt::FileDialog.get_open_file_name(
    	self, tr("Open an Application"), recent, "NDD Application (*.uia)"
    )
    unless path.nil?
    	add_recent(path)
	    load_file path
	  end
	end

	def saveAll
		warn "SAVE ALL NOT IMPLEMENTED"
	end

	def load_file( path )
		@ruic = RUIC.new
		@ruic.metadata( 'MetaData.xml' ) unless File.exist?(RUIC::DEFAULTMETADATA)
		@uia = @ruic.uia(path)
		dir = File.basename(File.dirname(path))
		self.window_title = File.join(dir,File.basename(path))
		reload_interface
	end

	def reload_interface
		reload_hierarchy
	end

	def reload_hierarchy
		@ui.elements.model = AppElementsModel.new(self,@uia)
    changed = SIGNAL('currentChanged(const QModelIndex &, const QModelIndex &)')
		@ui.elements.selectionModel.connect( changed, &method(:element_selected) )
	end

	def element_selected(current,previous)
		@ui.slideList.remove_item(1) until @ui.slideList.count==1
		if current.valid?
			el = current.internal_pointer.el
			master, *nonmaster = el.slides
			nonmaster.each{ |s| @ui.slideList.addItem "#{s.index}: #{s.name}" }
			@ui.inspector.model = AppAttributesModel.new(self,el)
			@ui.inspector.horizontal_header.stretch_last_section = true
		end
	end

	def add_recent(path)
		recent = $prefs.value("RecentProjects").value || []
		recent.delete(path)
		recent << path
		begin
			$prefs.set_value("RecentProjects",Qt::Variant.new(recent))
		rescue Exception=>e
			p e
		end
	end
end

require_relative 'window_ui'
require_relative 'appelementsmodel'
require_relative 'appattributesmodel'
