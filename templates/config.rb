################################################################
#######só para exemplo utilizar da forma que melhor entender
################################################################
_pagamento = {  
}
def pagamento.config
  {
    :email => "xxx@xxx.com",
    :token => "xxxxxxxxxxxx"
  }
end
def pagamento.reload
  self
end


################################################################################
#_pagamento = FormaPagamento.find_by_chave('pagamento_digital')
lambda_retorno = lambda{Rails.application.routes.url_helpers.send :pagamento_digital_retorno_url }

#redirect após pagamento
return_to   lambda_retorno
#notificaçoes retorno automático
url_aviso   lambda_retorno
#email da loja
email  lambda{_pagamento.reload.config[:email]}
#token gerado para sua conta
authenticity_token lambda{_pagamento.config[:token]}


development do    
  developer true  #modo de desenvolvimento
  base "http://localhost:3000"  #url base do servidor só necessário para developer  
end


#production do
#  #developer false    
##  email  lambda{_pagamento.reload.config[:email]}
##  authenticity_token lambda{_pagamento.reload.config[:token]}
#end
  
  
