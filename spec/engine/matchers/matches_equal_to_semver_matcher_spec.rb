# frozen_string_literal: true

require 'spec_helper'

describe SplitIoClient::EqualToSemverMatcher do
  let(:raw) { {
    'negate': false,
    'matcherType': 'EQUAL_TO_SEMVER',
    'stringMatcherData': "2.1.8"
  } }
  let(:config) { SplitIoClient::SplitConfig.new }

  it 'initilized params' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.attribute).to eq("version")
    semver = matcher.instance_variable_get(:@semver)
    expect(semver.instance_variable_get(:@version)).to eq("2.1.8")
  end

  it 'matches' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.match?(:attributes=>{"version": "2.1.8"})).to eq(true)
  end

  it 'does not match' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.match?(:attributes=>{"version": "2.1.8+rc"})).to eq(false)
    expect(matcher.match?(:attributes=>{"version": "2.1.5"})).to eq(false)
    expect(matcher.match?(:attributes=>{"version": "2.1.5-rc1"})).to eq(false)
  end

  it 'invalid attribute' do
    matcher = described_class.new("version", raw[:stringMatcherData], config.logger, config.split_validator)
    expect(matcher.match?(:attributes=>{"version": 2.1})).to eq(false)
    expect(matcher.match?(:attributes=>{"version": nil})).to eq(false)
  end
end
