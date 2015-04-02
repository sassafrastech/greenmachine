get '/green-machine' => 'gm_reports#show'
get '/green-machine/reports' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish/project-detail/:project_id' => 'gm_reports#project_detail'

# Quickbooks auth
match '/gmqbo/flow-start' => 'gm_quickbooks#authenticate', as: :gm_quickbooks_flow_start
match '/gmqbo/callback' => 'gm_quickbooks#callback', as: :gm_quickbooks_callback
