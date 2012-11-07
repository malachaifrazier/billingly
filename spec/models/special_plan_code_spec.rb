require 'spec_helper'

describe Billingly::SpecialPlanCode do
  describe 'when generating the numbers' do
    it 'generates batches of the given size' do
      Billingly::SpecialPlanCode.generate_ean_13_codes(5).size.should == 5
    end
    
    it 'generates all valid ean-13 numbers' do
      Billingly::SpecialPlanCode.generate_ean_13_codes(100).each do |code|
        EAN13.valid?(code).should be_true
      end
    end
    
    it 'does not create repeated codes if an existing list is provided' do
      pending
    end
  end
  
  describe 'when populating codes in the database' do
    it 'creates codes for the given plan' do
      plan = create(:pro_50_monthly)
      expect do
        Billingly::SpecialPlanCode.generate_for_plan(plan, 10).size.should == 10
      end.to change{ Billingly::SpecialPlanCode.where(plan_id: plan.id).count }.by(10)
    end
    it 'creates codes with a particular amount' do
      plan = create(:pro_50_monthly)
      expect do
        Billingly::SpecialPlanCode.generate_for_plan(plan, 10, 4).size.should == 10
      end.to change{ Billingly::SpecialPlanCode.where(bonus_amount: 4).count }.by(10)
    end
  end
  
  describe 'when exporting codes' do
    it 'exports all the codes on a per-plan basis' do
      Billingly::SpecialPlanCode.generate_for_plan(create(:pro_50_monthly), 10)
      Billingly::SpecialPlanCode.generate_for_plan(create(:pro_100_monthly), 10)
      Billingly::SpecialPlanCode.export_codes
      Dir[File.expand_path('~/ean_13_codes_for_*.csv')].size.should == 2
      Billingly::SpecialPlanCode.cleanup_exported_files
      Dir[File.expand_path('~/ean_13_codes_for_*.csv')].size.should == 0
    end
  end
  
  describe 'when retrieving only a redeemable code' do
    it 'retrieves a redeemable code' do
      Billingly::SpecialPlanCode.find_redeemable(create(:promo_code).code).should_not be_nil
    end
    
    it 'does not retrieve non existing codes' do
      Billingly::SpecialPlanCode.find_redeemable('abcd1').should be_nil
    end
    
    it 'does not retrieve codes which have been redeemed' do
      code = create(:promo_code, redeemed_on: Time.now).code
      Billingly::SpecialPlanCode.find_redeemable(code).should be_nil
    end
  end
end
