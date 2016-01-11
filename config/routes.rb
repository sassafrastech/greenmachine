get '/green-machine' => 'gm_reports#show'
get '/green-machine/reports' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish/project-detail/:project_id' => 'gm_reports#project_detail'
get '/green-machine/reports/:start/:finish/project-detail/:project_id/create-invoice' => 'gm_reports#create_invoice', as: :gm_create_invoice

# GreenMachine config
get '/green-machine/config' => 'gm_config#index', as: :gm_config
resources :gm_rates, path: '/green-machine/config/rates'
resources :gm_user_info, path: '/green-machine/config/users'

# Quickbooks auth
match '/green-machine/quickbooks/flow-start' => 'gm_quickbooks#authenticate', as: :gm_quickbooks_flow_start, via: [:get, :post]
match '/green-machine/quickbooks/callback' => 'gm_quickbooks#callback', as: :gm_quickbooks_callback, via: [:get, :post]
