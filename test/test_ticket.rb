# A more general routine to encode to LLSD is probably in the future,
# but the structure is so simple a custom routine is sufficient for now.

# encode_ticket wraps a hash around the asset upload parameters, then uses
# Builder to create the required LLSD structure.

# The required structure is a series of <key> <string> elements, wrapped
# in the top level <llsd><map>.  For example: 
#     <llsd><map>
#        <key>asset_type</key>
#        <string>texture</string>
#      </map></llsd>

# TODO:  this test is lame and fragile; perhaps a mock object would help?

require "test/unit"
require "../redcap.rb"

$answer = %{<llsd>\n  <map>\n    <key>name</key>\n    <string>file.jpg</string>\n    <key>folder_id</key>\n    <string>000-ffff-f0lde4</string>\n    <key>description</key>\n    <string>uploaded by redcap</string>\n    <key>inventory_type</key>\n    <string>texture</string>\n    <key>asset_type</key>\n    <string>texture</string>\n  </map>\n</llsd>\n}

class TestTicket < Test::Unit::TestCase
  def test_typical
    result = encode_ticket("000-ffff-f0lde4", "file.jpg")
    assert_equal($answer, result)
  end
end
