require "rails/generators/base"

module PagamentoDigital
  class InstallGenerator < ::Rails::Generators::Base
    namespace "pagseguro:install"
    source_root File.dirname(__FILE__) + "/../../templates"

    def copy_configuration_file
      copy_file "config.rb", "config/pagamento_digital.rb"
    end
  end
end
