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


    end

    def grid(collection, options={}, &block)
      grid_binding=GridBinding.new

      initialize_grid_binding(grid_binding)

      content=with_output_buffer {block.call(grid_binding) } if block_given?

      # we need to initialize the procs in the helper context otherwise other helpers inside the proc object (e.g. link_to) wont work

      
      options={:actions=>[:edit, :delete]}.merge(options).with_indifferent_access
      

      
      unless collection.blank?
        grid_binding.header.call(collection.first.class, collection, options)

        collection.each_with_index {|object, i| grid_binding.row.call(object.class, object, options.merge(:row_is_even=>i%2==1)) } #index starts from 0 
        
        grid_binding.paginator.call(collection.first.class, collection, options) if collection.respond_to?(:current_page) && defined?(Kaminari) # we assume only Kaminari is supported
          
        
        grid_binding.footer.call(collection.first.class, collection, options)

      end

      return nil

    end
    def initialize_grid_binding(grid_binding)
      with_output_buffer do
        grid_binding.header do |klass, collection, options={}|
          safe_concat("<table class=\"#{klass.name.downcase}\">")
          safe_concat("<tr>")
          
          (options[:columns]||klass.column_names).each do |col|
            col_label=klass.human_attribute_name(col)
            col_label = sort_link(options[:q], col, col_label) if defined?(:sort_link) && options.has_key?(:q)
            safe_concat("<th>#{col_label}</th>")
          end
          safe_concat("<th class=\"children\"></th>") if options.has_key?(:children)
          safe_concat("<th class=\"actions\">Actions</th>")
          safe_concat("</tr>")
        end

        grid_binding.row do  |klass, object, options={}|
          object_list=
            if options.has_key?(:parent)
              ([options[:parent]] + [object]).flatten 
            else
              [object]
            end
            puts "options: #{options.inspect}"
            
          result =""
          result << "<tr id=\"#{klass.name}_#{object.id}\" class=\"#{options[:row_is_even] ? 'even' : 'odd'}\">"
          formats=(options[:formats]||{}).with_indifferent_access
          (options[:columns]||klass.column_names).each do |col|
            value=object.send(col)
            if formats.has_key?(col)
              
              if formats[col]==:currency
                value=number_to_currency(value) 
              elsif formats[col].kind_of?(Hash)
                if formats[col].has_key?(:date)
                  value=value.try(:to_date).try(:to_s, formats[col][:date])
                end
              elsif formats[col].kind_of?(Proc)
                # use hook
                value=formats[col].call(value)
              end
              
            
            end
            result << "<td class=\"#{col}\">#{value}</td>"
          end
          actions=options[:actions]
          
          if options.has_key?(:children)
            result << "<td class=\"children\">"
            options[:children].each do |child|
              label= child.to_s.singularize.classify.constantize.model_name.human.pluralize
              result << link_to(label, [object, child], :class=>"child_link #{child.to_s}")
            end
            result << "</td>"
          end

          if actions.present?
          result << "<td class=\"actions\">"
            if actions.kind_of?(Proc)
              result << actions.call(object, options)
            elsif actions.kind_of?(Array)
              result << "#{link_to 'Show', object_list, :class=>%w{action_link show}}" if actions.include?(:show)
              result << "#{link_to 'Edit', [:edit]+ object_list, :class=>%w{action_link edit}}" if actions.include?(:edit)
              result << "#{link_to 'Delete', object_list, :class=>%w{action_link delete}, :method=>:delete, :confirm=>'Are you sure?'}"  if actions.include?(:delete)
            elsif actions.kind_of?(Hash)
              result << "#{link_to 'Show', object_list, {:class=>%w{action_link show}}.merge(actions[:show]||{})}" if actions.has_key?(:show)
              result << "#{link_to 'Edit', [:edit]+ object_list, {:class=>%w{action_link edit}}.merge(actions[:edit]||{})}" if actions.include?(:edit)
              result << "#{link_to 'Delete', object_list, {:class=>%w{action_link delete}, :method=>:delete, :confirm=>'Are you sure?'}.merge(actions[:delete]||{})}"  if actions.include?(:delete)
            end
            result << "</td>"
          end
          result << "</tr>"
          safe_concat(result)

        end

        grid_binding.paginator do |klass, collection, options|
          colspans=(options[:columns]||klass.column_names).count + 2 #TODO: change this to number of action columns
          result = ""
          result << "<tr class=\"footer\">"
          result << "<td colspan=\"#{colspans}\">"
          result << paginate(collection)
          result << "</td>"
          result << "</tr>"
          safe_concat(result)
        end

        grid_binding.footer do |klass, collection, options={}|
          safe_concat("</table>")
        end
        

      end
    end



  end
end