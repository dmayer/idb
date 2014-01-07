require 'open-uri'

class URLSchemeFuzzer


  def default_fuzz_strings
    fuzz_inputs = [
        "A" * 10,
        "A" * 101,
        "A" * 1001,
        "\x0",
        "'",
        "%",
        "%n",
        "%@" * 20,
        "%n%d" * 20,
        "%s%p%x%d",
        "%x%x%x%x",
        "%#0123456x%08x%x%s%p%d%n%o%u%c%h%l%q%j%z%Z%t%i%e%g%f%a%C%S%08x%%",
#        "100",
#        "1000",
#        "3fffffff",
#        "7ffffffe",
#        "7fffffff",
#        "80000000",
#        "fffffffe",
#        "ffffffff",
#        "10000",
#        "100000",
         "0",
         "-1",
         "1",
    ]
    fuzz_inputs
  end


  def generate_inputs url, fuzz_inputs
    inputs = Array.new

    # count fuzz locations
    locs = url.scan(/\$@\$/)

    # generate input combinations
    combs = fuzz_inputs.combination(locs.size).to_a

    # generate test instance for each combination
    for c in combs do
      inputs << url.dup.gsub!(/\$@\$/) { |x|
        x = URI::encode(c.pop) }
    end

    return inputs
  end

  def execute url
    $log.info "Fuzzing: #{url}"
    $device.open_url url
    sleep 2

    $log.info "Killing processes names #{$selected_app.binary_name}"
    $device.kill_by_name $selected_app.binary_name

    crashed?
  end

  def crashed?
    crash_report_folder = "/var/mobile/Library/Logs/CrashReporter"
    crashes = $device.ops.dir_glob crash_report_folder, "*"
    crashed = false
    crashes.each { |x|
      if x.include? $selected_app.binary_name
        crashed = true
      end
    }
    crashed
  end



end