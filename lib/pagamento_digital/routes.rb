Rails.application.routes.draw do
  get "pagamento_digital_developer/confirm", :to => "pagamento_digital/developer#confirm"
  post "pagamento_digital_developer", :to => "pagamento_digital/developer#create"
end
