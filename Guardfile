# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'nanoc' do
  watch( /^config.yaml/ )
  watch( /^Rules/ )
  watch( /^layouts\//)
  watch( /^content\// )
  watch( /^lib\// )
  watch( /^static\// )
end

guard 'livereload' do
  watch(%r{output/.+\.(html|css|js)})
end