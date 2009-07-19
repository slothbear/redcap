# Second Life hands us complete URLs, but Net::HTTP requires
# separate values for protocol, server, port, and path.

# HTTPS protocol is always used, so that part of the URL is ignored.


require 'test/unit'
require '../lib/redcap/uploader'

class TestParseCap < Test::Unit::TestCase
  
  def test_typical
    result = parse_capability("https://sim4.aditi.lindenlab.com:12043/cap/f692b7fc-3074-a277-c08c-74363e5248cb")
    assert_equal(3,result.size)
    server, port, path = result
    assert_equal("sim4.aditi.lindenlab.com", server)
    assert_equal("12043", port)
    assert_equal("/cap/f692b7fc-3074-a277-c08c-74363e5248cb", path)
  end
  
  def test_abnormal
    assert_raise(RuntimeError) { parse_capability("") }
    assert_raise(RuntimeError) { parse_capability("ftp://www.secondlife.com:12045/cap/xxx") }
    assert_raise(RuntimeError) { parse_capability("https://test.server.com:/app/path") }
  end
  
  
end
