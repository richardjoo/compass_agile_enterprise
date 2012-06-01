module ErpTechSvcs
  module Utils
    module Sessions
      class DeleteExpiredSessionsService

        def initialize
          @session_age = ErpTechSvcs::Config.session_expires_in_hours.hours
        end

        def execute
          ActiveRecord::SessionStore::Session.delete_all ['updated_at < ?', @session_age.ago]
        end
      end #DeleteExpiredSessionsService
    end #Sessions
  end #Utils
end #ErpTechSvcs