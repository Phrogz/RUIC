=begin
** Form generated from reading ui file 'window.ui'
**
** Created: Mon Oct 6 20:32:15 2014
**      by: Qt User Interface Compiler version 4.8.6
**
** WARNING! All changes made in this file will be lost when recompiling ui file!
=end

class Ui_MainWin
    attr_reader :menuFileOpen
    attr_reader :menuEditUndo
    attr_reader :menuEditRedo
    attr_reader :menuEditCopy
    attr_reader :centralwidget
    attr_reader :verticalLayout_2
    attr_reader :splitter_4
    attr_reader :splitter_3
    attr_reader :splitter_2
    attr_reader :appHierarchy
    attr_reader :splitter
    attr_reader :availSlides
    attr_reader :inspector
    attr_reader :layoutWidget
    attr_reader :assetsLayout
    attr_reader :assetView
    attr_reader :removeUnusedAssets
    attr_reader :widget
    attr_reader :verticalLayout
    attr_reader :label
    attr_reader :logOutput
    attr_reader :menubar
    attr_reader :menuFile
    attr_reader :menuEdit
    attr_reader :menuWindow
    attr_reader :statusbar

    def setupUi(mainWin)
    if mainWin.objectName.nil?
        mainWin.objectName = "mainWin"
    end
    mainWin.resize(884, 669)
    @menuFileOpen = Qt::Action.new(mainWin)
    @menuFileOpen.objectName = "menuFileOpen"
    @menuFileOpen.shortcutContext = Qt::ApplicationShortcut
    @menuEditUndo = Qt::Action.new(mainWin)
    @menuEditUndo.objectName = "menuEditUndo"
    @menuEditRedo = Qt::Action.new(mainWin)
    @menuEditRedo.objectName = "menuEditRedo"
    @menuEditCopy = Qt::Action.new(mainWin)
    @menuEditCopy.objectName = "menuEditCopy"
    @centralwidget = Qt::Widget.new(mainWin)
    @centralwidget.objectName = "centralwidget"
    @sizePolicy = Qt::SizePolicy.new(Qt::SizePolicy::Preferred, Qt::SizePolicy::Minimum)
    @sizePolicy.setHorizontalStretch(0)
    @sizePolicy.setVerticalStretch(0)
    @sizePolicy.heightForWidth = @centralwidget.sizePolicy.hasHeightForWidth
    @centralwidget.sizePolicy = @sizePolicy
    @centralwidget.autoFillBackground = true
    @verticalLayout_2 = Qt::VBoxLayout.new(@centralwidget)
    @verticalLayout_2.objectName = "verticalLayout_2"
    @splitter_4 = Qt::Splitter.new(@centralwidget)
    @splitter_4.objectName = "splitter_4"
    @splitter_4.orientation = Qt::Vertical
    @splitter_3 = Qt::Splitter.new(@splitter_4)
    @splitter_3.objectName = "splitter_3"
    @splitter_3.orientation = Qt::Horizontal
    @splitter_2 = Qt::Splitter.new(@splitter_3)
    @splitter_2.objectName = "splitter_2"
    @splitter_2.orientation = Qt::Horizontal
    @appHierarchy = Qt::TreeWidget.new(@splitter_2)
    @appHierarchy.objectName = "appHierarchy"
    @appHierarchy.uniformRowHeights = true
    @appHierarchy.headerHidden = false
    @appHierarchy.columnCount = 2
    @splitter_2.addWidget(@appHierarchy)
    @splitter = Qt::Splitter.new(@splitter_2)
    @splitter.objectName = "splitter"
    @splitter.orientation = Qt::Vertical
    @availSlides = Qt::ListView.new(@splitter)
    @availSlides.objectName = "availSlides"
    @availSlides.gridSize = Qt::Size.new(0, 0)
    @splitter.addWidget(@availSlides)
    @inspector = Qt::TableView.new(@splitter)
    @inspector.objectName = "inspector"
    @inspector.horizontalScrollBarPolicy = Qt::ScrollBarAlwaysOff
    @inspector.showGrid = true
    @inspector.wordWrap = false
    @splitter.addWidget(@inspector)
    @splitter_2.addWidget(@splitter)
    @splitter_3.addWidget(@splitter_2)
    @layoutWidget = Qt::Widget.new(@splitter_3)
    @layoutWidget.objectName = "layoutWidget"
    @assetsLayout = Qt::VBoxLayout.new(@layoutWidget)
    @assetsLayout.spacing = 0
    @assetsLayout.objectName = "assetsLayout"
    @assetsLayout.setContentsMargins(0, 0, 0, 0)
    @assetView = Qt::TreeView.new(@layoutWidget)
    @assetView.objectName = "assetView"
    @sizePolicy1 = Qt::SizePolicy.new(Qt::SizePolicy::Expanding, Qt::SizePolicy::Ignored)
    @sizePolicy1.setHorizontalStretch(0)
    @sizePolicy1.setVerticalStretch(0)
    @sizePolicy1.heightForWidth = @assetView.sizePolicy.hasHeightForWidth
    @assetView.sizePolicy = @sizePolicy1

    @assetsLayout.addWidget(@assetView)

    @removeUnusedAssets = Qt::PushButton.new(@layoutWidget)
    @removeUnusedAssets.objectName = "removeUnusedAssets"

    @assetsLayout.addWidget(@removeUnusedAssets)

    @splitter_3.addWidget(@layoutWidget)
    @splitter_4.addWidget(@splitter_3)
    @widget = Qt::Widget.new(@splitter_4)
    @widget.objectName = "widget"
    @verticalLayout = Qt::VBoxLayout.new(@widget)
    @verticalLayout.objectName = "verticalLayout"
    @verticalLayout.setContentsMargins(0, 0, 0, 0)
    @label = Qt::Label.new(@widget)
    @label.objectName = "label"
    @sizePolicy2 = Qt::SizePolicy.new(Qt::SizePolicy::Preferred, Qt::SizePolicy::Maximum)
    @sizePolicy2.setHorizontalStretch(0)
    @sizePolicy2.setVerticalStretch(0)
    @sizePolicy2.heightForWidth = @label.sizePolicy.hasHeightForWidth
    @label.sizePolicy = @sizePolicy2

    @verticalLayout.addWidget(@label)

    @logOutput = Qt::PlainTextEdit.new(@widget)
    @logOutput.objectName = "logOutput"
    @sizePolicy3 = Qt::SizePolicy.new(Qt::SizePolicy::Ignored, Qt::SizePolicy::Minimum)
    @sizePolicy3.setHorizontalStretch(0)
    @sizePolicy3.setVerticalStretch(0)
    @sizePolicy3.heightForWidth = @logOutput.sizePolicy.hasHeightForWidth
    @logOutput.sizePolicy = @sizePolicy3
    @logOutput.undoRedoEnabled = false
    @logOutput.readOnly = true
    @logOutput.tabStopWidth = 2
    @logOutput.textInteractionFlags = Qt::LinksAccessibleByMouse|Qt::TextSelectableByMouse

    @verticalLayout.addWidget(@logOutput)

    @splitter_4.addWidget(@widget)

    @verticalLayout_2.addWidget(@splitter_4)

    mainWin.centralWidget = @centralwidget
    @menubar = Qt::MenuBar.new(mainWin)
    @menubar.objectName = "menubar"
    @menubar.geometry = Qt::Rect.new(0, 0, 884, 22)
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
    @menuEdit.addAction(@menuEditUndo)
    @menuEdit.addAction(@menuEditRedo)
    @menuEdit.addSeparator()
    @menuEdit.addAction(@menuEditCopy)

    retranslateUi(mainWin)

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
    @menuEditCopy.text = Qt::Application.translate("MainWin", "Copy", nil, Qt::Application::UnicodeUTF8)
    @menuEditCopy.shortcut = Qt::Application.translate("MainWin", "Ctrl+C", nil, Qt::Application::UnicodeUTF8)
    @appHierarchy.headerItem.setText(0, Qt::Application.translate("MainWin", "1", nil, Qt::Application::UnicodeUTF8))
    @appHierarchy.headerItem.setText(1, Qt::Application.translate("MainWin", "2", nil, Qt::Application::UnicodeUTF8))
    @removeUnusedAssets.text = Qt::Application.translate("MainWin", "Remove Unused", nil, Qt::Application::UnicodeUTF8)
    @label.text = Qt::Application.translate("MainWin", "Output", nil, Qt::Application::UnicodeUTF8)
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

