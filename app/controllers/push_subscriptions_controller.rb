# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  before_action :set_project

  # POST /projects/:project_id/push_subscription
  def create
    payload = params[:subscription] || {}
    endpoint = payload[:endpoint].to_s
    keys = payload[:keys] || {}
    p256dh = keys[:p256dh].to_s
    auth = keys[:auth].to_s

    if endpoint.blank? || p256dh.blank? || auth.blank?
      return render json: { ok: false, error: "invalid_subscription" }, status: :unprocessable_entity
    end

    sub = PushSubscription.find_or_initialize_by(endpoint: endpoint)
    sub.project_id = @project.id
    sub.p256dh = p256dh
    sub.auth = auth
    sub.user_agent = request.user_agent.to_s
    sub.save!

    render json: { ok: true }
  end

  # DELETE /projects/:project_id/push_subscription
  def destroy
    endpoint = params[:endpoint].to_s
    if endpoint.present?
      PushSubscription.where(endpoint: endpoint, project_id: @project.id).delete_all
    end

    render json: { ok: true }
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
