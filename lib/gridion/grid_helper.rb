module Gridion
  module GridHelper

    class GridBinding

      def initialize
      end

      def header(&block)
        @header=block if block_given?
        @header

      end
      def row(&block)
        @row=block if block_given?
        @row
      end

      def footer(&block)
        @footer=block if block_given?
        @footer
      end
      
      def paginator(&block)
        @paginator=block if block_given?
        @paginator
      end

      def filter(&block)
        @filter=block if block_given?
        @filter
      end
        
    end

    def grid(collection, options={}, &block)
      grid_binding=GridBinding.new

      initialize_grid_binding(grid_binding)

      content=with_output_buffer {block.call(grid_binding) } if block_given?

      # we need to initialize the procs in the helper context otherwise other helpers inside the proc object (e.g. link_to) wont work

      
      options={:actions=>[:edit, :delete]}.merge(options).with_indifferent_access
      
      if %w(ol ul).include?(options[:table_tag])
        options[:table_header_tag]||="span"
        options[:table_row_tag]||="li"
        options[:table_cell_tag]||="span"
      end
      
      options[:table_tag]||="table"
      options[:table_header_tag]||="th"
      options[:table_header_wrapper_tag]="thead"
      options[:table_body_wrapper_tag]="tbody"
      options[:table_row_tag]||="tr"
      options[:table_cell_tag]||="td"
      options[:paginate]=true unless options.has_key?(:paginate)

      
      if collection.blank?
        if options[:render_empty_grid]
          grid_binding.header.call(options[:object_class], collection, options)
          grid_binding.filter.call(collection.first.class, collection, options) if grid_binding.filter.present?
          grid_binding.footer.call(options[:object_class], collection, options)
        end
      else
        grid_binding.header.call(collection.first.class, collection, options)
        grid_binding.filter.call(collection.first.class, collection, options) if grid_binding.filter.present?

        collection.each_with_index {|object, i| grid_binding.row.call(object.class, object, options.merge(:row_is_even=>i%2==1)) } #index starts from 0 
        
        if collection.respond_to?(:current_page) && defined?(Kaminari) # we assume only Kaminari is supported
          grid_binding.paginator.call(collection.first.class, collection, options) if collection.num_pages > 1 && options[:paginate]==true

        end
          
        
        grid_binding.footer.call(collection.first.class, collection, options)

      end

      return nil

    end
    def initialize_grid_binding(grid_binding)
      with_output_buffer do
        grid_binding.header do |klass, collection, options={}|
          table_tag = options[:table_tag]||"table"
          table_row_tag=options[:table_row_tag]||"tr"
          table_header_tag=options[:table_header_tag]||"th"
          table_header_wrapper_tag=options[:table_header_wrapper_tag]||"thead"
          table_body_wrapper_tag=options[:table_body_wrapper_tag]||"tbody"
          table_classes=[options[:class]].flatten.compact
          safe_concat("<#{table_tag} class=\"#{klass.name.downcase} #{table_classes.join(' ')}\">")
          
          columns=options[:columns]||klass.column_names
          safe_concat("<#{table_header_wrapper_tag}>")  if table_header_wrapper_tag.present?
          safe_concat("<#{table_row_tag} class=\"header\">")
          
          (columns).each do |col|
            col_label=klass.human_attribute_name(col)
            col_label = sort_link(options[:q], col, col_label) if defined?(:sort_link) && options.has_key?(:q) && options[:q].present?  
            safe_concat("<#{table_header_tag} class=\"header_cell #{col.to_s.parameterize.underscore}\">#{col_label}</#{table_header_tag}>")
          end
          safe_concat("<#{table_header_tag} class=\"actions\">Actions</#{table_header_tag}>") unless options[:actions].blank?
          safe_concat("<#{table_header_tag} class=\"children\"></#{table_header_tag}>") if options.has_key?(:children)
          safe_concat("</#{table_row_tag}>")
          safe_concat("</#{table_header_wrapper_tag}>")  if table_header_wrapper_tag.present?
          safe_concat("<#{table_body_wrapper_tag}>")  if table_body_wrapper_tag.present?
        end

        grid_binding.row do  |klass, object, options={}|
          table_tag = options[:table_tag]||"table"
          table_row_tag=options[:table_row_tag]||"tr"
          table_cell_tag=options[:table_cell_tag]||"td"
          
          object_list=
            if options.has_key?(:parent)
              ([options[:parent]] + [object]).flatten 
            else
              [object]
            end

          if options.has_key?(:namespace)
            namespaces=options[:namespace]
            object_list = ([namespaces] + object_list).flatten
          end
            
          result =""
          aux_columns={}
          aux_columns=options[:aux_columns].with_indifferent_access if options.has_key?(:aux_columns)
          
          formats=(options[:formats]||{}).with_indifferent_access
          actions=options[:actions]
          columns=options[:columns]||klass.column_names

          row_id="#{klass.name}_#{object.id}"
          
          result << "<#{table_row_tag} id=\"#{row_id}\" class=\"#{options[:row_is_even] ? 'even' : 'odd'}\">"
          (columns).each do |col|
            if aux_columns[col].present?
              value=aux_columns[col].call(object, options)
            else
              value=object.send(col)
              if formats.has_key?(col)
            
                if formats[col]==:currency
                  value=number_to_currency(value) 
                elsif formats[col].kind_of?(Hash)
                  if formats[col].has_key?(:date)
                    value=value.try(:to_date).try(:to_s, formats[col][:date])
                  elsif formats[col].has_key?(:datetime)
                    value=value.try(:to_s, formats[col][:datetime])
                  end
                elsif formats[col].kind_of?(Proc)
                  # use hook
                  value=formats[col].call(value)
                end
              end
            end
            result << "<#{table_cell_tag} class=\"#{col}\">#{value}</#{table_cell_tag}>"
          end
            

          if actions.present?
            result << "<#{table_cell_tag} class=\"actions\">"
            if actions.kind_of?(Proc)
              result << actions.call(object, options)
            elsif actions.kind_of?(Array)
              result << "#{link_to I18n.t("gridion.actions.show", default: "Show"), object_list, :class=>%w{action_link show}}" if actions.include?(:show)
              result << "#{link_to I18n.t("gridion.actions.edit", default: "Edit"), [:edit]+ object_list, :class=>%w{action_link edit}}" if actions.include?(:edit)
              result << "#{link_to I18n.t("gridion.actions.delete", default: "Delete"), object_list, :class=>%w{action_link delete}, :method=>:delete, :confirm=>'Are you sure?'}"  if actions.include?(:delete)
            elsif actions.kind_of?(Hash)
              result << "#{link_to I18n.t("gridion.actions.show", default: "Show"), object_list, {:class=>%w{action_link show}}.merge(actions[:show]||{})}" if actions.has_key?(:show)
              result << "#{link_to I18n.t("gridion.actions.edit", default: "Edit"), [:edit]+ object_list, {:class=>%w{action_link edit}}.merge(actions[:edit]||{})}" if actions.include?(:edit)
              result << "#{link_to I18n.t("gridion.actions.delete", default: "Delete"), object_list, {:class=>%w{action_link delete}, :method=>:delete, :confirm=>'Are you sure?'}.merge(actions[:delete]||{})}"  if actions.include?(:delete)
            end
            result << "</#{table_cell_tag}>"
          end
          
          if options.has_key?(:children)
            result << "<#{table_cell_tag} class=\"children\">"
            children_hash=
              if options[:children].kind_of?(Array)
                options[:children].each_with_object({}) {|child, h| h[child]=child.to_s.singularize.classify.constantize.model_name.human.pluralize }
              else
                options[:children].keys.each_with_object({}) {|child, h| h[child]=options[:children][child]||child.to_s.singularize.classify.constantize.model_name.human.pluralize} 
              end

            children_hash.keys.each do |child|
              label= children_hash[child]
              label||= child.to_s.singularize.classify.constantize.model_name.human.pluralize
              result << link_to(label, [namespaces, object, child].flatten, :class=>"child_link #{child.to_s}")
            end
          
            result << "</#{table_cell_tag}>"
          end

          
          result << "</#{table_row_tag}>"
          safe_concat(result)

        end

        grid_binding.paginator do |klass, collection, options|
          table_tag = options[:table_tag]
          table_row_tag=options[:table_row_tag]
          table_cell_tag=options[:table_cell_tag]
          
          colspans=(options[:columns]||klass.column_names).count + 1 + (options[:actions].blank? ? 0 : 1) #TODO: change this to number of action columns
          result = ""
          result << "<#{table_row_tag} class=\"paginator\">"
          result << "<#{table_cell_tag} colspan=\"#{colspans}\">"
          result << paginate(collection)
          result << "</#{table_cell_tag}>"
          result << "</#{table_row_tag}>"
          safe_concat(result)
        end

        grid_binding.footer do |klass, collection, options={}|
          table_tag = options[:table_tag]
          table_row_tag=options[:table_row_tag]
          table_cell_tag=options[:table_cell_tag]
          table_body_wrapper_tag=options[:table_body_wrapper_tag]
          safe_concat("</#{table_body_wrapper_tag}>")  if table_body_wrapper_tag.present?
          safe_concat("</#{table_tag}>")
        end
        

      end
    end



  end
end