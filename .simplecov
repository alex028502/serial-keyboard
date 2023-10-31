require 'simplecov-lcov'

ignore_list = [
  "coverage",
  "firmware/.arduino",
  "package",
  "resources/postinst",
]

SimpleCov.add_filter ignore_list

SimpleCov.command_name 'test:serial-keyboard'

SimpleCov.coverage_dir '.bashcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter

# SimpleCov.formatters = SimpleCov::Formatter::JSONFormatter
