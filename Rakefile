
# load libraries

require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'lib/joggle/version.rb' 

def package_info
  require 'ostruct'
  require 'rubygems'

  # create package
  ret = OpenStruct.new

  # set package information
  ret.name          = 'Joggle'
  ret.blurb         = 'Jabber/Twitter relay, written in Ruby.'
  ret.version       = Joggle::VERSION
  ret.platform      = Gem::Platform::RUBY
  ret.url           = 'http://pablotron.org/software/joggle/'

  # author information
  ret.author_name   = 'Paul Duncan'
  ret.author_email  = 'pabs@pablotron.org'

  # requirements and files
  ret.reqs          = ['none']
  ret.include_files = Dir['**/*'].delete_if { |path| 
    %w{CVS .svn .hg}.any? { |chunk| path.include?(chunk) }
  }
      
  # rdoc info
  ret.rdoc_title    = "#{ret.name} #{ret.version} API Documentation"
  ret.rdoc_options  = %w{--webcvs http://hg.pablotron.org/joggle}
  ret.rdoc_dir      = 'doc'
  ret.rdoc_files    = %w{bin/joggle lib/**/*.rb README examples/**/*}

  # runtime info
  ret.auto_require  = 'joggle'
  ret.executables   = %w{joggle}
  ret.require_path  = 'lib'
  ret.package_name  = 'joggle'
  ret.dependencies  = %w{xmpp4r json}

  # package signing
  if false && ENV['GEM_SIGNING_KEY'] && ENV['GEM_SIGNING_CHAIN']
    ret.signing_key = File.expand_path(ENV['GEM_SIGNING_KEY'])
    ret.signing_chain = ENV['GEM_SIGNING_CHAIN'].split(',').map { |path|
      File.expand_path(path)
    }
  end

  # package release dir
  if path = ENV['RAKE_PACKAGE_DIR']
    ret.pkg_dir = File.join(File.expand_path(path), ret.package_name)
  end

  if files = ret.rdoc_files
    ret.rdoc_files = files.map { |e| Dir.glob(e) }.flatten.compact
  end

  # return package
  ret
end

pkg = package_info

gem_spec = Gem::Specification.new do |s|
  # package information
  s.name      = pkg.name.downcase
  s.platform  = pkg.platform
  s.version   = pkg.version
  s.summary   = s.description = pkg.blurb

  # files
  pkg.reqs.each { |req| s.requirements << req }
  s.files = pkg.include_files

  # runtime info
  s.executables   = pkg.executables
  s.require_path  = pkg.require_path
  s.autorequire   = pkg.auto_require

  # dependencies
  pkg.dependencies.each { |dep| s.add_dependency(dep) }

  # rdoc info
  s.has_rdoc = true
  s.rdoc_options = ['--title', pkg.rdoc_title] + pkg.rdoc_options + pkg.rdoc_files

  # author and project details
  s.author    = pkg.author_name
  s.email     = pkg.author_email
  s.homepage  = pkg.url

  # gem crypto stuff
  if pkg.signing_key && pkg.signing_chain
    s.signing_key   = pkg.signing_key
    s.signing_chain = pkg.signing_chain
  end
end

Rake::GemPackageTask.new(gem_spec) do |p|
  p.need_tar_gz = true
  # p.need_pgp_signature = true
  p.package_dir = pkg.pkg_dir if pkg.pkg_dir
end


Rake::RDocTask.new do |rd|
  rd.title = pkg.rdoc_title
  rd.rdoc_dir = pkg.rdoc_dir
  rd.rdoc_files.include(*pkg.rdoc_files)
  rd.options.concat(pkg.rdoc_options)
end

task :clean => [:clobber]
task :release => [:clean, :package]
