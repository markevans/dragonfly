require 'spec_helper'

describe Dragonfly::Job::Fetch do

  let (:app) { test_app }
  let (:job) { Dragonfly::Job.new(app) }

  before(:each) do
    job.fetch!('some_uid')
  end

  it { job.steps.should match_steps([Dragonfly::Job::Fetch]) }

  it "should read from the app's datastore when applied" do
    app.datastore.should_receive(:read).with('some_uid').and_return ["", {}]
    job.apply
  end

  it "raises NotFound if the datastore returns nil" do
    app.datastore.should_receive(:read).and_return(nil)
    expect {
      job.apply
    }.to raise_error(Dragonfly::Job::Fetch::NotFound)
  end

end
