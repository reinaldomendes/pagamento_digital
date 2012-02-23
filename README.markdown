# PagamentoDigital

Este é um plugin do Ruby on Rails que permite utilizar o [PagamentoDigital](www.pagamentodigital.com.br).

## SOBRE O PagamentoDigital

### Retorno Automático

Após o processo de compra e pagamento, o usuário é enviado de volta a seu site. Para isso, você deve configurar uma [URL de retorno](https://PagamentoDigital.uol.com.br/Security/ConfiguracoesWeb/RetornoAutomatico.aspx).

Antes de enviar o usuário para essa URL, o robô do PagamentoDigital faz um POST para ela, em segundo plano, com os dados e status da transação. Lendo esse POST, você pode obter o status do pedido. Se o pagamento entrou em análise, ou se o usuário pagou usando boleto bancário, o status será "Aguardando Pagamento" ou "Em Análise". Nesses casos, quando a transação for confirmada (o que pode acontecer alguns dias depois) a loja receberá outro POST, informando o novo status. **Cada vez que a transação muda de status, um POST é enviado.**

## REQUISITOS

A versão atual que está sendo mantida suporta Rails 3.0.0 ou superior.


### Configuração

O primeiro passo é instalar a biblioteca. Para isso, basta executar o comando

	gem install PagamentoDigital

Adicione a biblioteca ao arquivo Gemfile:

~~~.ruby
gem "PagamentoDigital", "~> 0.0.1"
~~~

Lembre-se de utilizar a versão que você acabou de instalar.

Depois de instalar a biblioteca, você precisará executar gerar o arquivo de configuração, que deve residir em `config/PagamentoDigital.yml`. Para gerar um arquivo de modelo execute

	rails generate PagamentoDigital:install

O arquivo de configuração gerado será parecido com isto:

~~~.rb
#...
lambda_retorno = lambda{Rails.application.routes.url_helpers.send :pagamento_digital_retorno_path }

#redirect após pagamento
return_to   lambda_retorno
#notificaçoes retorno automático
url_aviso   lambda_retorno
#email da loja
email  lambda{_pagamento.config[:email]}
#token gerado para sua conta
authenticity_token lambda{_pagamento.config[:token]}


development do    
  developer true  #modo de desenvolvimento
  base "http://localhost:3000"  #url base do servidor só necessário para developer  
end
~~~

Esta gem possui um modo de desenvolvimento que permite simular a realização de pedidos e envio de notificações; basta utilizar a opção `developer`. Ela é ativada por padrão nos ambientes de desenvolvimento e teste. Você deve configurar as opções `base`, que deverá apontar para o seu servidor e a URL de retorno, que deverá ser configurada no próprio [PagamentoDigital](https://PagamentoDigital.uol.com.br/?ind=689659), na página <https://PagamentoDigital.uol.com.br/Security/ConfiguracoesWeb/RetornoAutomatico.aspx>.

Para o ambiente de produção, que irá efetivamente enviar os dados para o [PagamentoDigital](https://PagamentoDigital.uol.com.br/?ind=689659), você precisará adicionar o e-mail cadastrado como vendedor e o `authenticity_token`, que é o Token para Conferência de Segurança, que pode ser conseguido na página <https://PagamentoDigital.uol.com.br/Security/ConfiguracoesWeb/RetornoAutomatico.aspx>.

### Montando o formulário

Para montar o seu formulário, você deverá utilizar a classe `PagamentoDigital::Order`. Esta classe deverá ser instanciada recebendo um identificador único do pedido. Este identificador permitirá identificar o pedido quando o [PagamentoDigital](https://PagamentoDigital.uol.com.br/?ind=689659) notificar seu site sobre uma alteração no status do pedido.

~~~.ruby
class CartController < ApplicationController
  def checkout
    # Busca o pedido associado ao usuario; esta logica deve
    # ser implementada por voce, da maneira que achar melhor
    @invoice = current_user.invoices.last

    # Instanciando o objeto para geracao do formulario
    @order = PagamentoDigital::Order.new(@invoice.id)

    # adicionando os produtos do pedido ao objeto do formulario
    @invoice.products.each do |product|
      # Estes sao os atributos necessarios. Por padrao, peso (:weight) eh definido para 0,
      # quantidade eh definido como 1 e frete (:shipping) eh definido como 0.
      @order.add :id => product.id, :preco => product.price, :descricao => product.title, :qtde => 1
    end
  end
end
~~~

Se você precisar, pode definir os dados de cobrança com o método `billing`.

~~~.ruby
@order.billing = {
       :nome                  => "nome",
      :cpf                   => "cpf",
      :sexo                  => "sexo",
      :data_nasc             => 'data_nascimento',      
      :email                 => "email",
      :telefone              => "telefone",
      :celular               => "celular",
      :endereco              => "endereco",
      :complemento           => "complemento",
      :bairro                => "bairro",
      :cidade                => "cidade",      
      :estado                => "estado",
      :cep                   => "cep",
      :free                  => "free",      
      :tipo_frete            => "tipo_frete",
      :desconto              => "desconto",
      :acrescimo             => "acrescimo",      
      :razao_social          => 'cliente_razao_social',
      :cnpj                  => "cliente_cnpj",
      :rg                    => 'rg',
      :hash                  => "hash",
}
~~~

Depois que você definiu os produtos do pedido, você pode exibir o formulário.

~~~.erb
<!-- app/views/cart/checkout.html.erb -->
<%= pagamento_digital_form @order, :submit => "Efetuar pagamento!" %>
~~~

Por padrão, o formulário é enviado para o email no arquivo de configuração. Você pode mudar o email com a opção `:email`.

~~~.erb
<%= PagamentoDigital_form @order, :submit => "Efetuar pagamento!", :email => @account.email %>
~~~

### Recebendo notificações

Toda vez que o status de pagamento for alterado, o [PagamentoDigital](http://www.pagamentodigital.com.br) irá notificar sua URL de retorno com diversos dados. Você pode interceptar estas notificações com o método `PagamentoDigital_notification`. O bloco receberá um objeto da classe `PagamentoDigital::Notification` e só será executado se for uma notificação verificada junto ao [PagamentoDigital](http://www.pagamentodigital.com.br).

~~~.ruby
class CartController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def confirm
    return unless request.post?

	pagamento_digital_notification do |notification|
	  # Aqui voce deve verificar se o pedido possui os mesmos produtos
	  # que voce cadastrou. O produto soh deve ser liberado caso o status
	  # do pedido seja "completed" ou "approved"
          #exemplo abaixo#
          valor_notify = notification.valor_original.to_f.round(2) #valor que veio do pagamento digital
          valor_loja = @pedido.preco_final.to_f.round(2) #valor que está em sua loja
          raise "valor retornado pelo pagamento digital é diferente que preço da loja
                 p. digital=#{valor_notify} loja=#{valor_loja}" if valor_notify != valor_loja           
          if notification.valid?#valida a notificação antes de prosseguir
            if notification.aprovada? #status aprovada
              @pedido.status_financeiro = Pedido::StatusFinanceiro::PAGO
            elsif notification.cancelada? #cancelada
              @pedido.status_financeiro = Pedido::StatusFinanceiro::CANCELADO
              @pedido.status_processo = Pedido::StatusProcesso::CANCELADO #cancela faz estorno ect...
            else
              #//pendente não faz nada
            end
          end
	end

	render :nothing => true
  end
end
~~~
O método `pagamento_digital_notification` também pode receber como parâmetro o `authenticity_token` que será usado pra verificar a autenticação.

~~~.ruby
class CartController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def confirm
    return unless request.post?
	# Se voce receber pagamentos de contas diferentes, pode passar o
	# authenticity_token adequado como parametro para PagamentoDigital_notification
	account = Account.find(params[:seller_id])
	pagamento_digital_notification(account.authenticity_token) do |notification|
            
        end

	render :nothing => true
  end
end
~~~

O objeto `notification` possui os seguintes métodos:

* `PagamentoDigital::Notification#products`: Lista de produtos enviados na notificação.
* `PagamentoDigital::Notification#frete`: Valor do frete
* `PagamentoDigital::Notification#status`: Status do pedido
* `PagamentoDigital::Notification#payment_method`: Tipo de pagamento
* `PagamentoDigital::Notification#processed_at`: Data e hora da transação
* `PagamentoDigital::Notification#cliente`: Dados do comprador
* `PagamentoDigital::Notification#valid?(force=false)`: Verifica se a notificação é válida, confirmando-a junto ao PagamentoDigital. A resposta é jogada em cache e pode ser forçada com `PagamentoDigital::Notification#valid?(:force)`

**ATENÇÃO:** Não se esqueça de adicionar `skip_before_filter :verify_authenticity_token` ao controller que receberá a notificação; caso contrário, uma exceção será lançada.

### Utilizando modo de desenvolvimento

Toda vez que você enviar o formulário no modo de desenvolvimento, um arquivo YAML será criado em `tmp/PagamentoDigital-#{Rails.env}.yml`. Esse arquivo conterá todos os pedidos enviados.

Depois, você será redirecionado para a URL de retorno que você configurou no arquivo `config/PagamentoDigital.yml`. Para simular o envio de notificações, você deve utilizar a rake `PagamentoDigital:notify`.

	$ rake PagamentoDigital:notify ID=<id do pedido>

O ID do pedido deve ser o mesmo que foi informado quando você instanciou a class `PagamentoDigital::Order`. Por padrão, o status do pedido será `completed` e o tipo de pagamento `credit_card`. Você pode especificar esses parâmetros como no exemplo abaixo.

	$ rake PagamentoDigital:notify ID=1 PAYMENT_METHOD=boleto STATUS=canceled NOTE="Enviar por motoboy" NAME="José da Silva" EMAIL="jose@dasilva.com"

#### PAYMENT_METHOD

* `credicard_visa`: Cartão de crédito visa
* `credicard_mastercard`: Cartão de crédito mastercard
* `credicard_amex`: Cartão de crédito amex
* `credicard_diners`: Cartão de crédito diners
* `credicard_aura`: Cartão de crédito Aura
* `credicard_hiper`: Cartão de crédito HiperCard
* `boleto`: Boleto
* `trans_bb`: Transferencia online Banco do Brasil
* `trans_bradesco`: Transferenciaonline  Bradesco
* `trans_itau`: Transferencia online Itau
* `trans_banrisul`: Transferencia online Banrisul
* `trans_hsbc`: Transferencia online HSBC 


#### STATUS

* `aprovada`: aprovada
* `pendente`: Aguardando pagamento
* `cancelada`: Cancelada


### Codificação (Encoding)

Esta biblioteca assume que você está usando UTF-8 como codificação de seu projeto. Neste caso, o único ponto onde os dados são convertidos para UTF-8 é quando uma notificação é enviada do UOL em ISO-8859-1.

Se você usa sua aplicação como ISO-8859-1, esta biblioteca NÃO IRÁ FUNCIONAR. Nenhum patch dando suporte ao ISO-8859-1 será aplicado; você sempre pode manter o seu próprio fork, caso precise.

## TROUBLESHOOTING

**Quero utilizar o servidor em Python para testar o retorno automático, mas recebo OpenSSL::SSL::SSLError (SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B)**

Neste caso, você precisa forçar a validação do POST enviado. Basta acrescentar a linha:

~~~.ruby
PagamentoDigital_notification do |notification|
  notification.valid?(:force => true)
  # resto do codigo...
end
~~~

## AUTOR:

Reinaldo Mendes (http://reinaldo-mendes.blogspot.com/) baseado em https://github.com/fnando/pagseguro


## LICENÇA:

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
