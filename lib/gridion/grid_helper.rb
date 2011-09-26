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



      unless collection.blank?
        grid_binding.header.call(collection.first.class, collection, options)

        collection.each {|object| grid_binding.row.call(object.class, object, options) }
        
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
          safe_concat("<th>Actions</th>")
          safe_concat("</tr>")
        end

        grid_binding.row do  |klass, object, options={}|
          object_list=
            if options.has_key?(:parent)
              (options[:parent] + [object]).flatten 
            else
              [object]
            end
            
          result =""
          result << "<tr id=\"#{klass.name}_#{object.id}\">"
          (options[:columns]||klass.column_names).each do |col|
            result << "<td>#{object.send(col)}</td>"
          end
          result << "<td>#{link_to 'Edit', [:edit]+ object_list}</td>"
          result << "<td>#{link_to 'Delete', object_list, :method=>:delete, :confirm=>'Are you sure?'}</td>"
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