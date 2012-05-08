module CustomMatchers
  def i_should_see_field(name, options = {})
    field = find_field(name)
    field.should_not be_nil
    case options[:type].to_s
    when nil
    when 'textarea'
      field.tag_name.should == type
    else
      field.tag_name.should == 'input'
      field['type'].should == options[:type].to_s
    end
    if options.has_key?(:value)
      field.value.should == options[:value]
    elsif options.has_key?(:checked)
      field['checked'].should == options[:checked]
    end
  end

end

RSpec.configuration.include CustomMatchers, :type => :request
