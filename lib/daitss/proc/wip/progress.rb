require 'daitss/proc/wip'

module Daitss

  class Wip

    def progress sym

      case sym
      when :virus_check
        steps_performed_against_original /^step\.virus-check-\d+$/

      when :describe_original
        steps_performed_against_original /^step\.describe-\d+$/

      when :migrate_original
        steps_performed_against_original /^step\.migrate-\d+$/

      when :normalize_original
        steps_performed_against_original /^step\.normalize-\d+$/

      when :describe_transformed
        steps_performed_against_transformed /^step\.describe-\d+(norm|mig)-\d+$/

      when :xmlres
        tags.has_key?('step.xml-resolution') ? 'done' : '...'

      when :descriptor
        tags.has_key?('step.make-aip-descriptor') ? 'done' : '...'

      when :save
        tags.has_key?('step.make-aip') ? 'done' : '...'

      else raise "unknown progress for #{sym}"
      end

    end

    private

    def steps_performed_against_original pattern
      ks = tags.keys_like pattern
      "#{ks.size} of #{original_datafiles.size} datafiles"
    end

    def steps_performed_against_transformed pattern
      ks = tags.keys_like pattern
      transformed = normalized_datafiles + migrated_datafiles
      "#{ks.size} of #{transformed.size} datafiles"
    end

  end

end
