require File.expand_path(File.join(File.dirname(__FILE__),  'test_helper'))
require 'google_font_helper'

class GoogleFontHelperTest < ActionView::TestCase
  tests GoogleFontHelper

  def test_no_variants
    expected_link = "http://fonts.googleapis.com/css?family=Arimo"
    actual_link_tag = google_font_link 'Arimo'
    assert actual_link_tag.include?(expected_link), "expected #{actual_link_tag} to include #{expected_link}"
  end

  def test_some_variants
    expected_link = "http://fonts.googleapis.com/css?family=Arimo:regular,bold"
    actual_link_tag = google_font_link 'Arimo', :regular, :bold
    assert actual_link_tag.include?(expected_link), "expected #{actual_link_tag} to include #{expected_link}"
  end

  def test_with_spaces
    expected_link = "http://fonts.googleapis.com/css?family=Goudy+Bookletter+1911"
    actual_link_tag = google_font_link 'Goudy Bookletter 1911'
    assert actual_link_tag.include?(expected_link), "expected #{actual_link_tag} to include #{expected_link}"
  end

end
