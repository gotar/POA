Site::Container.register_provider :settings do
  prepare do
    require "site/types"
    require "ostruct"
  end

  start do
    settings = {
      import_dir: ENV.fetch("IMPORT_DIR", "./import"),
      export_dir: ENV.fetch("EXPORT_DIR", "./build"),
      assets_precompiled: ENV.fetch("ASSETS_PRECOMPILED", "false") == "true",
      assets_server_url: ENV["ASSETS_SERVER_URL"],
      site_name: ENV.fetch("SITE_NAME", "Polska Organizacja Aikido"),
      site_author: ENV.fetch("SITE_AUTHOR", "POA"),
      site_url: ENV.fetch("SITE_URL", "https://aikido-polska.eu")
    }

    register "settings", OpenStruct.new(settings)
  end
end
