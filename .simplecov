ignore_list = [
  "coverage",
  "firmware/.arduino",
  "package",
  "resources/postinst",
]

SimpleCov.add_filter ignore_list

SimpleCov.command_name 'test:serial-keyboard'

SimpleCov.coverage_dir './coverage/bash'
