require "test_helper"

class BillingTest < ActionDispatch::IntegrationTest
  PASSWORD = "correct horse battery"

  setup do
    @owner = users(:confirmed)
    @organization = Organizations::Organization.create!(name: "Billing Lab")
    Organizations::Membership.create!(user: @owner, organization: @organization, role: "owner")
  end

  test "public pricing renders configured tiers and interval toggle" do
    get pricing_path
    assert_response :success
    assert_select "h2", text: "Free"
    assert_select "h2", text: "Pro"
    assert_select "h2", text: "Enterprise"
    assert_select "a[aria-current=page]", text: "Monthly"
    assert_select "p", text: /\$29/

    get pricing_path(interval: "year")
    assert_response :success
    assert_select "a[aria-current=page]", text: "Yearly"
    assert_select "p", text: /\$290/
  end

  test "manual plans are marked and hide self-serve upgrade calls to action" do
    @organization.assign_pricing_plan!(:pro)
    sign_in_and_switch(@owner)

    get pricing_path
    assert_response :success
    assert_select "strong", text: "Manually assigned plan."
    assert_select "form[action=?]", billing_checkout_path, count: 0
    assert_select "span", text: /Current plan · manual/
  end

  test "checkout uses the selected configured Stripe price" do
    host! "attacker.invalid"
    sign_in_and_switch(@owner)
    captured = nil
    checkout = lambda do |**arguments|
      captured = arguments
      "https://checkout.stripe.test/session_stub"
    end

    with_stubbed_singleton_method(Foundation::BillingGateway, :checkout_url, checkout) do
      post billing_checkout_path, params: { plan: "pro", interval: "year" }
    end

    assert_response :see_other
    assert_redirected_to "https://checkout.stripe.test/session_stub"
    assert_equal @organization, captured[:organization]
    assert_equal "price_pro_yearly", captured[:price_id]
    assert_equal "https://example.com/billing?checkout=success", captured[:success_url]
    assert_equal "https://example.com/pricing?interval=year", captured[:cancel_url]
    assert_no_match(/attacker\.invalid/, captured.values.join(" "))
  end

  test "checkout rejects free, unknown, and manually controlled plans" do
    sign_in_and_switch(@owner)

    post billing_checkout_path, params: { plan: "free", interval: "month" }
    assert_redirected_to pricing_path

    @organization.assign_pricing_plan!(:enterprise)
    post billing_checkout_path, params: { plan: "pro", interval: "month" }
    assert_redirected_to pricing_path
    assert_match(/manually assigned/, flash[:alert])
  end

  test "a member cannot start checkout" do
    member = User.create!(
      email: "billing-member@example.com",
      password: PASSWORD,
      legal_assent: "1",
      confirmed_at: Time.current
    )
    Organizations::Membership.create!(user: member, organization: @organization, role: "member")
    sign_in_and_switch(member)

    post billing_checkout_path, params: { plan: "pro", interval: "month" }
    assert_redirected_to billing_path
    assert_match(/owners and admins/, flash[:alert])
  end

  test "mixed manual and subscription state still exposes the portal" do
    create_subscription
    @organization.assign_pricing_plan!(:enterprise)
    sign_in_and_switch(@owner)

    get billing_path
    assert_response :success
    assert_select "span", text: "Manually assigned"
    assert_select "form[action=?]", billing_portal_path
    assert_select "a", text: "Compare plans", count: 0

    portal_arguments = nil
    portal = lambda do |**arguments|
      portal_arguments = arguments
      "https://billing.stripe.test/portal_stub"
    end
    with_stubbed_singleton_method(Foundation::BillingGateway, :portal_url, portal) do
      post billing_portal_path
    end
    assert_response :see_other
    assert_redirected_to "https://billing.stripe.test/portal_stub"
    assert_equal @organization, portal_arguments[:organization]
    assert_equal "https://example.com/billing", portal_arguments[:return_url]
  end

  private

  def sign_in_and_switch(user)
    post user_session_path, params: { user: { email: user.email, password: PASSWORD } }
    post organizations.switch_organization_path(@organization)
  end

  def create_subscription
    customer = Pay::Stripe::Customer.create!(
      owner: @organization,
      processor: "stripe",
      processor_id: "cus_billing_test",
      default: true
    )
    Pay::Stripe::Subscription.create!(
      customer: customer,
      name: "default",
      processor_id: "sub_billing_test",
      processor_plan: "price_pro_monthly",
      status: "active"
    )
  end
end
