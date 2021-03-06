class DynamicDatum < ActiveRecord::Base
  attr_protected :created_at, :updated_at

  DYNAMIC_ATTRIBUTE_PREFIX = 'dyn_'
  
  has_dynamic_attributes :dynamic_attribute_prefix => DYNAMIC_ATTRIBUTE_PREFIX, :destroy_dynamic_attribute_for_nil => false

  belongs_to :reference, :polymorphic => true
  belongs_to :created_with_form, :class_name => "DynamicForm"
  belongs_to :updated_with_form, :class_name => "DynamicForm"
  belongs_to :created_by, :class_name => "User"
  belongs_to :updated_by, :class_name => "User"
  
  def dynamic_attributes_without_prefix
    attrs = {}
    self.dynamic_attributes.each do |k,v|
      attrs[k[DYNAMIC_ATTRIBUTE_PREFIX.length..(k.length)]] = v
    end

    attrs
  end

  def dynamic_attributes_with_related_data(related_fields=[], use_label=false)
    key = (use_label ? :fieldLabel : :name)
    data = sorted_dynamic_attributes(:use_label => use_label)
    related_fields.each do |r|
      data.each do |k,v|
        if k == r[key]
          if r[:xtype] == 'related_combobox'
            d = r[:displayField]
            t = nil
          else
            #related_searchbox
            d = r[:display_fields].split(',')
            t = r[:display_template]
          end
          data[k] = DynamicDatum.related_data_value(r[:extraParams]['model'], v, d, t)
        end
      end
    end

    data
  end

  #column can be a string or array of strings
  def self.related_data_value(model, id, column, template=nil)
    if column.is_a?(String)
      return model.camelize.constantize.find(id).send(column) rescue nil
    else
      final_display = template
      column.each do |c|
        value = model.camelize.constantize.find(id).send(c) rescue nil
        final_display = final_display.gsub(c, value)
      end
      return final_display.gsub('{','').gsub('}','')
    end
  end

  # we cannot assume that dynamic attributes are stored in order in the database as this is often not the case
  # this method will sort them according to the order of the fields in the form definition
  # method returns an ordered hash
  # options = {:with_prefix => false, :use_label => false, :all => false}
  # :with_prefix = false will remove the dyn_ from the attribute key
  # if :with_prefix is false, you may choose to use the fieldLabel as the hash key by setting :use_label = true 
  # :use_label is useful displaying data on a view screen or formatting an email
  # :all = false will only return attributes that are in the form definition
  # :all = true will return all attributes with those not in the form definition last
  # you can set :all = true and :use_label = true, but attributes not in definition will use key.titleize
  # if for some reason a form cannot be found, sorting will not be attempted
  def sorted_dynamic_attributes(options={})
    options[:with_prefix] = false if options[:with_prefix].nil?
    options[:use_label] = false if options[:use_label].nil?
    options[:all] = true if options[:all].nil?

    form = self.updated_with_form !self.updated_with_form.nil?
    form = self.created_with_form if form.nil? and !self.created_with_form.nil?
    form = DynamicForm.get_form(self.reference_type) if form.nil?
    
    unless form.nil?
      fields = form.definition_object

      fields_and_values = {}
      if options[:with_prefix]
        fields.each do |f|
          k = DYNAMIC_ATTRIBUTE_PREFIX + f[:name]
          next if k == DYNAMIC_ATTRIBUTE_PREFIX + 'file' # we dont want to show file upload fields
          fields_and_values[k] = {}
          fields_and_values[k][:value] = self.dynamic_attributes[k]
          fields_and_values[k][:xtype] = f[:xtype]
        end
      else        
        fields.each do |f|
          k = f[:name]
          next if k == 'file' # we dont want to show file upload fields
          fields_and_values[k] = {}
          fields_and_values[k][:value] = self.dynamic_attributes_without_prefix[k]
          fields_and_values[k][:xtype] = f[:xtype]
          fields_and_values[k][:fieldLabel] = f[:fieldLabel] if options[:use_label]
        end
      end

      # although we try and save integers as integers, we ensure here they are integers so that combobox value is selected
      related_fields = form.related_fields
      if related_fields.length > 0
        related_fields.collect{|f| f[:name]}.each do |k|
          k = DYNAMIC_ATTRIBUTE_PREFIX+k if options[:with_prefix]
          fields_and_values[k][:value] = fields_and_values[k][:value].to_i 
        end
      end
      
      sorted = {}
      i=0
      fields_and_values.each do |key, field|        
        if options[:with_prefix]
          sorted[key] = field[:value]
        else
          index = (options[:use_label] ? field[:fieldLabel] : key)
          sorted[index] = field[:value]
        end
        i += 1
      end
      
      if options[:all]
        # append attributes not in definition
        attrs = (options[:with_prefix] ? self.dynamic_attributes : self.dynamic_attributes_without_prefix)
        keys = fields_and_values.collect{|k,v| k}

        i=0
        sorted.each do |k,v|
          index = (options[:use_label] ? keys[i] : k)
          attrs.delete(index)
          i += 1
        end

        attrs.each do |k,v|
          if options[:with_prefix]
            sorted[k] = self.dynamic_attributes[k]
          else
            index = (options[:use_label] ? k.titleize : k)
            sorted[index] = self.dynamic_attributes_without_prefix[k]
          end
        end
      end

      return sorted
    else
      return (options[:with_prefix] ? self.dynamic_attributes : self.dynamic_attributes_without_prefix)
    end
  end
end