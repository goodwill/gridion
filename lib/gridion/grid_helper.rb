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


    end

    def grid(collection, options={}, &block)
      grid_binding=GridBinding.new

      with_output_buffer do
        grid_binding.header do |klass, collection, options={}|
          safe_concat("<table class=\"#{klass.name.downcase}\">")
          safe_concat("<tr>")
          (options[:columns]||klass.column_names).each do |col|
            safe_concat("<th>#{klass.human_attribute_name(col)}</th>")
          end
          safe_concat("<th>Actions</th>")
          safe_concat("</tr>")
        end

        grid_binding.row do  |klass, object, options={}|
          result =""
          result << "<tr id=\"#{klass.name}_#{object.id}\">"
          (options[:columns]||klass.column_names).each do |col|
            result << "<td>#{object.send(col)}</td>"
          end
          result << "<td>#{link_to 'Edit', [:edit, object ]}</td>"
          result << "<td>#{link_to 'Delete', object, :method=>:delete, :confirm=>'Are you sure?'}</td>"
          result << "</tr>"
          safe_concat(result)

        end

        grid_binding.footer do |klass, collection, options={}|
          safe_concat("</table>")
        end

      end

      content=with_output_buffer {block.call(grid_binding) } if block_given?

      # we need to initialize the procs in the helper context otherwise other helpers inside the proc object (e.g. link_to) wont work



      unless collection.blank?
        grid_binding.header.call(collection.first.class, collection, options)

        collection.each {|object| grid_binding.row.call(object.class, object, options) }

        grid_binding.footer.call(collection.first.class, collection, options)

      end

      return nil

    end




  end
end