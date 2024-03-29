class AttrAccessorObject
  
  #Uses define_method to recreate the attr_reader and attr_writer methods
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method("#{name}") do
        self.instance_variable_get("@#{name}")
      end

      define_method("#{name}=") do |argument|
        self.instance_variable_set("@#{name}", argument)
      end

    end

  end
end
