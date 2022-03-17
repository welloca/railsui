require "open-uri"
require "thor"

module Railsui
  class Configuration
    include ActiveModel::Model
    include Thor::Actions
     # Attributes
    attr_accessor :application_name, :css_framework, :primary_color, :secondary_color, :tertiary_color, :font_family, :about, :pricing, :blog, :theme

    def initialize(options = {})
      assign_attributes(options)
      self.application_name ||= "Rails UI"
      self.css_framework ||= ""
      self.theme ||= ""
      self.primary_color ||= "4338CA"
      self.secondary_color ||= "FF8C69"
      self.tertiary_color ||= "333333"
      self.font_family ||= "Inter, sans-serif"
      self.about ||= false
      self.pricing ||= false
      self.blog ||= false
    end


    def self.load!
      if File.exist?(config_path)
        config = Psych.safe_load_file(config_path, permitted_classes: [Hash, Railsui::Configuration])
        return config if config.is_a?(Railsui::Configuration)
        new(config)
      else
        new
      end
    end

    def self.config_path
      Rails.root.join("config", "railsui.yml")
    end

    def about=(value)
      @about = ActiveModel::Type::Boolean.new.cast(value)
    end

    def about?
      @about.nil? ? false : ActiveModel::Type::Boolean.new.cast(@about)
    end

    def pricing=(value)
      @pricing = ActiveModel::Type::Boolean.new.cast(value)
    end

    def pricing?
      @pricing.nil? ? false : ActiveModel::Type::Boolean.new.cast(@pricing)
    end

    def blog=(value)
      @blog = ActiveModel::Type::Boolean.new.cast(value)
    end

    def blog?
      @blog.nil? ? false : ActiveModel::Type::Boolean.new.cast(@blog)
    end

    def save
      # Creates config/railsui.yml
      File.write(self.class.config_path, to_yaml)

      # Change the Rails UI config to the latest version
      Railsui.config = self

      # Install and configure framework of choice
      set_framework unless Railsui.framework_installed?

      if Railsui.config.blog?
        create_blog
      end

      # Install any static pages
      unless Railsui.config.about?
        create_about_page
      end

      unless Railsui.config.pricing?
        create_pricing_page
      end
    end

    def create_blog
      # See lib/templates/erb/scaffold <- Defaults
      # Need conditional logic per framework + theme
      # How?
      # Railsui.run_command "rails generate scaffold Post -framework #{Railsui.config.css_framework} -theme #{Railsui.config.theme}"
    end

    private

    def update_framework
      Railsui.config.css_framework = self.css_framework
      Railsui.config.theme = self.theme
    end


    def create_about_page
      Railsui.run_command "rails generate railsui:static about -c #{chosen_framework}" if Railsui.config.about?
    end

    def create_pricing_page
      Railsui.run_command "rails generate railsui:static pricing -c #{chosen_framework}" if Railsui.config.pricing?
    end

    def set_framework
      case Railsui.config.css_framework
      when Railsui::Default::BOOTSTRAP
        Railsui.run_command "rails railsui:framework:install:bootstrap"
      when Railsui::Default::TAILWIND_CSS
        Railsui.run_command "rails railsui:framework:install:tailwind"
      when Railsui::Default::BULMA
        Railsui.run_command "bundle add sass-rails"
        Railsui.run_command "rails railsui:framework:install:bulma"
      else
        # no framework => None
      end
    end

    def copy_template(filename)
      # Safely copy template, so we don't blow away any customizations you made
      unless File.exist?(Rails.root.join(filename))
        FileUtils.cp template_path(filename), Rails.root.join(filename)
      end
    end

    def template_path(filename)
      Rails.root.join("lib/templates", filename)
    end

  end
end
