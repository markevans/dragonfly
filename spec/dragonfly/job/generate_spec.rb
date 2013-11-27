require 'spec_helper'

describe Dragonfly::Job::Generate do

  let (:app) { test_app }
  let (:job) { Dragonfly::Job.new(app) }

  before :each do
    app.add_generator(:plasma){}
  end

  it "adds a step" do
    job.generate!(:plasma, 20)
    job.steps.should match_steps([Dragonfly::Job::Generate])
  end

  it "uses the generator when applied" do
    job.generate!(:plasma, 20)
    app.get_generator(:plasma).should_receive(:call).with(job.content, 20)
    job.apply
  end

  it "updates the url if method exists" do
    app.get_generator(:plasma).should_receive(:update_url).with(job.url_attributes, 20)
    job.generate!(:plasma, 20)
  end

end
