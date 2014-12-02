class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      atname = ('@'+name.to_s).to_sym
      define_method(name) { instance_variable_get(atname) }
      define_method((name.to_s + '=').to_sym) do |obj|
        instance_variable_set(atname, obj)
      end
    end
  end
end
