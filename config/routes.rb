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
    resources :conversations, only: %i[index show create update destroy] do
      member do
        patch :set_model
        get :available_models
      end
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

    # Web Push subscriptions (per project)
    resource :push_subscription, only: %i[create destroy]

    # Scheduled jobs within a project
    resources :scheduled_jobs, only: %i[index show new create edit update destroy] do
      member do
        post :run_now
        post :toggle
      end
    end

    # Personal knowledge (filesystem + QMD)
    get :personal_knowledge, to: "personal_knowledge#index"
    get "personal_knowledge/search", to: "personal_knowledge#search", as: :personal_knowledge_search
    post "personal_knowledge/reindex", to: "personal_knowledge#reindex", as: :personal_knowledge_reindex
    post "personal_knowledge/remember", to: "personal_knowledge#remember", as: :personal_knowledge_remember
    post "personal_knowledge/topics", to: "personal_knowledge#create_topic", as: :personal_knowledge_topics
    get "personal_knowledge/note", to: "personal_knowledge#show", as: :personal_knowledge_note
    get "personal_knowledge/note/edit", to: "personal_knowledge#edit", as: :personal_knowledge_edit_note
    patch "personal_knowledge/note", to: "personal_knowledge#update", as: :personal_knowledge_update_note

    # Project context for AI
    get :context, on: :member

    # Models from pi (for pickers)
    get :available_models, on: :member
  end

  # Global Personal Knowledge (shared across projects)
  get "/knowledge", to: "knowledge#index", as: :knowledge
  get "/knowledge/search", to: "knowledge#search", as: :knowledge_search
  post "/knowledge/reindex", to: "knowledge#reindex", as: :knowledge_reindex
  post "/knowledge/topics", to: "knowledge#create_topic", as: :knowledge_topics
  post "/knowledge/remember", to: "knowledge#remember", as: :knowledge_remember
  get "/knowledge/note", to: "knowledge#show", as: :knowledge_note
  get "/knowledge/note/edit", to: "knowledge#edit", as: :knowledge_edit_note
  patch "/knowledge/note", to: "knowledge#update", as: :knowledge_update_note

  # Monitoring
  get "/monitoring", to: "monitoring#index", as: :monitoring
  get "/monitoring/jobs", to: "monitoring#jobs", as: :monitoring_jobs

  # PWA routes (using custom manifest and service worker)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
