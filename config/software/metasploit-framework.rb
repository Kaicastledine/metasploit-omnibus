name "metasploit-framework"
source git: "https://github.com/rapid7/metasploit-framework.git"
default_version "master"

#default_version "release"
#source url: "https://github.com/rapid7/metasploit-framework/archive/#{default_version}.tar.gz",
#       md5: "8194917a8b5e53f9f72e8ba55df8c8cf"
#relative_path "metasploit-framework-#{default_version}"

dependency "bundler"
dependency "pcaprub"
if windows?
  dependency "postgresql-windows"
  dependency "postgresql-windows-prev"
else
  dependency "liblzma"
  dependency "libxslt"
  dependency "ruby"
  dependency "postgresql"
  dependency "postgresql-prev"
  dependency "sqlite"
end

# This depends on extra system libraries on OS X
whitelist_file "#{install_dir}//embedded/framework/data/isight.bundle"

# This depends on libfuse
whitelist_file "#{install_dir}/embedded/framework/data/exploits/CVE-2016-4557/hello"

# This depends on Openssl 1.x
whitelist_file "#{install_dir}/embedded/lib/ruby/gems/2.3.0/gems/metasploit-payloads.*"

build do
  copy "#{project_dir}", "#{install_dir}/embedded/framework"
  patch source: "no-git.diff", plevel: 1, target: "#{install_dir}/embedded/framework/metasploit-framework.gemspec"

  major, minor, patch = Omnibus::BuildVersion.semver.split('.')

  erb source: 'version.yml.erb',
      dest: "#{install_dir}/embedded/framework/version.yml",
      mode: 0644,
      vars: {
        major: major,
        minor: minor,
        patch: patch,
        git_hash: `git ls-remote #{source[:git]} HEAD`.strip.split(' ')[0],
        date: Time.new.strftime("%Y%m%d")
      }

  erb source: 'msfdb.erb',
      dest: "#{install_dir}/embedded/framework/msfdb",
      mode: 0755,
      vars: { install_dir: install_dir }

  unless windows?
    erb source: 'msfdb-kali.erb',
        dest: "#{install_dir}/embedded/framework/msfdb-kali",
        mode: 0755,
        vars: { install_dir: install_dir }
  end

  env = with_standard_compiler_flags(with_embedded_path)
  bundle "install", env: env

  if windows?
    # Workaround missing Ruby 2.3 support for bcrypt on Windows
    # https://github.com/codahale/bcrypt-ruby/issues/139
    gem "uninstall bcrypt", env: env
    gem "install bcrypt --platform=ruby", env: env

    delete "#{install_dir}/devkit"
  else
    command "chmod o+r #{install_dir}/embedded/lib/ruby/gems/2.3.0/gems/robots-0.10.1/lib/robots.rb"
  end
end
