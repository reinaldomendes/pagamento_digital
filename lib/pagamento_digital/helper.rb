module PagamentoDigital::Helper
  def pagamento_digital_form(order, options = {})
    options.reverse_merge!(:submit => "Pagar com pagamento digital")
    render :partial => "pagamento_digital/form", :locals => { :options => options, :order => order}
  end
end
