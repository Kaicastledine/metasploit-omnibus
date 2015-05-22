name "john"
default_version "1.8.0-jumbo-1"

version("1.8.0-jumbo-1") { source md5: "1d6b22ec41a12cdcd62ad6eae3e77345" }

source url: "http://www.openwall.com/john/j/john-1.8.0-jumbo-1.tar.xz"

relative_path "john-#{version}/src"

dependency "openssl"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  command "./configure --prefix=#{install_dir}/embedded --disable-openmp", env: env
  make env: env
  make "install", env: env
  mkdir "#{install_dir}/embedded/john"
  copy "#{project_dir}/../run/*", "#{install_dir}/embedded/john/"
end
