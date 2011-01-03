module Daitss

  class ServiceError < StandardError

    def initialize message, curl
      super <<MSG
#{message}
#{curl.url}: #{curl.response_code}
#{curl.body_str}
MSG
    end

  end

end
