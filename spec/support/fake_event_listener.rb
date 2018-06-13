class FakeEventListener < Akasha::EventListener
  attr_reader :calls

  def initialize(fail_on: [])
    @fail_on = fail_on.map { |event_name| :"on_#{event_name}" }
    @calls = []
  end

  def method_missing(method, *)
    if method.to_s.start_with?('on_')
      raise "Triggered failure for #{method}" if @fail_on.include?(method)
      @calls << method
    else
      super
    end
  end

  def respond_to_missing?(method)
    method.to_s.start_with?('on_') || super
  end
end
