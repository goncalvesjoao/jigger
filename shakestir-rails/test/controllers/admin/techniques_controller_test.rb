require "test_helper"

class Admin::TechniquesControllerTest < ActionDispatch::IntegrationTest
  test "admins manage translated guides without photo fields" do
    users(:one).update!(admin: true)
    sign_in_as(users(:one))
    technique = techniques(:shake)
    get admin_techniques_url
    assert_response :success
    assert_select "a[href=?]", admin_technique_path(technique), minimum: 1
    get admin_techniques_url(search: "Shake")
    assert_response :success
    get edit_admin_technique_url(technique)
    assert_response :success
    assert_select "input[type=file]", count: 0
    patch admin_technique_url(technique), params: { technique: { description: "Updated guide" } }
    assert_response :see_other
    assert_equal "Updated guide", technique.reload.description
    patch admin_technique_url(technique), params: { content_locale: "ja", technique: { name: "シェイク" } }
    assert_response :see_other
    assert_equal "Shake", technique.reload.name
    assert_equal "シェイク", technique.translation_for(:ja).name
    assert_difference("Technique.count") do
      post admin_techniques_url, params: { technique: { slug: "new-guide", name: "New guide", description: "Purpose", instructions: "Instructions" } }
    end
    assert_response :redirect
  end

  test "catalog changes require administrator access" do
    get admin_techniques_url
    assert_redirected_to new_session_url
    sign_in_as(users(:one))
    patch admin_technique_url(techniques(:shake)), params: { technique: { name: "Tampered" } }
    assert_response :forbidden
    assert_equal "Shake", techniques(:shake).reload.name
  end
end
