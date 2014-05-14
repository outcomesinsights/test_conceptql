module Pbcopeez
  def pbcopy(input)
    str = input.to_s
    IO.popen('pbcopy', 'w') do |i|
      i << str
    end
  rescue
    # nothing
  ensure
    str
  end
end
