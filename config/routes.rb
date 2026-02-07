# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Root path - redirect to first project or show onboarding
  root "projects#index"

  # Projects (sessions)
  resources :projects, only: %i[index show create update destroy] do
    member do
      post :archive
      post :unarchive
    end

    collection do
      delete :bulk_delete
      post :bulk_archive
      post :bulk_unarchive
    end
    # Conversations within a project
    resources :conversations, only: %i[index show create destroy] do
      member do
        post :clear_messages
        get :export
      end

      # Messages within a conversation
      resources :messages, only: %i[create] do
        # Attachments for messages
        resources :attachments, only: %i[create destroy]
      end

      # Streaming endpoint
      post :stream, to: "messages#stream", on: :member
    end

    # TODOs within a project
    resources :todos, only: %i[index create update destroy] do
      member do
        post :start
        post :complete
        post :cancel
        post :reopen
      end
    end

    # Notes within a project
    resources :notes, only: %i[index show create update destroy]

    # Knowledge bases within a project
    resources :knowledge_bases, only: %i[index show new create edit update destroy] do
      # Attachments for knowledge bases
      resources :attachments, only: %i[create destroy]
    end

    # Scheduled jobs within a project
    resources :scheduled_jobs, only: %i[index show new create edit update destroy] do
      member do
        post :run_now
        post :toggle
      end
    end

    # Project context for AI
    get :context, on: :member
  end

  # PWA routes (using custom manifest and service worker)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
