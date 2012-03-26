module PagamentoDigital
  extend self

  # PagSeguro receives all invoices in this URL. If developer mode is enabled,
  # then the URL will be /pagseguro_developer/invoice
  GATEWAY_URL = "https://www.pagamentodigital.com.br/checkout/pay/"

  # Hold the config/pagseguro.yml contents
  @@config = nil

  # The path to the configuration file
  def config_file
    Rails.root.join("config/pagamento_digital.rb")
  end

  # Check if configuration file exists.
  def config?
    File.exist?(config_file)
  end

  # Load configuration file.
  def config
    raise MissingConfigurationError, "file not found on #{config_file.inspect}" unless config?

    # load file if is not loaded yet
    @@config ||= Configuration.new(true){eval File.open(PagamentoDigital.config_file).read}
    
    # raise an exception if the environment hasn't been set
    # or if file is empty
    if @@config == false || !@@config[Rails.env]
      raise MissingEnvironmentError, ":#{Rails.env} environment not set on #{config_file.inspect}"
    end
    # retrieve the environment settings
    #raise @@config[Rails.env].inspect
    @@config[Rails.env]
  end

  # The gateway URL will point to a local URL is
  # app is running in developer mode
  def gateway_url
    if developer?
      "/pagamento_digital_developer"
    else
      GATEWAY_URL
    end
  end
  
  
  

  # Reader for the `developer` configuration
  def developer?
    config? && config["developer"] == true
  end

  class MissingEnvironmentError < StandardError; end
  class MissingConfigurationError < StandardError; end
  
  class Configuration < HashWithIndifferentAccess
    ENVS = [:development,:test,:production]
    CONFIGS = [:authenticity_token,:return_to,:developer,:base,:email,:url_aviso]
    def initialize(is_environment=false,&block)
      @is_enviroment = is_environment
      @_eval = false
      #      unless environment
      #        instance_eval do
      #          undef :development,:test,:production          
      #        end
      #      else
      #        instance_eval do
      #          undef :authenticity_token,:return_to,:developer,:email 
      #        end        
      #      end      
      if block_given?         
        instance_eval(&block)          
      end   
      if @is_enviroment #merge global with especific
        ENVS.each do |env|
          CONFIGS.each do |config|
            self[env][config] ||= self[config] if self[env] && self[config]            
          end
          self[env].instance_variable_set("@_eval".to_sym,true)
        end        
      end
      
    end
    
    ENVS.each do |env|
      define_method "#{env}".to_sym do|&blk|                        
        #raise "not valid " unless @is_enviroment
        self[env] = Configuration.new(false,&blk)
      end
      self
    end
    
    CONFIGS.each do |method|
      define_method method do |*args|
        #raise "not valid " if @is_enviroment
        if args.length == 1#atribuicao        
          self[method] = args.first
          self
        elsif args.length > 1
          self[method] = args
          self
        else args.length == 0
          self[method]
        end              
      end      
    end
    
    def []key
      ret = super key
      if @_eval
        if ret.is_a?(Proc) 
          ret = ret.call()#só troca quando estiver no config
        end
      end
      ret
    end
    
    
  end
end
