# name: auto-email-in
# about: Discourse plugin which automatically sets category email-in addresses based on their slug
# version: 1.0.0
# authors: Leo McArdle

enabled_site_setting :auto_email_in_enabled

after_initialize do
  require_dependency 'category'
  class ::Category
    after_save do
      update_email_in
      update_subcategory_email_in
    end

    def update_email_in
      return unless SiteSetting.auto_email_in_enabled

      old_email_in = self.email_in
      divider = SiteSetting.auto_email_in_divider
      domain = SiteSetting.auto_email_in_domain

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
end

DiscourseEvent.on(:site_setting_changed) do |name|
  if name == :auto_email_in_enabled or name == :auto_email_in_divider or name == :auto_email_in_domain
    Category.all.each do |category|
      category.update_email_in
    end
  end
end
