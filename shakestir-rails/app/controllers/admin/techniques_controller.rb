module Admin
  class TechniquesController < ApplicationController
    private
      def scoped_resource
        resource_class.all
      end

      def find_resource(param)
        scoped_resource.find_by!(slug: param)
      end
  end
end
