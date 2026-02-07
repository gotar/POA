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
pin "prismjs/components/prism-bash", to: "prismjs--components--prism-bash.js" # @1.30.0
pin "prismjs/components/prism-css", to: "prismjs--components--prism-css.js" # @1.30.0
pin "prismjs/components/prism-javascript", to: "prismjs--components--prism-javascript.js" # @1.30.0
pin "prismjs/components/prism-json", to: "prismjs--components--prism-json.js" # @1.30.0
pin "prismjs/components/prism-markup", to: "prismjs--components--prism-markup.js" # @1.30.0
pin "prismjs/components/prism-python", to: "prismjs--components--prism-python.js" # @1.30.0
pin "prismjs/components/prism-ruby", to: "prismjs--components--prism-ruby.js" # @1.30.0
pin "prismjs/components/prism-sql", to: "prismjs--components--prism-sql.js" # @1.30.0
pin "prismjs/components/prism-yaml", to: "prismjs--components--prism-yaml.js" # @1.30.0
