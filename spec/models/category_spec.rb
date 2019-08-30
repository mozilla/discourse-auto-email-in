require "rails_helper"

describe Category do
  let(:parent) { Fabricate(:category, slug: "test-parent") }
  let(:child) { Fabricate(:category, slug: "test-child", parent_category: parent) }

  context "when auto-email-in isn't enabled" do
    it "doesn't set email-in on new category" do
      expect(parent.email_in).to be_blank
    end

    it "allows email-in to be updated normally" do
      parent.email_in = "test@example.com"
      parent.save
      expect(parent.email_in).to eq "test@example.com"
    end

    it "updates emails-in when auto_email_in_enabled is set to true" do
      expect(parent.email_in).to be_blank
      SiteSetting.auto_email_in_enabled = true
      expect(parent.reload.email_in).to eq "test-parent@example.com"
    end
  end

  context "when auto-email-in is enabled" do
    before { SiteSetting.auto_email_in_enabled = true }

    it "sets email-in on new category" do
      expect(parent.email_in).to eq "test-parent@example.com"
    end

    it "sets email-in on new subcategory" do
      expect(child.email_in).to eq "test-parent+test-child@example.com"
    end

    it "updates parent and child emails-in when the parent category is updated" do
      parent.slug = "new-test-parent"
      parent.save
      expect(parent.email_in).to eq "new-test-parent@example.com"
      expect(child.email_in).to eq "new-test-parent+test-child@example.com"
    end

    it "updates emails-in when auto_email_in_domain setting is changed" do
      SiteSetting.auto_email_in_domain = "test.example.com"
      expect(parent.email_in).to eq "test-parent@test.example.com"
      expect(child.email_in).to eq "test-parent+test-child@test.example.com"
    end

    it "updates emails-in when auto_email_in_divider setting is changed" do
      SiteSetting.auto_email_in_divider = "."
      expect(child.email_in).to eq "test-parent.test-child@example.com"
    end

    it "doesn't allow email-in to be updated normally" do
      parent.email_in = "test@example.com"
      parent.save
      expect(parent.email_in).to eq "test-parent@example.com"
    end

  end
end
