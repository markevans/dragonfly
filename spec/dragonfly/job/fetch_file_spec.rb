require 'spec_helper'

describe Dragonfly::Job::FetchFile do

  let (:app) { test_app }
  let (:job) { Dragonfly::Job.new(app) }

  before(:each) do
    job.fetch_file!(SAMPLES_DIR.join('egg.png'))
  end

  it { job.steps.should match_steps([Dragonfly::Job::FetchFile]) }

  it "should fetch the specified file when applied" do
    job.size.should == 62664
  end

  it "should set the url_attributes" do
    job.url_attributes.name.should == 'egg.png'
  end

  it "should set the name" do
    job.name.should == 'egg.png'
  end

end
