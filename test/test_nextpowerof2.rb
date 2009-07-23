# nextpow2 is adapted from function by Simon Kröger posted in comp.lang.ruby
# original post: http://www.ruby-forum.com/topic/76261

# The adaptation made for Second Life constrain the maximum value returned
# to 1024, the maximum dimention of an SL texture.

require 'test/unit'
require '../redcap'

class TestNextPowerOf2 < Test::Unit::TestCase
  
  def setup
    @check_array = [[1, 1], [2,2]]
    (2..9).each do | i |
      @check_array << [ 2**i - 1, 2**i] << [2**i, 2**i] << [2**i + 1, 2**(i+1)]
    end
  end  
  
  # test copied from Rick Denatale's post to the thread mentioned above.
  def test_normal
    @check_array.each do | input, output |
      assert_equal(output, nextpow2(input))
    end
  end
  
  def test_over
    assert_equal(1024, nextpow2(1023))
    assert_equal(1024, nextpow2(1025))
    assert_equal(1024, nextpow2(10240))
  end
  
  def test_under
    assert_equal(2, nextpow2(2))
    assert_equal(1, nextpow2(1))
    assert_equal(1, nextpow2(0))
    assert_raise(NameError) { nextpow2(-1) }
  end
  
end