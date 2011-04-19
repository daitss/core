namespace :db do
  desc 'generate sample data'
  task :sampledata => :environment do
    require 'blueprints'

    # get a random sample out of a range
    class Range

      def roll
        to_a.rand
      end

    end

    (10..15).roll.times do

      a = Account.make

      a.projects += (3..5).roll.times.map do
        p = Project.make_unsaved

        p.packages = (20..30).roll.times.map do
          Package.make_unsaved
        end

        p
      end

      a.agents = (2..5).roll.times.map do
        u = User.make_unsaved
        u.encrypt_auth 'pw'
        u
      end

      a.save or debug
      true
    end
  end
end
