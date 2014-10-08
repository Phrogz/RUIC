all: window_ui.rb window_qrc.rb

window_ui.rb: window.ui
	rbuic4 window.ui -o window_ui.rb

window_qrc.rb: resources.qrc
	rbrcc -name resources resources.qrc -o window_qrc.rb

clean:
	rm -f window_ui.rb
	rm -f window_qrc.rb

run: all
	ruby launch.rb
