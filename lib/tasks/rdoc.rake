require 'rdoc/task'

##
# Creates a rake task to generate documentation
# rails rdoc
RDoc::Task.new do |rdoc|
  rdoc.name = "rdoc"
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("README.rdoc", "app/**/*.rb")
  rdoc.rdoc_files.exclude("app/assets", "app/channels", "app/views", "app/jobs")
  rdoc.rdoc_dir = "doc"
end