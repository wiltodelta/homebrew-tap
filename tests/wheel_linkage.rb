# typed: strict
# frozen_string_literal: true

require "formula"
require "formulary"
require "tmpdir"

unless OS.mac?
  puts "Wheel Mach-O check is macOS-only"
  exit
end

path = Pathname(__dir__).parent/"Formula/remove-ai-watermarks.rb"
formula = Formulary.from_contents("remove-ai-watermarks", path, path.read)
Dir.mktmpdir("raiw-wheel-linkage-") do |directory|
  root = Pathname(directory)
  library = root/"site-packages/av/.dylibs/libsample.dylib"
  library.dirname.mkpath
  source = root/"sample.c"
  source.write("int sample(void) { return 42; }\n")
  raise "Could not compile fixture" unless system(
    "/usr/bin/clang", "-dynamiclib", "-Wl,-install_name,/DLC/av/.dylibs/libsample.dylib",
    "-o", library, source
  )

  # A wheel may expose aliases; changing an external symlink target is forbidden.
  (library.dirname/"alias.dylib").make_symlink(library)
  calls = []
  formula.define_singleton_method(:libexec) { root }
  formula.define_singleton_method(:system) do |*args|
    calls << args
    raise "Signing failed" unless Kernel.system(*args)
  end
  formula.preserve_wheel_linkage
  expected = "@rpath/libsample.dylib"
  raise "Hidden wheel dylib ID was not normalized" if MachOPathname.wrap(library).dylib_id != expected
  raise "Changed wheel was not signed once" if calls.length != 1
  raise "Signature is invalid" unless system("/usr/bin/codesign", "--verify", library)

  formula.preserve_wheel_linkage
  raise "An unchanged wheel was signed again" if calls.length != 1
end
puts "Hidden wheel dylib ID and signature passed"
