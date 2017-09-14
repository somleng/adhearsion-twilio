module MockCall
  def call_params
    @call_params ||= {
      :to => "85512456869",
      :from => "1000",
      :id => SecureRandom.uuid,
      :variables => {
        "variable_sip_from_host" => "192.168.1.1",
        "variable_sip_to_host" => "192.168.2.1",
        "variable_sip_network_ip" => "192.168.3.1"
      }
    }
  end

  def mock_call
    @mock_call ||= instance_double(
      Adhearsion::Call,
      :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
      :to => "#{call_params[:to]}@192.168.42.234",
      :id => call_params[:id],
      :variables => call_params[:variables]
    )
  end
end
