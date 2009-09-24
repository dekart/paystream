I18n.load_path << Dir[File.join(File.dirname(__FILE__), "config", "locales", "*.yml")]

ActionController::Base.send(:include, Paystream::ControllerExtension)