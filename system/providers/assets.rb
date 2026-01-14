Site::Container.register_provider :assets do
  prepare do
    require "site/assets"
  end

  start do
    settings = target[:settings]

    assets =
      if settings.assets_precompiled
        Site::Assets::Precompiled.new(settings.export_dir)
      else
        Site::Assets::Served.new(settings.assets_server_url)
      end

    register "assets", assets
  end
end
