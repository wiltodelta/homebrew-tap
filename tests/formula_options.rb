require "formula"
require "formulary"
require "tmpdir"

path = Pathname(__dir__).parent/"Formula/remove-ai-watermarks.rb"
contents = path.read
load_formula = lambda do |flags|
  formula = Formulary.from_contents("remove-ai-watermarks", path, contents, flags:)
  formula.build = BuildOptions.new(Options.create(flags), formula.options)
  formula
end

defaults = load_formula.call([])
raise "Default install lost visible support" unless defaults.selected_extras == ["visible"]
raise "Wheel dylib IDs would be expanded by Homebrew" unless defaults.preserve_rpath?
extras = defaults.class::PACKAGE_EXTRAS
expected_flags = ["--without-default-extras", *extras.map { |extra| "--with-#{extra}" }].sort
raise "An extra has no Homebrew option" unless defaults.options.as_flags.sort == expected_flags

cases = [
  ["default", [], ["visible"]],
  ["metadata", ["--without-default-extras"], []],
  ["Seedance", ["--with-video", "--with-diffusion"], %w[diffusion video visible]],
  ["bare HEIF", ["--without-default-extras", "--with-heif"], ["heif"]],
]
extras.each do |extra|
  cases << [extra, ["--without-default-extras", "--with-#{extra}"], [extra]]
end
cases << ["all explicit extras", extras.map { |extra| "--with-#{extra}" }, extras.sort]

cases.each do |name, flags, expected|
  formula = load_formula.call(flags)
  Dir.mktmpdir("raiw-formula-options-") do |directory|
    root = Pathname(directory)
    calls = []
    virtualenv_calls = []
    (root/"source").mkpath
    (root/"venv/bin").mkpath
    (root/"venv/bin/remove-ai-watermarks").write("")
    formula.define_singleton_method(:buildpath) { root/"source" }
    formula.define_singleton_method(:libexec) { root/"venv" }
    formula.define_singleton_method(:bin) { root/"bin" }
    formula.define_singleton_method(:virtualenv_create) do |*args, **kwargs|
      virtualenv_calls << [args, kwargs]
    end
    formula.define_singleton_method(:system) do |*args|
      calls << args.map(&:to_s)
    end
    formula.install

    target = (root/"source").to_s
    target += "[#{expected.join(",")}]" unless expected.empty?
    expected_call = [
      "python3.12", "-m", "pip", "--python=#{root}/venv/bin/python", "install", target,
    ]
    raise "#{name}: incorrect installed extras: #{calls.inspect}" unless calls == [expected_call]
    unless virtualenv_calls == [[[root/"venv", "python3.12"], { system_site_packages: false }]]
      raise "#{name}: dependency environment is not isolated"
    end
    raise "#{name}: command was not linked" unless (root/"bin/remove-ai-watermarks").symlink?
  end
end

puts "#{cases.length} formula install selections passed using Homebrew's option parser"
