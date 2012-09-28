require 'spec_helper'

describe Billingly::Engine do
  before { Billingly::Engine.stub(called_from: '/lib/billingly') }

  it 'returns the path to the engine app directory' do
    Billingly::Engine.app_path.should eq '/app'
  end

  it 'returns the path to the named engine controller' do
    Billingly::Engine.controller_path(:test_controller)
      .should eq '/app/controllers/billingly/test_controller.rb'
  end

  it 'returns the path to the named engine helper' do
    Billingly::Engine.helper_path(:test_helper)
      .should eq '/app/helpers/billingly/test_helper.rb'
  end

  it 'returns the path to the named engine mailer' do
    Billingly::Engine.mailer_path(:test_mailer)
      .should eq '/app/mailers/billingly/test_mailer.rb'
  end

  it 'returns the path to the named engine model' do
    Billingly::Engine.model_path(:test_model)
      .should eq '/app/models/billingly/test_model.rb'
  end
end
