require 'Qt'
require_relative 'window'

$app = Qt::Application.new(ARGV)
UIC::GUI.new.show
$app.exec