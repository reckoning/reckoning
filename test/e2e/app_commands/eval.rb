# Lets a spec run arbitrary Ruby against the live Rails process via
# `appEval("…")`. Use sparingly — prefer a named scenario for
# anything non-trivial so the intent stays visible in the spec.
Kernel.eval(command_options) unless command_options.nil? # rubocop:disable Security/Eval
