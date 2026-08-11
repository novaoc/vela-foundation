require "test_helper"

# SPEC M2.4: the legal documents must actually exist, be substantive, and
# carry visible version identifiers — enforced here so a fork cannot quietly
# ship an empty terms page.
class LegalPagesTest < ActionDispatch::IntegrationTest
  SUBSTANCE_THRESHOLD = 60 # non-blank lines per document

  DOCUMENT_SOURCES = {
    "terms" => Rails.root.join("app/views/foundation/legal/terms.html.erb"),
    "privacy" => Rails.root.join("app/views/foundation/legal/privacy.html.erb")
  }.freeze

  test "both documents exist and exceed the substance threshold" do
    DOCUMENT_SOURCES.each do |name, path|
      assert path.exist?, "expected the #{name} document at #{path}"

      non_blank_lines = path.read.lines.count { |line| line.strip.present? }

      assert_operator non_blank_lines, :>=, SUBSTANCE_THRESHOLD,
        "#{name} has #{non_blank_lines} non-blank lines; the template promises at least #{SUBSTANCE_THRESHOLD}"
    end
  end

  test "terms page renders with a visible version identifier and operator markers" do
    get legal_terms_path

    assert_response :success
    assert_includes response.body, Foundation::Legal.terms_label
    assert_match(/v\d+ — \d{4}-\d{2}-\d{2}/, response.body, "version identifier must be visible")
    assert_includes response.body, "TODO-OPERATOR"
  end

  test "privacy page renders with a visible version identifier and operator markers" do
    get legal_privacy_path

    assert_response :success
    assert_includes response.body, Foundation::Legal.privacy_label
    assert_match(/v\d+ — \d{4}-\d{2}-\d{2}/, response.body, "version identifier must be visible")
    assert_includes response.body, "TODO-OPERATOR"
  end

  test "legal pages are reachable without an account" do
    get legal_terms_path
    assert_response :success

    get legal_privacy_path
    assert_response :success
  end
end
