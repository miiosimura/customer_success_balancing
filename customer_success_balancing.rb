# frozen_string_literal: true

require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  TIE_RESULT = 0

  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  def execute
    remove_away_customer_success if away_customer_success.any?
    create_customers_key_on_customer_success
    balance_customers

    return TIE_RESULT if customer_sucess_with_max_customers_size.size > 1

    customer_sucess_with_max_customers_size.first[:id]
  end

  private

  attr_reader :customer_success, :customers, :away_customer_success

  def remove_away_customer_success
    customer_success.reject! { |cs| away_customer_success.include?(cs[:id]) }.compact
  end

  def create_customers_key_on_customer_success
    customer_success.each { |cs| cs[:customers] = [] }
  end

  def balance_customers
    customers.each do |customer|
      customer_succes_with_more_score_than_customer = customer_success.select { |cs| cs[:score] >= customer[:score] }
      next if customer_succes_with_more_score_than_customer.empty?

      customer_success_able_to_answer = customer_succes_with_more_score_than_customer.min_by { |cs| cs[:score] }
      customer_success_able_to_answer[:customers] << customer[:id]
    end
  end

  def customer_sucess_with_max_customers_size
    customer_success.select { |cs| cs[:customers].size == max_customers_size }
  end

  def max_customers_size
    customer_success.max_by { |cs| cs[:customers].size }[:customers].size
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10_000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
