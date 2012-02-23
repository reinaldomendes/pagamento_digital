namespace :pagamento_digital do
  desc "Send notification to the URL specified in your config/pagseguro.yml file"
  task :notify => :environment do
    PagamentoDigital::Rake.run
  end
end
