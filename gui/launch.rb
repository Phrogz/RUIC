#encoding: utf-8
require 'Qt'
require_relative 'window'

class Qt::Application
	def self.translate(*a,&b)
		method_missing(:translate,*a,&b).force_encoding('utf-8')
	end
end

Qt::CoreApplication.organization_name   = "PhrogzSoft"
Qt::CoreApplication.organization_domain = "phrogz.net"
Qt::CoreApplication.application_name    = "RUIC"
$prefs = Qt::Settings.new

$app = Qt::Application.new(ARGV)
gui = NDD::GUI.new
gui.show
gui.open
$app.exec