ignore_list = [
  "coverage",
]

SimpleCov.add_filter ignore_list

SimpleCov.command_name 'test:serial-keyboard'

SimpleCov.coverage_dir './coverage/bash'
