require "spec_helper"

describe "Thread subscriptions" do
  let(:thread) { FactoryGirl.create(:message_thread) }
  let(:subscribe_button) { find_button(I18n.t("formtastic.actions.thread_subscription.create")) }

  context "site user subscribe" do
    include_context "signed in as a site user"

    before do
      visit thread_path(thread)
    end

    context "for web only" do
      before do
        current_user.prefs.update_attribute(:notify_subscribed_threads, false)
      end

      it "should subscribe the user to the thread" do
        subscribe_button.click
        page.should have_content("You are now subscribed to this thread.")
        current_user.thread_subscriptions.count.should == 1
        current_user.thread_subscriptions.first.thread.should == thread
      end

      it "should state I am subscribed" do
        subscribe_button.click
        page.should have_content("You are subscribed")
      end

      it "should not send me an email when I post" do
        email_count = all_emails.count
        subscribe_button.click
        within(".new-message") do
          fill_in "Message", with: "All interesting stuff, but don't email me"
          click_on "Post Message"
        end
        all_emails.count.should == email_count
      end

      it "should subscribe me to the thread automatically" do
        current_user.subscribed_to_thread?(thread).should be_false
        within(".new-message") do
          fill_in "Message", with: "Given I'm interested enough to post, I should be subscribed"
          click_on "Post Message"
        end
        current_user.subscribed_to_thread?(thread).should be_true
      end
    end

    context "for email" do
      before do
        # Set the user to receive emails
        current_user.prefs.notify_subscribed_threads!
      end

      it "should subscribe the user to the thread" do
        subscribe_button.click
        page.should have_content("You are now subscribed to this thread.")
        current_user.thread_subscriptions.count.should == 1
        current_user.thread_subscriptions.first.thread.should == thread
      end

      it "should send future messages on the thread by email" do
        subscribe_button.click
        within(".new-message") do
          fill_in "Message", with: "Notification test"
          click_on "Post Message"
        end
        open_email(current_user.email, with_subject: /^Re/)
        current_email.should have_subject("Re: #{thread.title}")
        current_email.should have_body_text(/Notification test/)
        current_email.should be_delivered_from("#{current_user.name} <notifications@cyclescape.org>")
        current_email.should have_reply_to("Cyclescape <thread-#{thread.public_token}@cyclescape.org>")
      end
    end

    context "cancelling" do
      let(:unsubscribe_button) { find_button("Unfollow") }

      before do
        subscribe_button.click
      end

      it "should unsubscribe me" do
        current_user.should be_subscribed_to_thread(thread)
        unsubscribe_button.click
        current_user.should_not be_subscribed_to_thread(thread)
        page.should have_content("You have unsubscribed from this thread.")
      end

      it "should not send me any more messages" do
        email_count = all_emails.count
        unsubscribe_button.click
        within(".new-message") do
          fill_in "Message", with: "Notification test"
          click_on "Post Message"
        end
        all_emails.count.should == email_count
      end

      it "should resubscribe me" do
        current_user.should be_subscribed_to_thread(thread)
        unsubscribe_button.click
        current_user.should_not be_subscribed_to_thread(thread)
        subscribe_button.click
        current_user.should be_subscribed_to_thread(thread)
      end
    end
  end
end
