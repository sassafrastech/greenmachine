get '/green-machine' => 'gm_reports#show'
get '/green-machine/reports' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish' => 'gm_reports#show'
get '/green-machine/reports/:start/:finish/project-detail/:project_id' => 'gm_reports#project_detail'