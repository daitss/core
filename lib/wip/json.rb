require 'json'
require 'wip'

class Wip

  def to_json *a

    hash = {
      :running => @wip.running?,
      :done => (@wip.done? ? true : false),
      :snafu => (@wip.snafu? ? false : @wip.snafu),
      :reject => (@wip.reject? ? false : @wip.reject),
    }

    hash.to_json *a
  end

end
