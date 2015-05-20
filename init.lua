
cal framework = require('./modules/framework.lua')
local Plugin = framework.Plugin
local DataSourcePoller = framework.DataSourcePoller
local WebRequestDataSource = framework.WebRequestDataSource
local PollerCollection = framework.PollerCollection
local url = require('url')

local auth = framework.util.auth

local params = framework.params
params.name = 'Boundary Http Check Plugin'
params.version = '1.2'
params.tags = 'http'

local function createPollers(params) 
  local pollers = PollerCollection:new() 

  for _,item in pairs(params.items) do

    local options = url.parse(item.url)
    options.protocol = options.protocol or item.protocol or 'http'
    options.auth = options.auth or auth(item.username, item.password)
    options.method = item.method
    options.meta = item.source
    options.data = item.postdata

    options.wait_for_end = false

    local data_source = WebRequestDataSource:new(options)

    local time_interval = tonumber((item.pollInterval or params.pollInterval)) * 1000
    local poller = DataSourcePoller:new(time_interval, data_source)
    
    pollers:add(poller)
  end

  return pollers
end

local pollers = createPollers(params)

local plugin = Plugin:new(params, pollers)
function plugin:onParseValues(_, extra)
  local result = {}
  local value = tonumber(extra.response_time) 
  if extra.status_code < 200 or extra.status_code >= 300 then
    value = -1
  end

  result['HTTP_RESPONSETIME'] = {value = value, source = extra.info} 

  return result
end
plugin:run()
