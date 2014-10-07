require 'Qt'
require_relative 'window'

$app = Qt::Application.new(ARGV)
RUICWindow.new.show
$app.exec