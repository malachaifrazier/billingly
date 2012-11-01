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
    end
  end
  
  describe 'when populating codes in the database' do
    it 'creates codes for the given plan' do
      expect do
        Billingly::SpecialPlanCode.generate_for_plan(create(:pro_50_monthly), 10)
          .size.should == 10
      end.to change{ Billingly::SpecialPlanCode.count }.by(10)
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
end
