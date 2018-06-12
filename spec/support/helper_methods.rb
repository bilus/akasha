module HelperMethods
  def gensym(name)
    :"#{name}_#{SecureRandom.hex}"
  end
end
