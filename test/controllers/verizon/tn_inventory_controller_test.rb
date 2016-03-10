require 'test_helper'

class Verizon::TnInventoryControllerTest < ActionController::TestCase
  test "should get getByAddress" do
    get :getByAddress
    assert_response :success
  end

  test "should get getByName" do
    get :getByName
    assert_response :success
  end

  test "should get getInventory" do
    get :getInventory
    assert_response :success
  end

end
