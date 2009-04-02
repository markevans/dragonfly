module Imagetastic
  module Controller

    module Macro
      # This is the method you use to make a model an imagetastic model, e.g.
      # class ImagetasticController < ApplicationController
      #   imagetastic_controller
      # end
      #
      def imagetastic_controller
        unless self.included_modules.member? Imagetastic::Controller::InstanceMethods
          extend  Imagetastic::Controller::ClassMethods
          include Imagetastic::Controller::InstanceMethods
        end
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      
      def show
        image = Imagetastic.model.find params[:id]
        respond_to do |format|
          format.jpg do
            data = Imagetastic.datastore.retrieve(image)
            process = params.delete(:process)
            logger.debug Imagetastic.image_processor.public_methods.sort.inspect
            image_data = Imagetastic.image_processor.send(process, data, params[:process_opts])
            send_data image_data, :type => 'image/jpeg', :disposition => 'inline'
          end
        end
      end
      
    end
    
  end
end
