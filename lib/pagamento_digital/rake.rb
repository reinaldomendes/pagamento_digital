# encoding: utf-8
module PagamentoDigital
  module Rake
    extend self
    def run
      require "digest/md5"

      env = ENV.inject({}) do |buffer, (name, value)|
        value = value.respond_to?(:force_encoding) ? value.dup.force_encoding("UTF-8") : value
        buffer.merge(name => value)
      end

      # Not running in developer mode? Exit!
      unless PagamentoDigital.developer?
        puts "=> [PagamentoDigital] Can only notify development URLs"
        puts "=> [PagamentoDigital] Double check your config/pagseguro.yml file"
        exit 1
      end

      # There's no orders file! Exit!
      unless File.exist?(PagamentoDigital::DeveloperController::ORDERS_FILE)
        puts "=> [PagamentoDigital] No orders added. Exiting now!"
        exit 1
      end

      # Load the orders file
      orders = YAML.load_file(PagamentoDigital::DeveloperController::ORDERS_FILE)

      # Ops! No orders added! Exit!
      unless orders
        puts "=> [PagamentoDigital] No invoices created. Exiting now!"
        exit 1
      end

      # Get the specified order
      order = orders[env["ID"]]

      # Not again! No order! Exit!
      unless order
        puts "=> [PagamentoDigital] The order #{env['ID'].inspect} could not be found. Exiting now!"
        exit 1
      end

      # Set the client's info
      name = env.fetch("NAME", Faker.name)
      email = env.fetch("EMAIL", Faker.email)

      order["cliente_nome"] = name
      order["cliente_email"] = email
      order["cliente_endereco"] = Faker.street_name + ", Nº #{rand(1000)}"
      
      order["cliente_complemento"] = Faker.secondary_address
      order["cliente_bairro"] = Faker.city
      order["cliente_cidade"] = Faker.city
      order["cliente_estado"] = Faker.state
      
      order["cliente_cep"] = Faker.zipcode
      order["cliente_telefone"] = Faker.phone_number
      order["cliente_celular"] = Faker.phone_number

      # Set the transaction date
      order["data_transacao"] = Time.now.strftime("%d/%m/%Y %H:%M:%S")

      # Replace the order id to the correct name
      order["id_pedido"] = order.delete("id_pedido")
      

      to_price = proc do |price|
        if price.to_s =~ /^(.*?)[,\.](.*?)$/
          "#{$1}.#{$2}".to_f.round
        else
          "0.00".to_f.round
        end
      end
      sum_valor_produtos = 0
      index = 0
      loop do
        index+=1
        break unless order.has_key?("produto_valor_#{index}")                  
        order["produto_codigo_#{index}"] = order.delete("produto_codigo_#{index}")
        order["produto_descricao_#{index}"] = order.delete("produto_descricao_#{index}")
        order["produto_valor_#{index}"] = to_price.call(order.delete("produto_valor_#{index}"))
        order["produto_qtde_#{index}"] = order.delete("produto_qtde_#{index}")        
        #soma produtos
        sum_valor_produtos += order["produto_valor_#{index}"].to_f * order["produto_qtde_#{index}"].to_f
      end
      
      order['frete'] = to_price.call(order.delete "frete")
      
      order['valor_original'] = sum_valor_produtos + order['frete'].to_f
      order['valor_loja'] = order['valor_original']
      order['valor_total'] = order['valor_loja'] + 1.5#taxa só para sacanear
      
      # Retrieve the specified status or default to :completed
      status = env.fetch("COD_STATUS", :aprovada).to_sym

      # Retrieve the specified payment method or default to :credit_card
      payment_method = env.fetch("PAYMENT_METHOD", :credicard_visa).to_sym

      # Set a random transaction id
      order["id_transacao"] = Digest::MD5.hexdigest(Time.now.to_s)

      # Set note
      order["free"] = env["NOTE"].to_s
      
      
      

      # Retrieve index
      index = proc do |hash, value|
        if hash.respond_to?(:key)
          hash.key(value)
        else
          hash.index(value)
        end
      end

      # Set payment method and status
      order["tipo_pagamento"] = index[PagamentoDigital::Notification::PAYMENT_METHOD, payment_method]
      order["cod_status"] = index[PagamentoDigital::Notification::COD_STATUS, status]

      # Finally, ping the configured return URL      
      
      uri = URI.parse File.join(PagamentoDigital.config["base"], PagamentoDigital.config["return_to"])            
      response = Net::HTTP.post_form uri, order
      basedir = "#{Rails.root}/tmp/pagamento_digital"
      FileUtils.makedirs basedir
      tmp = File.open("#{basedir}/#{order['id_pedido']}.html",'w'){|out| out <<  PagamentoDigital::Utils.to_utf8(response.body)}
      puts "saida salva em #{tmp.path}"
        
      
    end
  end
end
