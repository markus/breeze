require 'fog'

module Fog
  class Model

    def current_state
      reload
      state
    end

    def running?
      reload
      ready?
    end

    # this may be broken for some providers
    def stopped?
      current_state == 'stopped'
    end

  end
end
