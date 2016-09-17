class Adhearsion::Twilio::Call
  attr_accessor :call, :to, :from

  def initialize(call)
    self.call = call
    set_call_variables!
  end

  def id
    call.id
  end

  private

  def set_call_variables!
    normalize_from!
    normalize_to!
  end

  def normalize_from!
    from = normalized_destination(call.from)
    if !destination_valid?(from)
      normalized_p_asserted_identity = normalized_destination(
        call.variables["variable_sip_p_asserted_identity"]
      )
      from = normalized_p_asserted_identity if destination_valid?(normalized_p_asserted_identity)
    end
    self.from = from
  end

  def normalize_to!
    self.to = normalized_destination(call.to)
  end

  def normalized_destination(raw_destination)
    # remove port if and scheme if given
    destination = raw_destination.gsub(/(\d+)\:\d+/, '\1').gsub(/^[a-z]+\:/, "") if raw_destination
    destination = Mail::Address.new(destination).local
    destination_valid?(destination) ? "+#{destination.gsub('+', '')}" : destination
  end

  def destination_valid?(raw_destination)
    raw_destination =~ /\A\+?\d+\z/
  end
end
