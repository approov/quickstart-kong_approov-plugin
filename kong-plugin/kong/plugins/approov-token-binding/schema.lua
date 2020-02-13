local typedefs = require "kong.db.schema.typedefs"


return {
  name = "approov-token-binding",
  fields = {
    { consumer = typedefs.no_consumer },
    { run_on = typedefs.run_on_first },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { token_binding_header_name = { type = "string", default = "Authorization" }, },
          { remove_approov_token_header = { type = "boolean", default = true }, },
          { remove_approov_token_binding_header = { type = "boolean", default = false }, },
          { run_on_preflight = { type = "boolean", default = true }, },
        },
    }, },
  },
}
