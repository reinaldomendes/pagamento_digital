module PagamentoDigital
  module ActionController
    private
    def pagamento_digital_notification(token = nil, &block)
      return unless request.post?
      notification = PagamentoDigital::Notification.new(params, token)
      yield notification 
      notification.valid?(nil)
    end
  end
end
