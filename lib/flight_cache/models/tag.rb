class FlightCache
  module Models
    class Tag < Model
      builder_class do
        api_name 'tags'
        api_type 'tag'

        def get(id: nil)
          build do |c|
            c.get(join(id)).body.data
          end
        end

        def list
          build_enum do |c|
            c.get(join).body.data
          end
        end
      end

      data_attribute :name
    end
  end
end
