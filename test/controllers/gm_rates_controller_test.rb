require 'test_helper'

class GmRatesControllerTest < ActionController::TestCase
  setup do
    @gm_rate = gm_rates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:gm_rates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create gm_rate" do
    assert_difference('GmRate.count') do
      post :create, gm_rate: {  }
    end

    assert_redirected_to gm_rate_path(assigns(:gm_rate))
  end

  test "should show gm_rate" do
    get :show, id: @gm_rate
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @gm_rate
    assert_response :success
  end

  test "should update gm_rate" do
    patch :update, id: @gm_rate, gm_rate: {  }
    assert_redirected_to gm_rate_path(assigns(:gm_rate))
  end

  test "should destroy gm_rate" do
    assert_difference('GmRate.count', -1) do
      delete :destroy, id: @gm_rate
    end

    assert_redirected_to gm_rates_path
  end
end
