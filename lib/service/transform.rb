require 'template'
require 'datafile'
require 'service/error'

class DataFile

  # Returns a new datafile provided there is a preservation policy to migrate
  def migrate

    preserve(CONFIG['migrate-uri']) do |df, tr_url|
      event_id = URI.join(df.uri, 'event', 'migrate').to_s
      df['migrate-event'] = event :id => event_id, :type => 'migrate'
      df['migrate-agent'] = agent :id => tr_url, :name => 'transformation service', :type => 'software'
      df.describe! :transform_src => uri, :transform_event => event_id
    end

  end

  # Returns a new datafile provided there is a preservation policy to normalize
  def normalize

    preserve(CONFIG['normalize-uri']) do |df, tr_url|
      event_id = URI.join(df.uri, 'event', 'normalize').to_s
      df['normalize-event'] = event :id => event_id, :type => 'normalize'
      df['normalize-agent'] = agent :id => tr_url, :name => 'transformation service', :type => 'software'
      df.describe! :transform_src => uri, :transform_event => event_id
    end

  end

  private

  def preserve ap_url, &blk
    actionplan(ap_url) { |tr_url| transform tr_url, &blk }
  end

  def actionplan url

    Net::HTTP.post_form(URI.parse(url), 'description' => metadata['describe-object']) do |res|

      case res
      when Net::HTTPRedirection then yield res['location']
      when Net::HTTPNotFound then nil
      else res.error!
      end

    end

  end

  def transform url

    Net::HTTP.post_form(URI.parse(tr_url), 'data' => self.open { |io| io.read } ) do |res|

      case res
      when Net::HTTPSuccess
        df = wip.new_datafile
        df.open(:w) { |io| io.write res.body }
        yield df, transformation_url
        df
      else res.error!
      end

    end

  end

end
