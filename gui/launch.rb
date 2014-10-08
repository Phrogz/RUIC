#encoding: utf-8
require 'Qt'
require_relative 'window'

class Qt::Application
	def self.translate(*a,&b)
		method_missing(:translate,*a,&b).force_encoding('utf-8')
	end
end

$app = Qt::Application.new(ARGV)
UIC::GUI.new.show
$app.exec