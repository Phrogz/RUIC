#encoding: utf-8
require_relative 'window_qrc'
require_relative '../lib/ruic'

class UIC::GUI < Qt::MainWindow
	slots	*%w[ open() save() saveAll() ]

	def initialize(parent=nil, &block)
		super(parent)
		@ui = Ui_MainWin.new
		@ui.setupUi(self)
		connect_menus!
		# instance_exec(&block) if block
	end

	def connect_menus!
		connect( @ui.menuFileOpen, SIGNAL('triggered()'), self, SLOT('open()')  )
		connect( @ui.actionQuit,   SIGNAL('triggered()'), self, SLOT('close()') )
	end

	def open
		recent = $prefs.value('RecentProjects').value
		recent = recent ? recent.last : Dir.pwd
		# TODO: ensure that the file/directory exists
    path = Qt::FileDialog.get_open_file_name(
    	self, tr("Open an Application"), recent, tr("UIC Application (*.uia)")
    )
    unless path.nil?
    	add_recent(path)
	    load_file path
	   end
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
		@elements = AppElementsModel.new(self,@uia)
		@ui.elements.model = @elements
		p @ui.elements.selectionModel
	end

	def add_recent(path)
		recent = $prefs.value("RecentProjects").value || []
		recent.delete(path)
		recent << path
		$prefs.set_value("RecentProjects",Qt::Variant.new(recent))
	end
end

require_relative 'window_ui'
require_relative 'appelementsmodel'
