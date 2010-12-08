require 'data_mapper'

module Daitss

  class EggHeadKey < DataMapper::Property::String
    key true
    default proc { |res, prop| EggHeadKey.new_egg_head_key }

    DIGITS = 36**14

    # @return [String] raandomly matching /E[0-9A-Z]{8}_[0-9A-Z]{6}/
    def EggHeadKey.new_egg_head_key
      s = rand(DIGITS).to_s(36).upcase
      s.insert(8, "_")
      'E' + s
    end

  end

end
