module MockCall
  def call_params
    @call_params ||= {
      :to => "85512456869",
      :from => "1000",
      :id => "5250692c-3db4-11e2-99cd-2f3f1cd7994c"
    }
  end

  def mock_call
    @mock_call ||= double(
      Adhearsion::Call,
      :from => "Extension 1000 <#{call_params[:from]}@192.168.42.234>",
      :to => "#{call_params[:to]}@192.168.42.234",
      :id => call_params[:id]
    )
  end
end
