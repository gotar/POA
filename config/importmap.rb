# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "prismjs" # @1.30.0
pin "tailwindcss" # @4.1.18
pin "local-time" # @3.0.3
pin "hotkeys-js" # @4.0.0
