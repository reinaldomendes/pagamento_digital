module PagamentoDigital
  class Order
    # Map all billing attributes that will be added as form inputs.
    BILLING_MAPPING = {
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

    # The list of products added to the order
    attr_accessor :products

    # The billing info that will be sent to PagamentoDigital.
    attr_accessor :billing
    
    
    def frete= value
      @frete = convert_unit(value, 100)
    end
    def frete
      @frete
    end
    
    

    # Define the shipping type.
    # Can be EN (PAC) or SD (Sedex)
    #attr_accessor :tipo_frete

    def initialize(order_id = nil)
      reset!
      self.id = order_id
      self.billing = {}
    end

    # Set the order identifier. Should be a unique
    # value to identify this order on your own application
    def id=(identifier)
      @id = identifier
    end

    # Get the order identifier
    def id
      @id
    end

    # Remove all products from this order
    def reset!
      @products = []
    end

    # Add a new product to the PagamentoDigital order
    # The allowed values are:
    # - weight (Optional. If float, will be multiplied by 1000g)
    # - shipping (Optional. If float, will be multiplied by 100 cents)
    # - quantity (Optional. Defaults to 1)
    # - price (Required. If float, will be multiplied by 100 cents)
    # - description (Required. Identifies the product)
    # - id (Required. Should match the product on your database)
    # - fees (Optional. If float, will be multiplied by 100 cents)
    def <<(options)
      options = {
        :valor => nil,                
        :qtde => 1        
      }.merge(options)

      # convert shipping to cents
      #options[:frete] = convert_unit(options[:frete], 100)
      # convert price to cents
      options[:preco] = convert_unit(options[:preco], 100)
      products.push(options)
    end

    def add(options)
      self << options
    end

    private
    def convert_unit(number, unit)
      number = number.to_f.round(unit) rescue 0
      number
    end
  end
end
