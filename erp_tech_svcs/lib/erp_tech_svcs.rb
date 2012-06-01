#compass_ae libraries
require 'erp_base_erp_svcs'

require 'paperclip'
require 'delayed_job'
require 'delayed_job_active_record'
require 'sorcery'
require 'pdfkit'
require "erp_tech_svcs/version"
require "erp_tech_svcs/utils/compass_logger"
require "erp_tech_svcs/utils/default_nested_set_methods"
require "erp_tech_svcs/utils/compass_access_negotiator"
require "erp_tech_svcs/extensions"
require 'aws'
require 'erp_tech_svcs/file_support'
require 'erp_tech_svcs/sms_wrapper'
require "erp_tech_svcs/config"
require "erp_tech_svcs/engine"
require "erp_tech_svcs/delayed_jobs"
require 'erp_tech_svcs/utils/delete_expired_sessions_service'
require 'erp_tech_svcs/mail_processor'

module ErpTechSvcs
end
