RSpec::Matchers.define :match_url do |url|
  match do |given|
    given_path, given_query_string = given.split('?')
    path, query_string = url.split('?')

    path == given_path && given_query_string.split('&').sort == query_string.split('&').sort
  end
end

RSpec::Matchers.define :be_an_empty_directory do
  match do |given|
    !!ENV['TRAVIS'] || (Dir.entries(given).sort == ['.','..'].sort)
  end
end

RSpec::Matchers.define :include_hash do |hash|
  match do |given|
    given.merge(hash) == given
  end
end

RSpec::Matchers.define :match_attachment_classes do |classes|
  match do |given_classes|
    given_classes.length == classes.length &&
      classes.zip(given_classes).all? do |(klass, given)|
        given.model_class == klass[0] && given.attribute == klass[1] && given.app == klass[2]
      end
  end
end

RSpec::Matchers.define :be_a_text_response do
  match do |given_response|
    given_response.status.should == 200
    given_response.body.length.should > 0
    given_response.content_type.should == 'text/plain'
  end
end

RSpec::Matchers.define :have_keys do |*keys|
  match do |given|
    given.keys.map{|sym| sym.to_s }.sort == keys.map{|sym| sym.to_s }.sort
  end
end

RSpec::Matchers.define :match_steps do |steps|
  match do |given|
    given.map{|step| step.class } == steps
  end
end

RSpec::Matchers.define :increase_num_tempfiles do
  match do |block|
    num_tempfiles_before = Dir.entries(Dir.tmpdir).size
    block.call
    num_tempfiles_after = Dir.entries(Dir.tmpdir).size
    increased = num_tempfiles_after > num_tempfiles_before
    puts "Num tempfiles increased: #{num_tempfiles_before} -> #{num_tempfiles_after}" if increased
    increased
  end

  def supports_block_expectations?
    true
  end
end

RSpec::Matchers.define :call_command do |shell, command|
  match do |block|
    # run_command is private so this is slightly naughty but it does the job
    allow(shell).to receive(:run_command).and_call_original
    block.call
    expect(shell).to have_received(:run_command).with(command)
  end

  def supports_block_expectations?
    true
  end
end
