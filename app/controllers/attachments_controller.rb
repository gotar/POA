class AttachmentsController < ApplicationController
  def create
    # Find the attachable object (message or knowledge_base)
    attachable = find_attachable

    # Create attachment
    @attachment = attachable.attachments.build(attachment_params)

    if @attachment.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("attachment_form_#{attachable.id}",
            partial: "attachments/form", locals: { attachable: attachable })
        end
        format.html { redirect_back fallback_location: root_path, notice: "File uploaded successfully" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("attachment_form_#{attachable.id}",
            partial: "attachments/form", locals: { attachable: attachable })
        end
        format.html { redirect_back fallback_location: root_path, alert: "Failed to upload file" }
      end
    end
  end

  def destroy
    @attachment = Attachment.find(params[:id])

    # Check permissions - user should own the attachable's project
    if authorized_to_modify?(@attachment.attachable)
      @attachment.destroy
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.remove("attachment_#{@attachment.id}")
        end
        format.html { redirect_back fallback_location: root_path, notice: "File deleted successfully" }
      end
    else
      head :forbidden
    end
  end

  private

  def attachment_params
    params.require(:attachment).permit(:name, :file)
  end

  def find_attachable
    if params[:message_id]
      Message.find(params[:message_id])
    elsif params[:knowledge_base_id]
      KnowledgeBase.find(params[:knowledge_base_id])
    else
      raise ActiveRecord::RecordNotFound, "Attachable not found"
    end
  end

  def authorized_to_modify?(attachable)
    # For now, allow all modifications since there's no authentication
    # In a real app, you'd check if current_user owns the attachable's project
    true
  end
end
