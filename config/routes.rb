get '/green-machine' => 'gm_reports#show'
get '/green-machine/reports' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish' => 'gm_reports#show'