# name: auto-email-in
# about: Discourse plugin which automatically sets category email-in addresses based on their slug
# version: 0.0.1
# authors: Leo McArdle

enabled_site_setting :auto_email_in_enabled

after_initialize do
  require_dependency 'category'
  class ::Category
    after_save do
      update_email_in
      update_subcategory_email_in
    end

    def update_email_in(site_setting=false)
      if site_setting and site_setting.name == 'auto_email_in_enabled'
        return unless site_setting.value == 't'
      else
        return unless SiteSetting.auto_email_in_enabled
      end

      old_email_in = self.email_in
      divider = SiteSetting.auto_email_in_divider
      domain = SiteSetting.auto_email_in_domain

      if site_setting
        if site_setting.name == 'auto_email_in_divider'
          divider = site_setting.value
        elsif site_setting.name == 'auto_email_in_domain'
          domain = site_setting.value
        end
      end

      if self.parent_category
        new_email_in = "#{self.parent_category.slug}#{divider}#{self.slug}@#{domain}"
      else
        new_email_in = "#{self.slug}@#{domain}"
      end

      update_column(:email_in, new_email_in) unless new_email_in == old_email_in
    end

    def update_subcategory_email_in
      if self.subcategories
        self.subcategories.each do |subcategory|
          subcategory.update_email_in
        end
      end
    end
  end

  Category.all.each do |category|
    category.update_email_in
  end
end

DiscourseEvent.on(:site_setting_saved) do |site_setting|
  name = site_setting.name
  if name == 'auto_email_in_enabled' or name == 'auto_email_in_divider' or name == 'auto_email_in_domain'
    Category.all.each do |category|
      category.update_email_in(site_setting)
    end
  end
end
