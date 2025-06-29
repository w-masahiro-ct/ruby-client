# frozen_string_literal: true

require 'spec_helper'

describe SplitIoClient::Cache::Fetchers::SegmentFetcher do
  let(:segments_json) do
    File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../test_data/segments/segments.json')))
  end
  let(:segments_json2) do
    File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../test_data/segments/segments2.json')))
  end
  let(:splits_with_segments_json) do
    File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../test_data/splits/splits3.json')))
  end
  let(:segment_data) do
    [
      { name: 'employees', added: %w[max dan], removed: [], since: -1, till: 1_473_863_075_059 },
      { name: 'employees', added: [], removed: [], since: 1_473_863_075_059, till: 1_473_863_075_059 }
    ]
  end

  before do
    stub_request(:get, 'https://sdk.split.io/api/segmentChanges/employees?since=-1')
      .to_return(status: 200, body: segments_json)

    stub_request(:get, 'https://sdk.split.io/api/segmentChanges/employees?since=1473863075059')
      .to_return(status: 200, body: segments_json2)

    stub_request(:get, 'https://sdk.split.io/api/splitChanges?s=1.3&since=-1&rbSince=-1')
      .to_return(status: 200, body: splits_with_segments_json)
  end

  context 'memory adapter' do
    let(:config) { SplitIoClient::SplitConfig.new }
    let(:segments_repository) { SplitIoClient::Cache::Repositories::SegmentsRepository.new(config) }
    let(:flag_sets_repository) {SplitIoClient::Cache::Repositories::MemoryFlagSetsRepository.new([]) }
    let(:flag_set_filter) {SplitIoClient::Cache::Filter::FlagSetsFilter.new([]) }
    let(:splits_repository) { SplitIoClient::Cache::Repositories::SplitsRepository.new(config, flag_sets_repository, flag_set_filter) }
    let(:rule_based_segments_repository) { SplitIoClient::Cache::Repositories::RuleBasedSegmentsRepository.new(config) }
    let(:telemetry_runtime_producer) { SplitIoClient::Telemetry::RuntimeProducer.new(config) }
    let(:segment_fetcher) { described_class.new(segments_repository, '', config, telemetry_runtime_producer) }
    let(:split_fetcher) do
      SplitIoClient::Cache::Fetchers::SplitFetcher.new(splits_repository, rule_based_segments_repository, '', config, telemetry_runtime_producer)
    end

    it 'fetch segments' do
      split_fetcher.send(:fetch_splits)
      segment_fetcher.send(:fetch_segments)
      segment_fetcher.send(:fetch_segments)
      segment_fetcher.send(:fetch_segments)

      expect(segment_fetcher.segments_repository.used_segment_names).to eq(['employees'])
    end

    it 'updates added/removed' do
      segments = segment_fetcher.send(:segments_api).send(:fetch_segment_changes, 'employees', -1)
      expect(segments[:added]).to eq(%w[max dan])
      expect(segments[:removed]).to eq([])

      segments = segment_fetcher.send(:segments_api).send(:fetch_segment_changes, 'employees', 1_473_863_075_059)
      expect(segments[:added]).to eq([])
      expect(segments[:removed]).to eq([])
    end
  end

  context 'redis adapter' do
    before do
      Redis.new.flushall
    end
    let(:config) { SplitIoClient::SplitConfig.new(cache_adapter: :redis) }
    let(:adapter) { SplitIoClient::Cache::Adapters::RedisAdapter.new(config.redis_url) }
    let(:segments_repository) { SplitIoClient::Cache::Repositories::SegmentsRepository.new(config) }
    let(:flag_sets_repository) {SplitIoClient::Cache::Repositories::RedisFlagSetsRepository.new(config) }
    let(:flag_set_filter) {SplitIoClient::Cache::Filter::FlagSetsFilter.new([]) }
    let(:splits_repository) { SplitIoClient::Cache::Repositories::SplitsRepository.new(config, flag_sets_repository, flag_set_filter) }
    let(:rule_based_segments_repository) { SplitIoClient::Cache::Repositories::RuleBasedSegmentsRepository.new(config) }
    let(:telemetry_runtime_producer) { SplitIoClient::Telemetry::RuntimeProducer.new(config) }
    let(:segment_fetcher) { described_class.new(segments_repository, '', config, telemetry_runtime_producer) }
    let(:split_fetcher) do
      SplitIoClient::Cache::Fetchers::SplitFetcher.new(splits_repository, rule_based_segments_repository, '', config, telemetry_runtime_producer)
    end

    it 'fetch segments' do
      split_fetcher.send(:fetch_splits)
      segment_fetcher.send(:fetch_segments)

      expect(segment_fetcher.segments_repository.used_segment_names).to eq(['employees'])
    end

    it 'updates added/removed' do
      segments = segment_fetcher.send(:segments_api).send(:fetch_segment_changes, 'employees', -1)
      expect(segments[:added]).to eq(%w[max dan])
      expect(segments[:removed]).to eq([])

      segments = segment_fetcher.send(:segments_api).send(:fetch_segment_changes, 'employees', 1_473_863_075_059)
      expect(segments[:added]).to eq([])
      expect(segments[:removed]).to eq([])
    end
  end
end
