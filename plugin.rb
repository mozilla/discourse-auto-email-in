# name: auto-email-in
# about: Discourse plugin which automatically sets category email-in addresses based on their slug
# version: 1.2.1
# authors: Leo McArdle
# url: https://github.com/mozilla/discourse-auto-email-in

enabled_site_setting :auto_email_in_enabled

def update_all_categories
  ::Category.all.each do |category|
    category.update_email_in
  end
end

after_initialize do
  require_dependency 'category'
  class ::Category
    after_save do
      update_email_in
      update_subcategory_email_in
    end

    register_custom_field_type("auto_email_in_disabled", :boolean)

    def update_email_in
      return unless SiteSetting.auto_email_in_enabled
      return if self.custom_fields["auto_email_in_disabled"]

      old_email_in = self.email_in
      divider = SiteSetting.auto_email_in_divider
      domain = SiteSetting.auto_email_in_domain

      if self.parent_category
        return if self.parent_category.custom_fields["auto_email_in_disabled"]
        new_email_in = "#{self.parent_category.slug}#{divider}#{self.slug}@#{domain}"
      else
        new_email_in = "#{self.slug}@#{domain}"
      end

      if SiteSetting.auto_email_in_append && !old_email_in.blank?
        update_column(:email_in, (old_email_in.split("|") - [new_email_in] + [new_email_in]).join("|"))
      else
        update_column(:email_in, new_email_in) unless new_email_in == old_email_in
      end
    end

    def update_subcategory_email_in
      if self.subcategories
        self.subcategories.each do |subcategory|
          subcategory.update_email_in
        end
      end
    end
  end

  if SiteSetting.auto_email_in_enabled
    update_all_categories
  end
end

DiscourseEvent.on(:site_setting_changed) do |name|
  if name == :auto_email_in_enabled or name == :auto_email_in_divider or name == :auto_email_in_domain
    update_all_categories
  end
end
