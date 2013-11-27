require 'spec_helper'

describe Dragonfly::Job::Process do

  let (:app) { test_app }
  let (:job) { Dragonfly::Job.new(app) }

  before :each do
    app.add_processor(:resize){}
  end

  it "adds a step" do
    job.process!(:resize, '20x30')
    job.steps.should match_steps([Dragonfly::Job::Process])
  end

  it "should use the processor when applied" do
    job.process!(:resize, '20x30')
    app.get_processor(:resize).should_receive(:call).with(job.content, '20x30')
    job.apply
  end

  it "should call update_url immediately with the url_attributes" do
    app.get_processor(:resize).should_receive(:update_url).with(job.url_attributes, '20x30')
    job.process!(:resize, '20x30')
  end

end
