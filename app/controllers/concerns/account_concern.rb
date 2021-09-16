# frozen_string_literal: true

module AccountConcern
  extend ActiveSupport::Concern

  ATTRIBUTE_NAME = "transition_checker_state"
  EMAIL_SUBSCRIPTION_NAME = "transition-checker-results"

  included do
    include GovukPersonalisation::ControllerConcern

    before_action :set_account_session_header
    before_action -> { set_slimmer_headers(remove_search: true, show_accounts: logged_in? ? "signed-in" : "signed-out") }
    # this is a false positive which will be fixed by updating rubocop
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :pre_results, only: %i[results]
    before_action :pre_saved_results, only: %i[saved_results edit_saved_results]
    before_action :pre_update_results, only: %i[save_results_confirm save_results_apply]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    helper_method :must_reauthenticate?
    helper_method :show_confirmation_reminder?
    helper_method :confirmation_banner_prompt_type
  end

  def pre_results
    result = do_or_logout do
      Services.account_api.get_attributes(
        govuk_account_session: account_session_header,
        attributes: [ATTRIBUTE_NAME, "email_verified", "has_unconfirmed_email"],
      )
    end

    return if must_reauthenticate?

    @user_email_verified = result&.dig("values", "email_verified")
    @user_has_unconfirmed_email = result&.dig("values", "has_unconfirmed_email")

    results_in_account = result&.dig("values", ATTRIBUTE_NAME) || {}

    now = Time.zone.now.to_i
    @results_differ = criteria_keys != results_in_account.fetch("criteria_keys", [])
    @results_saved = !@results_differ && results_in_account.fetch("timestamp", now) >= now - 10
  end

  def pre_saved_results
    results_in_account = fetch_results_from_account_or_logout

    redirect_path = case action_name
                    when "saved_results"
                      transition_checker_saved_results_path
                    when "edit_saved_results"
                      transition_checker_edit_saved_results_path
                    end

    redirect_to logged_out_pre_saved_results_path(redirect_path) and return if must_reauthenticate?

    @saved_results = results_in_account.fetch("criteria_keys", [])
  end

  def pre_update_results
    results_in_account = fetch_results_from_account_or_logout
    redirect_to logged_out_pre_update_results_path and return if must_reauthenticate?

    @saved_results = results_in_account["criteria_keys"]
  end

  def update_answers_and_email_subscription_in_account_or_reauthenticate(slug, new_criteria_keys)
    do_or_logout do
      Services.account_api.put_email_subscription(
        govuk_account_session: account_session_header,
        name: EMAIL_SUBSCRIPTION_NAME,
        topic_slug: slug,
      )
    end

    do_or_logout do
      Services.account_api.set_attributes(
        govuk_account_session: account_session_header,
        attributes: {
          ATTRIBUTE_NAME => {
            criteria_keys: new_criteria_keys,
            timestamp: Time.zone.now.to_i,
          },
        },
      )
    end

    if must_reauthenticate?
      redirect_to logged_out_pre_update_results_path
    else
      redirect_to transition_checker_results_path(c: new_criteria_keys)
    end
  end

  def logged_out_pre_saved_results_path(path = transition_checker_saved_results_path)
    transition_checker_new_session_url path
  end

  def logged_out_pre_update_results_path
    transition_checker_new_session_url transition_checker_save_results_confirm_path(c: criteria_keys)
  end

  def fetch_results_from_account_or_logout
    result = do_or_logout { Services.account_api.get_attributes(govuk_account_session: account_session_header, attributes: [ATTRIBUTE_NAME]) }
    result&.dig("values", ATTRIBUTE_NAME) || {}
  end

  def do_or_logout
    return unless account_session_header

    result = yield.to_h
    set_account_session_header(result["govuk_account_session"])
    result
  rescue GdsApi::HTTPUnauthorized
    logout!
    nil
  rescue GdsApi::HTTPForbidden
    @level_of_authentication_is_too_low = true
    nil
  end

  def must_reauthenticate?
    !logged_in? || @level_of_authentication_is_too_low
  end

  def transition_checker_new_session_url(redirect_path)
    uri = GdsApi.account_api.get_sign_in_url(
      redirect_path: redirect_path,
      level_of_authentication: "level1",
    ).to_h["auth_uri"]
    uri += "&_ga=#{params[:_ga]}" if params[:_ga]
    uri
  end

  def base_path
    Rails.env.production? ? Plek.new.website_root : Plek.find("frontend")
  end

  def show_confirmation_reminder?
    return false unless logged_in?

    !@user_email_verified || @user_has_unconfirmed_email
  end

  def confirmation_banner_prompt_type
    return "update" if confirmed_user_changed_email?

    "set_up"
  end

  def confirmed_user_changed_email?
    @user_email_verified && @user_has_unconfirmed_email
  end
end
