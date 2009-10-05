Then "debug" do
  debugger
  true
end

Then 'show "(.*)"' do |code|
  eval "puts #{code}"
end
