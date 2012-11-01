require 'set'
require 'ean13'

# A SpecialPlanCode lets the {Customer} subscribe to a plan which is hidden from regular
# customers.
# Customers would visit your site and redeem the code instead of subscribing to
# a plan directly. The code will then subscribe them to a plan with the given special pricing.
class Billingly::SpecialPlanCode < ActiveRecord::Base
  belongs_to :plan
  belongs_to :customer
  validates :plan, presence: true
  validates :code, presence: true
  
  attr_accessible :plan, :code, :customer, :redeemed_on
  
  # !@attribute [r] redeemed?
  # @return [Boolean] Whether this code has been redeemed or not
  def redeemed?
    !redeemed_on.nil?   
  end

  # Creates a list of valid random ean-13 codes.
  # @param how_many [Integer] How many codes to create.
  # @return [Array<String>] The list of generated ean-13 codes.
  def self.generate_ean_13_codes(how_many)
    randoms = Set.new
    loop do
      ean = EAN13.complete( (100000000000 + rand(100000000000)).to_s )
      randoms << ean if ean
      return randoms.to_a if randoms.size == how_many
    end
  end
  
  # Generates rows in the database with codes for a specific plan.
  # It creates new rows with new codes, and it makes sure that the new codes don't clash
  # with pre-existing codes.
  # @param plan [Plan] The plan to generate the codes for.
  # @param how_many [Integer] How many new codes to issue.
  def self.generate_for_plan(plan, how_many)
    generate_ean_13_codes(how_many).collect do |code|
      self.create!(code: code, plan: plan)
    end
  end
  
  # Exports all the codes for each plan. You may export only the unused ones.
  # The codes are exported into CSV files inside the current user's home directory.
  # There is one file per plan. Each file contains all the available codes for a given plan.
  def self.export_codes
    where('redeemed_on IS NULL').group_by(&:plan).each do |plan, special_codes|
      filename = "ean_13_codes_for_#{plan.description.gsub(/[^a-zA-Z0-9]/,'_')}.csv"
      File.open(File.expand_path("~/#{filename}"),'w') do |file|
        file.write(special_codes.collect(&:code).join("\n"))
      end
    end
  end
  
  def self.cleanup_exported_files
    `rm #{File.expand_path('~/ean_13_codes_for_*.csv')}`
  end
end
