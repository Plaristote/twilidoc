module HashInitialize
  def init_attrs attrs = {}
    attrs.each do |key, value|
      self.send "#{key}=", value
    end
    self
  end
end
