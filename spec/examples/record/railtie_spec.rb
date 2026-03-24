# -*- encoding : utf-8 -*-
require_relative 'spec_helper'
require 'fileutils'
require 'pathname'
require 'tmpdir'

unless defined?(Rails)
  module Rails
    class << self
      attr_accessor :env, :root
    end

    class Railtie
      class << self
        def config
          @config ||= Struct.new(:cequel).new
        end

        def initializer(*)
        end

        def rake_tasks(*)
        end

        def generators(*)
        end
      end
    end
  end
end

require_relative '../../../lib/cequel/record/railtie'

describe Cequel::Record::Railtie do
  around do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  end

  before do
    allow(Rails).to receive(:env).and_return('development')
    allow(Rails).to receive(:root).and_return(Pathname.new(@tmpdir))
    allow(described_class).to receive(:app_name).and_return('falcie')
  end

  describe '#configuration' do
    it 'loads yaml aliases from cequel.yml' do
      FileUtils.mkdir_p(File.join(@tmpdir, 'config'))
      File.write(File.join(@tmpdir, 'config/cequel.yml'), <<~YAML)
        default: &default
          host: '127.0.0.1'
          port: 9042
          max_retries: 3
          retry_delay: 0.5
          newrelic: false

        development:
          <<: *default
          keyspace: falcie_development
      YAML

      expect(described_class.new.send(:configuration)).to eq(
        host: '127.0.0.1',
        port: 9042,
        max_retries: 3,
        retry_delay: 0.5,
        newrelic: false,
        keyspace: 'falcie_development'
      )
    end
  end
end
