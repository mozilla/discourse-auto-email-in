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

    it "appends emails-in when auto_email_in_append is set to true and then auto_email_in_enabled is set to true" do
      parent.email_in = "some-old-email-in@example.com"
      parent.save
      SiteSetting.auto_email_in_append = true
      SiteSetting.auto_email_in_enabled = true
      expect(parent.reload.email_in).to eq "some-old-email-in@example.com|test-parent@example.com"
    end
  end

  context "when auto-email-in is enabled" do
    before do
      parent.subcategories << child
      SiteSetting.auto_email_in_enabled = true
      parent.reload
      child.reload
    end

    it "sets email-in on new category" do
      expect(Fabricate(:category, slug: "test").email_in).to eq "test@example.com"
    end

    it "sets email-in on new subcategory" do
      expect(Fabricate(:category, slug: "child", parent_category: parent).email_in).to eq "test-parent+child@example.com"
    end

    it "updates parent and child emails-in when the parent category is updated" do
      parent.slug = "new-test-parent"
      parent.save
      expect(parent.email_in).to eq "new-test-parent@example.com"
      expect(child.reload.email_in).to eq "new-test-parent+test-child@example.com"
    end

    it "updates emails-in when auto_email_in_domain setting is changed" do
      SiteSetting.auto_email_in_domain = "test.example.com"
      expect(parent.reload.email_in).to eq "test-parent@test.example.com"
      expect(child.reload.email_in).to eq "test-parent+test-child@test.example.com"
    end

    it "updates emails-in when auto_email_in_divider setting is changed" do
      SiteSetting.auto_email_in_divider = "."
      expect(child.reload.email_in).to eq "test-parent.test-child@example.com"
    end

    it "doesn't allow email-in to be updated normally" do
      parent.email_in = "test@example.com"
      parent.save
      expect(parent.email_in).to eq "test-parent@example.com"
    end

    context "when auto_email_in_append is enabled" do
      before { SiteSetting.auto_email_in_append = true }

      it "appends new email-in" do
        expect(parent.email_in).to eq "test-parent@example.com"
        parent.slug = "new-test-parent"
        parent.save
        expect(parent.email_in).to eq "test-parent@example.com|new-test-parent@example.com"
        parent.slug = "newer-test-parent"
        parent.save
        expect(parent.email_in).to eq "test-parent@example.com|new-test-parent@example.com|newer-test-parent@example.com"
      end

      it "doesn't append if new email-in is the same" do
        expect(parent.email_in).to eq "test-parent@example.com"
        parent.slug = "new-test-parent"
        parent.save
        expect(parent.email_in).to eq "test-parent@example.com|new-test-parent@example.com"
        parent.save
        expect(parent.email_in).to eq "test-parent@example.com|new-test-parent@example.com"
      end

      it "removes duplicates from the chain" do
        expect(parent.email_in).to eq "test-parent@example.com"
        parent.slug = "new-test-parent"
        parent.save
        expect(parent.email_in).to eq "test-parent@example.com|new-test-parent@example.com"
        parent.slug = "test-parent"
        parent.save
        expect(parent.email_in).to eq "new-test-parent@example.com|test-parent@example.com"
      end

      it "allows old entries to be removed through manual editing" do
        parent.slug = "new-test-parent"
        parent.save
        parent.slug = "newer-test-parent"
        parent.save
        expect(parent.email_in).to eq "test-parent@example.com|new-test-parent@example.com|newer-test-parent@example.com"
        parent.email_in = "anything@example.com"
        parent.save
        expect(parent.email_in).to eq "anything@example.com|newer-test-parent@example.com"
      end

    end

    context "when category has auto_email_in_disabled" do
      context "and is child category" do
        before { child.custom_fields["auto_email_in_disabled"] = true }

        it "allows manually setting email-in" do
          child.email_in = "manual@example.com"
          child.save
          expect(child.email_in).to eq "manual@example.com"
          SiteSetting.auto_email_in_divider = "."
          child.reload
          expect(child.email_in).to eq "manual@example.com"
        end
      end

      context "and is parent category" do
        before do
          child.save
          parent.custom_fields["auto_email_in_disabled"] = true
        end

        it "doesn't update child categories" do
          parent.slug = "new-parent"
          parent.save
          expect(parent.email_in).to eq "test-parent@example.com"
          expect(child.email_in).to eq "test-parent+test-child@example.com"
        end
      end
    end
  end
end
