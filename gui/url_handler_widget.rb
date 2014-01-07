require_relative '../lib/url_scheme_fuzzer'
require_relative 'url_scheme_fuzz_widget'
require_relative 'url_scheme_widget'

class URLHandlerWidget < Qt::TabWidget

  def initialize *args
    super *args

    @tabs = Hash.new

    @url_scheme = URLSchemeWidget.new self
    @tabs[:scheme] = addTab(@url_scheme, "URL Schemes")

    @url_fuzz = URLSchemeFuzzWidget.new self
    @tabs[:fuzzer] = addTab(@url_fuzz, "Fuzzer")
  end

end