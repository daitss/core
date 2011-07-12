module Daitss
  class Wip

    def withdraw
      #update aip descriptor to contain only package level MD
      #update storage (delete resource), update database
      
      step('load aip metadata') do
        load_dmd
        if package.d1?
          load_d1_package_digiprov
        else
          load_old_package_digiprov
        end
      end

      step 'withdraw digiprov'  do
        metadata['withdraw-event'] = withdraw_event package
        metadata['withdraw-agent'] = system_agent
      end

      step('make aip descriptor') { make_aip_descriptor }
      step('validate aip descriptor') { validate_aip_descriptor }
      step('withdraw aip') { withdraw_aip }
    end

  end # of class
end # of module
