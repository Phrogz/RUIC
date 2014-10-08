window_ui.rb: window.ui
	rbuic4 window.ui -o window_ui.rb

window_qrc.rb: resources.qrc
	rbrcc -name resources resources.qrc -o window_qrc.rb

run: window_ui.rb window_qrc.rb window.rb
	ruby launch.rb
