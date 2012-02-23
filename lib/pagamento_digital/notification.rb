# encoding: utf-8


module PagamentoDigital
  class Notification
    API_URL = "https://www.pagamentodigital.com.br/checkout/verify/"

    # Map all the attributes from PagamentoDigital.
    #
    MAPPING = {
      :tipo_pagamento   => "tipo_pagamento",
      :id_pedido         => "id_pedido",
      :processed_at     => "data_transacao",
      :status           => "status",
      :cod_status       => "cod_status",
      :id_transacao     => "id_transacao",
      :valor_original   => 'valor_original',
      :parcelas         => 'parcelas',
      :valor_loja       => 'valor_loja',
      :valor_total      => 'valor_total',
      :frete            => 'frete',
      :tipo_frete       => 'tipo_frete',
      :informacoes_loja => 'informacoes_loja',
      :free             => 'free',
      :email_vendedor   => 'email_vendedor',
    }

    
    COD_STATUS ={
      '0' => :pendente,
      '1' => :aprovada,
      '2' => :cancelada
    }
      
    
   

    #    # Map payment method from PagamentoDigital.
    #    #
    PAYMENT_METHOD = {
      "Boleto Bancário"                       => :boleto,
      "Visa"                                  => :credicard_visa,
      "Mastercard"                            => :credicard_mastercard,
      "American Express"                      => :credicard_amex,
      "Diners"                                => :credicard_diners,
      "Aura"                                  => :credicard_aura,
      "HiperCard"                             => :credicard_hiper,
      "Transferência OnLine Banco do Brasil"  => :trans_bb,
      "Transferência OnLine Bradesco"         => :trans_bradesco,
      "Transferência OnLine Itaú"             => :trans_itau,
      "Transferência OnLine Banrisul"         => :trans_banrisul,
      "Transferência OnLine HSBC"             => :trans_hsbc,      
      
    }

    # The Rails params hash.
    #
    attr_accessor :params

    # Expects the params object from the current request.
    # PagamentoDigital will send POST with ISO-8859-1 encoded data,
    # so we need to normalize it to UTF-8.
    #
    def initialize(params, token = nil)
      @token = token
      @params = PagamentoDigital.developer? ? params : normalize(params)
    end

    # Normalize the specified hash converting all data to UTF-8.
    #
    def normalize(hash)
      return hash
      #      each_value(hash) do |value|
      #        Utils.to_utf8(value)
      #      end
    end

    # Denormalize the specified hash converting all data to ISO-8859-1.
    #
    def denormalize(hash)
      return hash
      #            each_value(hash) do |value|
      #              Utils.to_iso8859(value)
      #            end
    end

    # Return a list of produtos sent by PagamentoDigital.
    # The values will be normalized
    # (e.g. currencies will be converted to cents, quantity will be an integer)
    #
    def produtos
      @produtos ||= begin
        items = []
        i = 0;
        loop do
          i += 1
          break if params["produto_qtde_#{i}"].blank?
          items << {
            :id          => params["produto_codigo_#{i}"],
            :descricao => params["produto_descricao_#{i}"],
            :qtde    => params["produto_qtde_#{i}"].to_i,
            :preco       => to_price(params["produto_valor_#{i}"]),
            :extra     => params["produto_extra_#{i}"]
          }
        end

        items
      end
    end
    
    def cliente
      @cliente ||= params.inject({}){|ret,args|
        key,value = args.first,args.second        
        ret[key.gsub('cliente_','')] = value if key =~ /^cliente_.*$/
        ret
      }
    end
    

    # Return the shipping fee.
    # Will be converted to a float number.
    #
    def frete
      to_price mapping_for(:frete)
    end

    # Return the order status.
    # Will be mapped to the STATUS constant.
    #
    def status
      @status ||= COD_STATUS[mapping_for(:cod_status).to_s]
    end
    def aprovada?
      status == :aprovada
    end
    def cancelada?
      status == :cancelada
    end
    def pendente?
      status == :pendente
    end
    

    # Return the payment method.
    # Will be mapped to the PAYMENT_METHOD constant.
    #
    def payment_method
      @payment_method ||= PAYMENT_METHOD[mapping_for()]
    end

    # Parse the processing date to a Ruby object.
    #
    def processed_at
      @processed_at ||= begin
        groups = *mapping_for(:processed_at).match(/(\d{2})\/(\d{2})\/(\d{4}) ([\d:]+)/sm)
        Time.parse("#{groups[3]}-#{groups[2]}-#{groups[1]} #{groups[4]}")
      end
    end
    

    def method_missing(method, *args)
      return mapping_for(method) if MAPPING[method]
      super
    end

    def respond_to?(method, include_private = false)
      return true if MAPPING[method]
      super
    end

    # A wrapper to the params hash,
    # sanitizing the return to symbols.
    #
    def mapping_for(name)
      params[MAPPING[name]]
    end

    # Cache the validation.
    # To bypass the cache, just provide an argument that is evaluated as true.
    #
    #   invoice.valid?
    #   invoice.valid?(:nocache)
    #
    def valid?(force=false)
      @valid = nil if force
      @valid = validates? if @valid.nil?
      @valid
    end

    # Return all useful properties in a single hash.
    #
    def to_hash
      MAPPING.inject({}) do |buffer, (name,value)|
        buffer.merge(name => __send__(name))
      end
    end

    private
    def each_value(hash, &blk) # :nodoc:
      hash.each do |key, value|
        if value.kind_of?(Hash)
          hash[key] = each_value(value, &blk)
        else
          hash[key] = blk.call value
        end
      end

      hash
    end

    # Convert amount format to float.
    #
    def to_price(amount)
      amount = "0#{amount}" if amount =~ /^\,/
      amount.to_s.to_f
    end
    
    

    # Check if the provided data is valid by requesting the
    # confirmation API url. The request will always be valid while running in
    # developer mode.
    #
    def validates?      
      return true if PagamentoDigital.developer?        
      # include the params to validate our request
      
      request_params = {
        :transacao => params[:id_transacao],
        :cod_status => params[:cod_status],
        :valor_original => params[:valor_original],
        :valor_loja => params[:valor_loja],          
        :token => @token || PagamentoDigital.config["authenticity_token"]
      }
        
      
      #send form by ruby
      response = Net::HTTP.post_form(URI.parse(API_URL),denormalize(request_params)   )      
      
      (response.body =~ /VERIFICADO/) != nil
        
    end
  end
end



