module PagamentoDigital
  class DeveloperController < ::ActionController::Base
    skip_before_filter :verify_authenticity_token
    
    ORDERS_FILE = File.join(Rails.root, "tmp", "pagamento_digital-#{Rails.env}.yml")

    def create      
      # create the orders file if doesn't exist
      FileUtils.touch(ORDERS_FILE) unless File.exist?(ORDERS_FILE)

      # YAML caveat: if file is empty false is returned;
      # we need to set default to an empty hash in this case
      orders = YAML.load_file(ORDERS_FILE) || {}

      # add a new order, associating it with the order id
      orders[params[:id_pedido]] = params.except(:controller, :action, :only_path, :authenticity_token)

      # save the file
      File.open(ORDERS_FILE, "w+") do |file|
        file << orders.to_yaml
      end

      # redirect to the configuration url            
      redirect = PagamentoDigital.config["return_to"].gsub(/\/?(.*)/,"/\\1")      
      
      return redirect_to redirect + "?id_pedido=#{params[:id_pedido]}" 
    end
  end
end
