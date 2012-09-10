require 'spec_helper'

describe 'routing to subscriptions' do
  it 'routes GET /subscriptions to subscriptions#index' do
    expect(get: '/subscriptions').to route_to(
      controller: 'billingly/subscriptions',
      action: 'index'
    )
  end

  it 'routes GET /subscriptions/new to subscriptions#new' do
    expect(get: '/subscriptions/new').to route_to(
      controller: 'billingly/subscriptions',
      action: 'new'
    )
  end

  it 'routes POST /subscriptions to subscriptions#create' do
    expect(post: '/subscriptions').to route_to(
      controller: 'billingly/subscriptions',
      action: 'create'
    )
  end

  it 'routes POST /subscriptions/reactivate to subscriptions#reactivate' do
    expect(post: '/subscriptions/reactivate').to route_to(
      controller: 'billingly/subscriptions',
      action: 'reactivate'
    )
  end

  it 'accepts a namespace' do
    expect(get: '/namespaced_billingly/subscriptions').to route_to(
      controller: 'billingly/subscriptions',
      action: 'index'
    )
  end
end

