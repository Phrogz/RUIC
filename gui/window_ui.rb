=begin
** Form generated from reading ui file 'window.ui'
**
** Created: Tue Oct 7 14:55:11 2014
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_MainWin
    attr_reader :menuFileOpen
    attr_reader :menuEditUndo
    attr_reader :menuEditRedo
    attr_reader :menuEditCopy
    attr_reader :actionSave_All
    attr_reader :actionQuit
    attr_reader :actionDelete_Unused_Assets
    attr_reader :centralwidget
    attr_reader :verticalLayout_4
    attr_reader :mainSplitter
    attr_reader :topRowSplitter
    attr_reader :layoutWidget
    attr_reader :elementsBox
    attr_reader :elementsHeader
    attr_reader :elementsSplitter
    attr_reader :elements
    attr_reader :layoutWidget1
    attr_reader :verticalLayout
    attr_reader :slideTabs
    attr_reader :tab_3
    attr_reader :horizontalLayout
    attr_reader :tab_4
    attr_reader :tab_5
    attr_reader :inspector
    attr_reader :layoutWidget2
    attr_reader :valuesBox
    attr_reader :valuesHeaderBox
    attr_reader :valuesHeader
    attr_reader :hspace
    attr_reader :comboBox_2
    attr_reader :comboBox_3
    attr_reader :comboBox_4
    attr_reader :tableView
    attr_reader :layoutWidget3
    attr_reader :assetsBox
    attr_reader :assetsHeaderBox
    attr_reader :assetsHeader
    attr_reader :hspace_2
    attr_reader :comboBox
    attr_reader :assetView
    attr_reader :layoutWidget4
    attr_reader :consoleBox
    attr_reader :consoleLabel
    attr_reader :console
    attr_reader :menubar
    attr_reader :menuFile
    attr_reader :menuEdit
    attr_reader :menuWindow
    attr_reader :statusbar

    def setupUi(mainWin)
    if mainWin.objectName.nil?
        mainWin.objectName = "mainWin"
    end
    mainWin.resize(1150, 656)
    mainWin.styleSheet = "QPlainTextEdit, QTableView, QTreeView { border:1px solid #898c95 }"
    mainWin.unifiedTitleAndToolBarOnMac = false
    @menuFileOpen = Qt::Action.new(mainWin)
    @menuFileOpen.objectName = "menuFileOpen"
    icon = Qt::Icon.new
    icon.addPixmap(Qt::Pixmap.new(":/resources/images/folder-horizontal-open.png"), Qt::Icon::Normal, Qt::Icon::Off)
    @menuFileOpen.icon = icon
    @menuFileOpen.shortcutContext = Qt::ApplicationShortcut
    @menuEditUndo = Qt::Action.new(mainWin)
    @menuEditUndo.objectName = "menuEditUndo"
    @menuEditUndo.enabled = false
    icon1 = Qt::Icon.new
    icon1.addPixmap(Qt::Pixmap.new(), Qt::Icon::Normal, Qt::Icon::Off)
    @menuEditUndo.icon = icon1
    @menuEditRedo = Qt::Action.new(mainWin)
    @menuEditRedo.objectName = "menuEditRedo"
    @menuEditRedo.enabled = false
    @menuEditCopy = Qt::Action.new(mainWin)
    @menuEditCopy.objectName = "menuEditCopy"
    @menuEditCopy.enabled = false
    @actionSave_All = Qt::Action.new(mainWin)
    @actionSave_All.objectName = "actionSave_All"
    @actionSave_All.enabled = false
    icon2 = Qt::Icon.new
    icon2.addPixmap(Qt::Pixmap.new(":/resources/images/disks-black.png"), Qt::Icon::Normal, Qt::Icon::Off)
    @actionSave_All.icon = icon2
    @actionQuit = Qt::Action.new(mainWin)
    @actionQuit.objectName = "actionQuit"
    @actionDelete_Unused_Assets = Qt::Action.new(mainWin)
    @actionDelete_Unused_Assets.objectName = "actionDelete_Unused_Assets"
    icon3 = Qt::Icon.new
    icon3.addPixmap(Qt::Pixmap.new(":/resources/images/cross.png"), Qt::Icon::Normal, Qt::Icon::Off)
    @actionDelete_Unused_Assets.icon = icon3
    @centralwidget = Qt::Widget.new(mainWin)
    @centralwidget.objectName = "centralwidget"
    @sizePolicy = Qt::SizePolicy.new(Qt::SizePolicy::Preferred, Qt::SizePolicy::Minimum)
    @sizePolicy.setHorizontalStretch(0)
    @sizePolicy.setVerticalStretch(0)
    @sizePolicy.heightForWidth = @centralwidget.sizePolicy.hasHeightForWidth
    @centralwidget.sizePolicy = @sizePolicy
    @centralwidget.autoFillBackground = true
    @verticalLayout_4 = Qt::VBoxLayout.new(@centralwidget)
    @verticalLayout_4.objectName = "verticalLayout_4"
    @mainSplitter = Qt::Splitter.new(@centralwidget)
    @mainSplitter.objectName = "mainSplitter"
    @mainSplitter.lineWidth = 0
    @mainSplitter.orientation = Qt::Vertical
    @mainSplitter.handleWidth = 9
    @topRowSplitter = Qt::Splitter.new(@mainSplitter)
    @topRowSplitter.objectName = "topRowSplitter"
    @sizePolicy1 = Qt::SizePolicy.new(Qt::SizePolicy::Expanding, Qt::SizePolicy::Preferred)
    @sizePolicy1.setHorizontalStretch(0)
    @sizePolicy1.setVerticalStretch(1)
    @sizePolicy1.heightForWidth = @topRowSplitter.sizePolicy.hasHeightForWidth
    @topRowSplitter.sizePolicy = @sizePolicy1
    @topRowSplitter.orientation = Qt::Horizontal
    @topRowSplitter.handleWidth = 9
    @topRowSplitter.childrenCollapsible = false
    @layoutWidget = Qt::Widget.new(@topRowSplitter)
    @layoutWidget.objectName = "layoutWidget"
    @elementsBox = Qt::VBoxLayout.new(@layoutWidget)
    @elementsBox.spacing = 0
    @elementsBox.objectName = "elementsBox"
    @elementsBox.setContentsMargins(0, 0, 0, 0)
    @elementsHeader = Qt::Label.new(@layoutWidget)
    @elementsHeader.objectName = "elementsHeader"
    @sizePolicy2 = Qt::SizePolicy.new(Qt::SizePolicy::Preferred, Qt::SizePolicy::Fixed)
    @sizePolicy2.setHorizontalStretch(0)
    @sizePolicy2.setVerticalStretch(0)
    @sizePolicy2.heightForWidth = @elementsHeader.sizePolicy.hasHeightForWidth
    @elementsHeader.sizePolicy = @sizePolicy2
    @elementsHeader.minimumSize = Qt::Size.new(61, 16)
    @elementsHeader.maximumSize = Qt::Size.new(16777215, 16)
    @font = Qt::Font.new
    @font.bold = true
    @font.weight = 75
    @elementsHeader.font = @font

    @elementsBox.addWidget(@elementsHeader)

    @elementsSplitter = Qt::Splitter.new(@layoutWidget)
    @elementsSplitter.objectName = "elementsSplitter"
    @sizePolicy3 = Qt::SizePolicy.new(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding)
    @sizePolicy3.setHorizontalStretch(0)
    @sizePolicy3.setVerticalStretch(0)
    @sizePolicy3.heightForWidth = @elementsSplitter.sizePolicy.hasHeightForWidth
    @elementsSplitter.sizePolicy = @sizePolicy3
    @elementsSplitter.minimumSize = Qt::Size.new(361, 0)
    @elementsSplitter.maximumSize = Qt::Size.new(16777215, 16777215)
    @elementsSplitter.orientation = Qt::Horizontal
    @elementsSplitter.handleWidth = 9
    @elementsSplitter.childrenCollapsible = false
    @elements = Qt::TreeView.new(@elementsSplitter)
    @elements.objectName = "elements"
    @elements.minimumSize = Qt::Size.new(0, 60)
    @elements.styleSheet = ""
    @elements.lineWidth = 1
    @elements.horizontalScrollBarPolicy = Qt::ScrollBarAlwaysOff
    @elements.uniformRowHeights = true
    @elements.headerHidden = false
    @elementsSplitter.addWidget(@elements)
    @layoutWidget1 = Qt::Widget.new(@elementsSplitter)
    @layoutWidget1.objectName = "layoutWidget1"
    @verticalLayout = Qt::VBoxLayout.new(@layoutWidget1)
    @verticalLayout.spacing = 0
    @verticalLayout.objectName = "verticalLayout"
    @verticalLayout.setContentsMargins(0, 0, 0, 0)
    @slideTabs = Qt::TabWidget.new(@layoutWidget1)
    @slideTabs.objectName = "slideTabs"
    @sizePolicy4 = Qt::SizePolicy.new(Qt::SizePolicy::Expanding, Qt::SizePolicy::Fixed)
    @sizePolicy4.setHorizontalStretch(0)
    @sizePolicy4.setVerticalStretch(0)
    @sizePolicy4.heightForWidth = @slideTabs.sizePolicy.hasHeightForWidth
    @slideTabs.sizePolicy = @sizePolicy4
    @slideTabs.maximumSize = Qt::Size.new(16777215, 21)
    @slideTabs.iconSize = Qt::Size.new(32, 32)
    @tab_3 = Qt::Widget.new()
    @tab_3.objectName = "tab_3"
    @tab_3.maximumSize = Qt::Size.new(16777215, 0)
    @horizontalLayout = Qt::HBoxLayout.new(@tab_3)
    @horizontalLayout.objectName = "horizontalLayout"
    @slideTabs.addTab(@tab_3, Qt::Application.translate("MainWin", "0: Master", nil, Qt::Application::UnicodeUTF8))
    @tab_4 = Qt::Widget.new()
    @tab_4.objectName = "tab_4"
    @tab_4.maximumSize = Qt::Size.new(16777215, 0)
    @slideTabs.addTab(@tab_4, Qt::Application.translate("MainWin", "1: Slide1", nil, Qt::Application::UnicodeUTF8))
    @tab_5 = Qt::Widget.new()
    @tab_5.objectName = "tab_5"
    @slideTabs.addTab(@tab_5, Qt::Application.translate("MainWin", "2: Slide2", nil, Qt::Application::UnicodeUTF8))

    @verticalLayout.addWidget(@slideTabs)

    @inspector = Qt::TableView.new(@layoutWidget1)
    @inspector.objectName = "inspector"
    @inspector.minimumSize = Qt::Size.new(0, 60)
    @inspector.styleSheet = "#inspector { border-top:none; margin-right:2px /*hack to line up with border on tabs */ }"
    @inspector.horizontalScrollBarPolicy = Qt::ScrollBarAlwaysOff
    @inspector.showGrid = true
    @inspector.wordWrap = false

    @verticalLayout.addWidget(@inspector)

    @elementsSplitter.addWidget(@layoutWidget1)

    @elementsBox.addWidget(@elementsSplitter)

    @topRowSplitter.addWidget(@layoutWidget)
    @layoutWidget2 = Qt::Widget.new(@topRowSplitter)
    @layoutWidget2.objectName = "layoutWidget2"
    @valuesBox = Qt::VBoxLayout.new(@layoutWidget2)
    @valuesBox.spacing = 0
    @valuesBox.objectName = "valuesBox"
    @valuesBox.setContentsMargins(0, 0, 0, 0)
    @valuesHeaderBox = Qt::HBoxLayout.new()
    @valuesHeaderBox.spacing = 2
    @valuesHeaderBox.objectName = "valuesHeaderBox"
    @valuesHeaderBox.setContentsMargins(-1, -1, -1, 1)
    @valuesHeader = Qt::Label.new(@layoutWidget2)
    @valuesHeader.objectName = "valuesHeader"
    @sizePolicy2.heightForWidth = @valuesHeader.sizePolicy.hasHeightForWidth
    @valuesHeader.sizePolicy = @sizePolicy2
    @valuesHeader.minimumSize = Qt::Size.new(45, 0)
    @valuesHeader.maximumSize = Qt::Size.new(16777215, 16)
    @valuesHeader.font = @font

    @valuesHeaderBox.addWidget(@valuesHeader)

    @hspace = Qt::SpacerItem.new(48, 13, Qt::SizePolicy::Expanding, Qt::SizePolicy::Minimum)

    @valuesHeaderBox.addItem(@hspace)

    @comboBox_2 = Qt::ComboBox.new(@layoutWidget2)
    @comboBox_2.objectName = "comboBox_2"
    @comboBox_2.minimumSize = Qt::Size.new(76, 0)
    @comboBox_2.maximumSize = Qt::Size.new(87, 16)
    @comboBox_2.maxVisibleItems = 15

    @valuesHeaderBox.addWidget(@comboBox_2)

    @comboBox_3 = Qt::ComboBox.new(@layoutWidget2)
    @comboBox_3.objectName = "comboBox_3"
    @comboBox_3.minimumSize = Qt::Size.new(69, 0)
    @comboBox_3.maximumSize = Qt::Size.new(69, 16)

    @valuesHeaderBox.addWidget(@comboBox_3)

    @comboBox_4 = Qt::ComboBox.new(@layoutWidget2)
    @comboBox_4.objectName = "comboBox_4"
    @sizePolicy5 = Qt::SizePolicy.new(Qt::SizePolicy::Minimum, Qt::SizePolicy::Fixed)
    @sizePolicy5.setHorizontalStretch(0)
    @sizePolicy5.setVerticalStretch(0)
    @sizePolicy5.heightForWidth = @comboBox_4.sizePolicy.hasHeightForWidth
    @comboBox_4.sizePolicy = @sizePolicy5
    @comboBox_4.minimumSize = Qt::Size.new(80, 0)
    @comboBox_4.maximumSize = Qt::Size.new(16777215, 16)

    @valuesHeaderBox.addWidget(@comboBox_4)


    @valuesBox.addLayout(@valuesHeaderBox)

    @tableView = Qt::TableView.new(@layoutWidget2)
    @tableView.objectName = "tableView"
    @tableView.minimumSize = Qt::Size.new(0, 60)

    @valuesBox.addWidget(@tableView)

    @topRowSplitter.addWidget(@layoutWidget2)
    @layoutWidget3 = Qt::Widget.new(@topRowSplitter)
    @layoutWidget3.objectName = "layoutWidget3"
    @assetsBox = Qt::VBoxLayout.new(@layoutWidget3)
    @assetsBox.spacing = 0
    @assetsBox.objectName = "assetsBox"
    @assetsBox.setContentsMargins(0, 0, 0, 0)
    @assetsHeaderBox = Qt::HBoxLayout.new()
    @assetsHeaderBox.objectName = "assetsHeaderBox"
    @assetsHeaderBox.setContentsMargins(-1, -1, -1, 1)
    @assetsHeader = Qt::Label.new(@layoutWidget3)
    @assetsHeader.objectName = "assetsHeader"
    @sizePolicy2.heightForWidth = @assetsHeader.sizePolicy.hasHeightForWidth
    @assetsHeader.sizePolicy = @sizePolicy2
    @assetsHeader.minimumSize = Qt::Size.new(46, 16)
    @assetsHeader.maximumSize = Qt::Size.new(16777215, 16)
    @assetsHeader.font = @font

    @assetsHeaderBox.addWidget(@assetsHeader)

    @hspace_2 = Qt::SpacerItem.new(40, 16, Qt::SizePolicy::Expanding, Qt::SizePolicy::Minimum)

    @assetsHeaderBox.addItem(@hspace_2)

    @comboBox = Qt::ComboBox.new(@layoutWidget3)
    @comboBox.objectName = "comboBox"
    @comboBox.minimumSize = Qt::Size.new(69, 16)
    @comboBox.maximumSize = Qt::Size.new(16777215, 16)

    @assetsHeaderBox.addWidget(@comboBox)


    @assetsBox.addLayout(@assetsHeaderBox)

    @assetView = Qt::TreeView.new(@layoutWidget3)
    @assetView.objectName = "assetView"
    @sizePolicy3.heightForWidth = @assetView.sizePolicy.hasHeightForWidth
    @assetView.sizePolicy = @sizePolicy3
    @assetView.minimumSize = Qt::Size.new(131, 101)

    @assetsBox.addWidget(@assetView)

    @topRowSplitter.addWidget(@layoutWidget3)
    @mainSplitter.addWidget(@topRowSplitter)
    @layoutWidget4 = Qt::Widget.new(@mainSplitter)
    @layoutWidget4.objectName = "layoutWidget4"
    @consoleBox = Qt::VBoxLayout.new(@layoutWidget4)
    @consoleBox.spacing = 0
    @consoleBox.objectName = "consoleBox"
    @consoleBox.setContentsMargins(0, 0, 0, 0)
    @consoleLabel = Qt::Label.new(@layoutWidget4)
    @consoleLabel.objectName = "consoleLabel"
    @sizePolicy2.heightForWidth = @consoleLabel.sizePolicy.hasHeightForWidth
    @consoleLabel.sizePolicy = @sizePolicy2
    @consoleLabel.maximumSize = Qt::Size.new(16777215, 16)
    @consoleLabel.font = @font

    @consoleBox.addWidget(@consoleLabel)

    @console = Qt::PlainTextEdit.new(@layoutWidget4)
    @console.objectName = "console"
    @console.enabled = true
    @sizePolicy6 = Qt::SizePolicy.new(Qt::SizePolicy::Ignored, Qt::SizePolicy::Minimum)
    @sizePolicy6.setHorizontalStretch(0)
    @sizePolicy6.setVerticalStretch(0)
    @sizePolicy6.heightForWidth = @console.sizePolicy.hasHeightForWidth
    @console.sizePolicy = @sizePolicy6
    @console.minimumSize = Qt::Size.new(0, 41)
    @console.undoRedoEnabled = false
    @console.readOnly = true
    @console.tabStopWidth = 2
    @console.textInteractionFlags = Qt::LinksAccessibleByMouse|Qt::TextSelectableByMouse

    @consoleBox.addWidget(@console)

    @mainSplitter.addWidget(@layoutWidget4)

    @verticalLayout_4.addWidget(@mainSplitter)

    mainWin.centralWidget = @centralwidget
    @menubar = Qt::MenuBar.new(mainWin)
    @menubar.objectName = "menubar"
    @menubar.geometry = Qt::Rect.new(0, 0, 1150, 21)
    @menuFile = Qt::Menu.new(@menubar)
    @menuFile.objectName = "menuFile"
    @menuEdit = Qt::Menu.new(@menubar)
    @menuEdit.objectName = "menuEdit"
    @menuWindow = Qt::Menu.new(@menubar)
    @menuWindow.objectName = "menuWindow"
    mainWin.setMenuBar(@menubar)
    @statusbar = Qt::StatusBar.new(mainWin)
    @statusbar.objectName = "statusbar"
    mainWin.statusBar = @statusbar

    @menubar.addAction(@menuFile.menuAction())
    @menubar.addAction(@menuEdit.menuAction())
    @menubar.addAction(@menuWindow.menuAction())
    @menuFile.addAction(@menuFileOpen)
    @menuFile.addAction(@actionSave_All)
    @menuFile.addSeparator()
    @menuFile.addAction(@actionDelete_Unused_Assets)
    @menuFile.addSeparator()
    @menuFile.addAction(@actionQuit)
    @menuEdit.addAction(@menuEditUndo)
    @menuEdit.addAction(@menuEditRedo)
    @menuEdit.addSeparator()
    @menuEdit.addAction(@menuEditCopy)

    retranslateUi(mainWin)

    @slideTabs.setCurrentIndex(0)


    Qt::MetaObject.connectSlotsByName(mainWin)
    end # setupUi

    def setup_ui(mainWin)
        setupUi(mainWin)
    end

    def retranslateUi(mainWin)
    mainWin.windowTitle = Qt::Application.translate("MainWin", "UIC Inspectamator", nil, Qt::Application::UnicodeUTF8)
    @menuFileOpen.text = Qt::Application.translate("MainWin", "Open\342\200\246", nil, Qt::Application::UnicodeUTF8)
    @menuFileOpen.shortcut = Qt::Application.translate("MainWin", "Ctrl+O", nil, Qt::Application::UnicodeUTF8)
    @menuEditUndo.text = Qt::Application.translate("MainWin", "Undo", nil, Qt::Application::UnicodeUTF8)
    @menuEditUndo.shortcut = Qt::Application.translate("MainWin", "Ctrl+Z", nil, Qt::Application::UnicodeUTF8)
    @menuEditRedo.text = Qt::Application.translate("MainWin", "Redo", nil, Qt::Application::UnicodeUTF8)
    @menuEditRedo.shortcut = Qt::Application.translate("MainWin", "Ctrl+Y", nil, Qt::Application::UnicodeUTF8)
    @menuEditCopy.text = Qt::Application.translate("MainWin", "Copy", nil, Qt::Application::UnicodeUTF8)
    @menuEditCopy.shortcut = Qt::Application.translate("MainWin", "Ctrl+C", nil, Qt::Application::UnicodeUTF8)
    @actionSave_All.text = Qt::Application.translate("MainWin", "Save All\342\200\246", nil, Qt::Application::UnicodeUTF8)
    @actionSave_All.shortcut = Qt::Application.translate("MainWin", "Ctrl+S", nil, Qt::Application::UnicodeUTF8)
    @actionQuit.text = Qt::Application.translate("MainWin", "Quit", nil, Qt::Application::UnicodeUTF8)
    @actionDelete_Unused_Assets.text = Qt::Application.translate("MainWin", "Delete Unused Assets\342\200\246", nil, Qt::Application::UnicodeUTF8)
    @elementsHeader.text = Qt::Application.translate("MainWin", "Elements", nil, Qt::Application::UnicodeUTF8)
    @slideTabs.setTabText(@slideTabs.indexOf(@tab_3), Qt::Application.translate("MainWin", "0: Master", nil, Qt::Application::UnicodeUTF8))
    @slideTabs.setTabText(@slideTabs.indexOf(@tab_4), Qt::Application.translate("MainWin", "1: Slide1", nil, Qt::Application::UnicodeUTF8))
    @slideTabs.setTabText(@slideTabs.indexOf(@tab_5), Qt::Application.translate("MainWin", "2: Slide2", nil, Qt::Application::UnicodeUTF8))
    @valuesHeader.text = Qt::Application.translate("MainWin", "Values", nil, Qt::Application::UnicodeUTF8)
    @comboBox_2.insertItems(0, [Qt::Application.translate("MainWin", "(elements)", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "scenes", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "layers", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "cameras", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "lights", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "groups", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "models", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "materials", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "text", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "components", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "behaviors", nil, Qt::Application::UnicodeUTF8)])
    @comboBox_3.insertItems(0, [Qt::Application.translate("MainWin", "(types)", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "floats", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "integers", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "colors", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "strings", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "fonts", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "fontsizes", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "vectors", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "rotations", nil, Qt::Application::UnicodeUTF8)])
    @comboBox_4.insertItems(0, [Qt::Application.translate("MainWin", "(attributes)", nil, Qt::Application::UnicodeUTF8)])
    @assetsHeader.text = Qt::Application.translate("MainWin", "Assets", nil, Qt::Application::UnicodeUTF8)
    @comboBox.insertItems(0, [Qt::Application.translate("MainWin", "All Assets", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "Used Only", nil, Qt::Application::UnicodeUTF8),
        Qt::Application.translate("MainWin", "Unused Only", nil, Qt::Application::UnicodeUTF8)])
    @consoleLabel.text = Qt::Application.translate("MainWin", "Console", nil, Qt::Application::UnicodeUTF8)
    @menuFile.title = Qt::Application.translate("MainWin", "File", nil, Qt::Application::UnicodeUTF8)
    @menuEdit.title = Qt::Application.translate("MainWin", "Edit", nil, Qt::Application::UnicodeUTF8)
    @menuWindow.title = Qt::Application.translate("MainWin", "Window", nil, Qt::Application::UnicodeUTF8)
    end # retranslateUi

    def retranslate_ui(mainWin)
        retranslateUi(mainWin)
    end

end

module Ui
    class MainWin < Ui_MainWin
    end
end  # module Ui

