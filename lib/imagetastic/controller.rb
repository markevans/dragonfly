module Imagetastic
  class Controller

    def show
      image = Imagetastic.model_class.find params[:id]
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
