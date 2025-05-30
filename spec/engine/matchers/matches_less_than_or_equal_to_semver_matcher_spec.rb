# frozen_string_literal: true

require 'spec_helper'

describe SplitIoClient::LessThanOrEqualToSemverMatcher do
  let(:raw) { {
    'negate': false,
    'matcherType': 'LESS_THAN_OR_EQUAL_TO_SEMVER',
    'stringMatcherData': "2.1.8"
  } }
  let(:config) { SplitIoClient::SplitConfig.new({:logger => Logger.new('/dev/null')}) }

  it 'initilized params' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.attribute).to eq("version")
    semver = matcher.instance_variable_get(:@semver)
    expect(semver.instance_variable_get(:@version)).to eq("2.1.8")
  end

  it 'matches' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.match?(:attributes=>{"version": "2.1.8+rc"})).to eq(true)
    expect(matcher.match?(:attributes=>{"version": "2.1.8"})).to eq(true)
    expect(matcher.match?(:attributes=>{"version": "2.1.5"})).to eq(true)
    expect(matcher.match?(:attributes=>{"version": "2.1.5-rc1"})).to eq(true)
  end

  it 'does not match' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.match?(:attributes=>{"version": "2.1.10"})).to eq(false)
    expect(matcher.match?(:attributes=>{"version": "2.2.0-rc1"})).to eq(false)
  end

  it 'invalid attribute' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.match?(:attributes=>{"version": 2.1})).to eq(false)
    expect(matcher.match?(:attributes=>{"version": nil})).to eq(false)
  end

end
