require_relative 'window_ui'
require 'ruic'
class RUICWindow < Qt::MainWindow	
	slots	*%w[ open() save() saveAll() ]

	def initialize(parent = nil)
		super

		@ui = Ui_MainWin.new
		@ui.setupUi(self)
		connect_menus!
	end

	def connect_menus!
		connect( @ui.menuFileOpen, SIGNAL('triggered()'), self, SLOT('open()') )
	end

	def populate_interface!
		hier = @ui.appHierarchy
		hier.column_count = 2
		hier.header_labels = ['element', 'kind']
		
		10.times.map do |i|
			Qt::TreeWidgetItem.new(hier){ set_text 0, "My Label ##{i}" }
		end
	end

	def open
    path = Qt::FileDialog.get_open_file_name(
    	self, tr("Open an Application"), Dir.pwd, tr("UIC Application (*.uia)")
    )
    load_file path unless path.nil?
	end

	def load_file( path )
		@ruic = RUIC.new
		@ruic.metadata( 'MetaData.xml' ) unless File.exist?(RUIC::DEFAULTMETADATA)
		@uia = @ruic.uia(path)
		reload_data
	end

	def reload_interface

	end

	def reload_hierarchy
	end
end