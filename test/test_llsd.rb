# LLSD (The Linden Lab Structured Data system) is the XML protocol
# used for redcap's communication with Second Life.  All current
# structures are simple maps (hashes) with pairs of key/values.

# For more information regarding The LLSD flexible data system
# see http://wiki.secondlife.com/wiki/LLSD

require 'test/unit'
require 'redcap'

$llsd = %{
  <llsd>
    <map>
      <key>name</key>
      <string>/Users/orion/Desktop/textures/rose bases are red.jpeg</string>
      <key>folder_id</key>
      <string>98359cef-1609-4317-be54-f044cc784b0a</string>
      <key>description</key>
      <string>uploaded by redcap</string>
      <key>inventory_type</key>
      <string>texture</string>
      <key>asset_type</key>
      <string>texture</string>
    </map>
  </llsd>
}

$llsd_odd = %{
  <llsd>
    <map>
      <key>name</key>
    </map>
  </llsd>
}

class TestLLSD < Test::Unit::TestCase

  def testTypicalDecode
    result = decode_llsd($llsd)
    assert_equal("/Users/orion/Desktop/textures/rose bases are red.jpeg", result["name"])
    assert_equal("98359cef-1609-4317-be54-f044cc784b0a", result["folder_id"])
    assert_equal("uploaded by redcap", result["description"])
    assert_equal("texture", result["inventory_type"])
    assert_equal("texture", result["asset_type"])
  end
  
  def testDecodeBadXML
    assert_raise(REXML::ParseException) { decode_llsd("<badxml>") }
  end
  
  # The LLSD should contain an even number of elements (key, value, key, value)
  # Well formed LLSD shouldn't have an odd number, but if it does...
  def testDecodeOddPair
    assert_raise(ArgumentError) { decode_llsd($llsd_odd) }
  end
  
  def testDecodeRandomText
    result = decode_llsd("gibberish")
    assert_equal({}, result)
  end
  
end