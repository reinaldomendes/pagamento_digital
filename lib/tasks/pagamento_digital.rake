namespace :pagamento_digital do
  desc "Send notification to the URL specified in your config/pagamento_digital.rb file"
  task :notify => :environment do
    PagamentoDigital::Rake.run
  end
end
