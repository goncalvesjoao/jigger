require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "renders and escapes alert and notice messages" do
    flash[:alert] = "<script>alert('test')</script>"
    flash[:notice] = "Saved"

    render inline: "<%= flash_messages %>"

    assert_select "div.danger[role=status]", text: flash[:alert]
    assert_select "div.success[role=status]", text: "Saved"
    assert_select "script", count: 0
  end

  test "renders nothing without flash messages" do
    assert_equal "", flash_messages
  end
end
