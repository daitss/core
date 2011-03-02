namespace :daitss do

  desc 'start jobs'
  task :pulse => :environment do
    log = Logger.new $stdout
    log.info "daitss pulse started"

    loop do

      # make wips from ready reqs
      ready = Request.all(:is_authorized => true,
                          :status => :enqueued,
                          :order => [ :timestamp.asc ])

      ready.reject! { |r| r.package.wip }

      ready.each do |r|
        r.dispatch
        w = r.package.wip
        log.info "#{w.id}.#{w.task} made"
      end

      # start wips
      wips = Wip.all
      startable = wips.reject do |w|
        w.done? or w.running? or w.snafu? or w.stopped?
      end

      running = wips.select { |w| w.running? }
      n = Setting.get('throttle').value.to_i - running.size

      startable.take(n > 0 ? n : 0).each do |w|
        w.spawn
        log.info "#{w.id}.#{w.task} spawned"
      end

      sleep 2
    end

  end

end
