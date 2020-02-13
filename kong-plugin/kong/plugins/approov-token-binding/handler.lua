-- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--assert(ngx.get_phase() == "timer", "The world is coming to an end!")

-- Grab plugin name from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local kong = kong
local type = type

local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local basexx = require "basexx"
local resty_sha256 = require "resty.sha256"


local ApproovTokenBindingHandler = {}

-- MUST run after JWT plugin, that has a PRIORITY of 1005
ApproovTokenBindingHandler.PRIORITY = 1004
ApproovTokenBindingHandler.VERSION = "0.1.0"


local function do_authentication(conf)

  -----------------------------------------
  -- Config Validation
  -----------------------------------------

  local header_name = conf.token_binding_header_name

  if not header_name then
    kong.log.err("Missing configuration for: token_binding_header")
    return nil, { status = 500 }
  end


  -----------------------------------------
  -- Token Binding Header Validation
  -----------------------------------------

  local headers = kong.request.get_headers()
  local token_binding = headers[header_name]

  if not token_binding or token_binding == "" then
    kong.log.err("Missing the value for token binding header.")
    return nil, { status = 401 }
  end

  if type(token_binding) == "string" then

    -- By default the removal of the Approov Token header it's enabled, because
    --  every time you forward a request to a backend you are not in control of,
    --  like a Third Party API, you don't want to leak it.
    if conf.remove_approov_token_header then
      kong.service.request.clear_header("Approov-Token")
    end

    -- By default the removal of the Approov Token Binding header it's not
    --  enabled, because you may need it down in the request pipeline, like when
    --  you are binding to an Authentication/Authorization header.
    if conf.remove_approov_token_binding_header then
      kong.service.request.clear_header(header_name)
    end

  else
    -- duplicate Header for the token binding
    kong.log.warn("Duplicated header for the token binding.")
    return nil, { status = 401 }
  end


  -----------------------------------------
  -- Pay Claim Validation
  -----------------------------------------

  -- @TODO: Find a native function to remove the first occurrence of a word in a
  --        string.
  local approov_token = string.gsub(headers["Approov-Token"], "Bearer", "")
  approov_token = string.gsub(approov_token, " ", "")

  -- Decode the Approov token
  local jwt, err = jwt_decoder:new(approov_token)

  if err then
    kong.log.err(tostring(err))
    return false, { status = 401 }
  end

  local pay_claim = jwt.claims["pay"]

  if not pay_claim then
    -- Looks like an Approov Token from the fail-over.
    kong.log.warn("Approov Token pay claim not present.")
    return true
  elseif pay_claim == nil or pay_claim == "" then
    kong.log.err("Approov Token pay claim is empty.")
    return false, { status = 401 }
  end


  -----------------------------------------
  -- Approov Token Binding Check
  -----------------------------------------

  local sha256 = resty_sha256:new()
  sha256:update(token_binding)
  local token_binding_hash = basexx.to_base64(sha256:final())

  if token_binding_hash ~= pay_claim then
    kong.log.err("Approov Token Binding not matching.")
    return false, { status = 401 }
  end


  -----------------------------------------
  -- Success, Approov Token Binding Matches
  -----------------------------------------
  return true
end


function ApproovTokenBindingHandler:access(conf)
  -- check if preflight request and whether it should be authenticated
  if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
    return
  end

  local ok, err = do_authentication(conf)
  if not ok then
    return kong.response.exit(err.status, {}, {["Content-Type"] = "application/json"})
  end
end


return ApproovTokenBindingHandler
