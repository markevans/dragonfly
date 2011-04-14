Then "show me the html" do
  puts page.body
end

Then 'show "(.*)"' do |code|
  eval "puts #{code}"
end
